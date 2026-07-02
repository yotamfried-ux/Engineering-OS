#!/usr/bin/env bash
# check-pr-review-evidence.sh — PR-body review-evidence and merge-readiness gate.
#
# Extracted from .github/workflows/pr-policy.yml's inline python (behavior-preserving),
# then hardened: `checks:` must name a real gate/workflow token, `evidence:` must be a
# concrete artifact reference, and a `## Merge Readiness` schema (base/expected-head-sha/
# ci/threads/approval) is required so merge-decision evidence is deterministic. The merge
# decision itself stays human — this only validates the evidence recorded for it.
#
# Usage:
#   check-pr-review-evidence.sh --body <file> [--head-sha <sha>]
#                                [--workflows-dir <dir>] [--checks-dir <dir>]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BODY_FILE=""
HEAD_SHA=""
WORKFLOWS_DIR="$ROOT/.github/workflows"
CHECKS_DIR="$SCRIPT_DIR"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --body) BODY_FILE="${2:-}"; shift 2 ;;
    --head-sha) HEAD_SHA="${2:-}"; shift 2 ;;
    --workflows-dir) WORKFLOWS_DIR="${2:-}"; shift 2 ;;
    --checks-dir) CHECKS_DIR="${2:-}"; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

[ -n "$BODY_FILE" ] && [ -f "$BODY_FILE" ] || { echo "ERROR_FOR_AGENT: missing readable --body file." >&2; exit 2; }

python3 - "$BODY_FILE" "$HEAD_SHA" "$WORKFLOWS_DIR" "$CHECKS_DIR" <<'PY'
import os, re, sys

body_file, head_sha, workflows_dir, checks_dir = sys.argv[1:5]
body = open(body_file, encoding='utf-8').read()

# Anchored to the whole value (optionally with surrounding punctuation/whitespace)
# so a substantive answer that merely contains a banned word ("risks: none that
# I could find, ...") is not rejected — only values that ARE placeholder text.
placeholder = re.compile(r'^\s*(todo|tbd|placeholder|unknown|n/?a|none|later|fix later|not sure|unclear)\W*$', re.I)

def gate_tokens():
    out = set()
    if os.path.isdir(workflows_dir):
        for fn in os.listdir(workflows_dir):
            if fn.endswith(('.yml', '.yaml')):
                out.add(fn.rsplit('.', 1)[0].lower())
                try:
                    text = open(os.path.join(workflows_dir, fn), encoding='utf-8').read()
                    m = re.search(r'^name:\s*(.+)$', text, re.M)
                    if m:
                        out.add(m.group(1).strip().lower())
                except OSError:
                    pass
    if os.path.isdir(checks_dir):
        for fn in os.listdir(checks_dir):
            if re.match(r'^(check|enforce)-.+\.(sh|py)$', fn):
                out.add(fn.rsplit('.', 1)[0].lower())
    out.add('enforcement-tests')
    return out

GATE_TOKENS = gate_tokens()

def names_real_gate(value):
    low = value.lower()
    return any(re.search(r'\b' + re.escape(tok) + r'\b', low) for tok in GATE_TOKENS)

def require_real_gate(title, field, value):
    if names_real_gate(value):
        return True
    print(f'ERROR_FOR_AGENT: ## {title} {field}: must name at least one real gate/workflow '
          f'(matched against .github/workflows/*.yml names or check-*/enforce-*/enforcement-tests script basenames).')
    return False

CONCRETE_REF = re.compile(r'(https?://\S+|#\d+|[\w.\-/]+/[\w.\-]+\.[a-zA-Z0-9]+)')

def concrete_evidence(value):
    return bool(CONCRETE_REF.search(value))

def section(text, title):
    m = re.search(r'^##\s+' + re.escape(title) + r'\s*$', text, re.I | re.M)
    if not m:
        return ''
    rest = text[m.end():]
    n = re.search(r'^##\s+', rest, re.M)
    return rest[:n.start()] if n else rest

def field_value(text, field):
    m = re.search(r'(^|\n)\s*[-*]?\s*' + re.escape(field) + r'\s*:\s*(.+)', text, re.I)
    return m.group(2).strip() if m else None

MIN_LEN = {'base': 2, 'expected-head-sha': 7}

def require_fields(text, title, fields):
    if not text.strip():
        print(f'ERROR_FOR_AGENT: PR body must include ## {title}.')
        return False
    ok = True
    for field in fields:
        value = field_value(text, field)
        min_len = MIN_LEN.get(field, 12)
        if value is None or len(value) < min_len or placeholder.search(value):
            print(f'ERROR_FOR_AGENT: ## {title} must include a concrete {field}: value.')
            ok = False
            continue
        if field == 'checks' and not require_real_gate(title, 'checks', value):
            ok = False
        if field == 'evidence' and not concrete_evidence(value):
            print(f'ERROR_FOR_AGENT: ## {title} evidence: must be a concrete artifact reference '
                  f'(a path, a run URL, or #<PR/issue number>), not a vague claim.')
            ok = False
    return ok

review_ok = False
external = section(body, 'External Review Evidence')
fallback = section(body, 'Review Fallback Evidence')
if external and require_fields(external, 'External Review Evidence', ['source', 'result', 'decision']):
    print('review evidence present')
    review_ok = True
elif fallback and require_fields(fallback, 'Review Fallback Evidence', ['reviewer', 'scope', 'checks', 'risks', 'decision', 'evidence']):
    print('review fallback evidence present')
    review_ok = True
else:
    print('ERROR_FOR_AGENT: PR body must include either ## External Review Evidence or ## Review Fallback Evidence with required fields.')
    print('ACTION: add structured review evidence. Fallback must include reviewer, scope, checks, risks, decision, and evidence.')

merge = section(body, 'Merge Readiness')
merge_ok = require_fields(merge, 'Merge Readiness', ['base', 'expected-head-sha', 'ci', 'threads', 'approval'])
if merge_ok:
    sha_value = field_value(merge, 'expected-head-sha') or ''
    sha_match = re.search(r'\b[0-9a-f]{7,40}\b', sha_value, re.I)
    if not sha_match:
        print('ERROR_FOR_AGENT: ## Merge Readiness expected-head-sha: must contain a concrete commit SHA (7-40 hex chars).')
        merge_ok = False
    elif head_sha and not head_sha.lower().startswith(sha_match.group(0).lower()) and not sha_match.group(0).lower().startswith(head_sha.lower()):
        print(f'ERROR_FOR_AGENT: ## Merge Readiness expected-head-sha: ({sha_match.group(0)}) does not match the '
              f'actual PR head SHA ({head_sha}). The checklist restarts for the new SHA per '
              f'docs/operations/merge-readiness-checklist.md item 3.')
        merge_ok = False
    ci_value = field_value(merge, 'ci') or ''
    if not require_real_gate('Merge Readiness', 'ci', ci_value):
        merge_ok = False

if not (review_ok and merge_ok):
    sys.exit(1)

print('✅ PR review and merge-readiness evidence passed.')
PY
