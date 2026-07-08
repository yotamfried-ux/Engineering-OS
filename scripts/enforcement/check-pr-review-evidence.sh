#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BODY_FILE=""
HEAD_SHA=""
WORKFLOWS_DIR="$ROOT/.github/workflows"
CHECKS_DIR="$SCRIPT_DIR"
CHANGED_FILES=""
WORK_HISTORY_ARTIFACT="$ROOT/.engineering-os/work-history/latest.json"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --body) BODY_FILE="${2:-}"; shift 2 ;;
    --head-sha) HEAD_SHA="${2:-}"; shift 2 ;;
    --workflows-dir) WORKFLOWS_DIR="${2:-}"; shift 2 ;;
    --checks-dir) CHECKS_DIR="${2:-}"; shift 2 ;;
    --changed-files) CHANGED_FILES="${2:-}"; shift 2 ;;
    --work-history-artifact) WORK_HISTORY_ARTIFACT="${2:-}"; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

[ -n "$BODY_FILE" ] && [ -f "$BODY_FILE" ] || { echo "ERROR_FOR_AGENT: missing readable --body file." >&2; exit 2; }

python3 - "$BODY_FILE" "$HEAD_SHA" "$WORKFLOWS_DIR" "$CHECKS_DIR" <<'PY'
import os, re, sys
body_file, head_sha, workflows_dir, checks_dir = sys.argv[1:5]
body = open(body_file, encoding='utf-8').read()
placeholder = re.compile(r'^\s*(todo|tbd|placeholder|unknown|n/?a|none|later|fix later|not sure|unclear)\W*$', re.I)
concrete = re.compile(r'(https?://\S+|#\d+|[\w.\-/]+/[\w.\-]+\.[a-zA-Z0-9]+)')

def section(title):
    m = re.search(r'^##\s+' + re.escape(title) + r'\s*$', body, re.I | re.M)
    if not m:
        return ''
    rest = body[m.end():]
    n = re.search(r'^##\s+', rest, re.M)
    return rest[:n.start()] if n else rest

def field(text, name):
    m = re.search(r'(^|\n)\s*[-*]?\s*' + re.escape(name) + r'\s*:\s*(.+)', text, re.I)
    return m.group(2).strip() if m else None

def gate_tokens():
    tokens = {'enforcement-tests'}
    if os.path.isdir(workflows_dir):
        for fn in os.listdir(workflows_dir):
            if fn.endswith(('.yml', '.yaml')):
                tokens.add(fn.rsplit('.', 1)[0].lower())
                try:
                    txt = open(os.path.join(workflows_dir, fn), encoding='utf-8').read()
                    m = re.search(r'^name:\s*(.+)$', txt, re.M)
                    if m:
                        tokens.add(m.group(1).strip().lower())
                except OSError:
                    pass
    if os.path.isdir(checks_dir):
        for fn in os.listdir(checks_dir):
            if re.match(r'^(check|enforce)-.+\.(sh|py)$', fn):
                tokens.add(fn.rsplit('.', 1)[0].lower())
    return tokens

def names_gate(value):
    low = value.lower()
    return any(re.search(r'\b' + re.escape(tok) + r'\b', low) for tok in gate_tokens())

def require_fields(title, text, fields):
    if not text.strip():
        print(f'ERROR_FOR_AGENT: PR body must include ## {title}.')
        return False
    ok = True
    for name in fields:
        value = field(text, name)
        min_len = 7 if name == 'expected-head-sha' else 2 if name == 'base' else 12
        if value is None or len(value) < min_len or placeholder.fullmatch(value):
            print(f'ERROR_FOR_AGENT: ## {title} must include a concrete {name}: value.')
            ok = False
        elif name in {'checks', 'ci'} and not names_gate(value):
            print(f'ERROR_FOR_AGENT: ## {title} {name}: must name a real gate/workflow.')
            ok = False
        elif name == 'evidence' and not concrete.search(value):
            print(f'ERROR_FOR_AGENT: ## {title} evidence: must be a concrete artifact reference.')
            ok = False
    return ok

review_ok = False
external = section('External Review Evidence')
fallback = section('Review Fallback Evidence')
if external and require_fields('External Review Evidence', external, ['source', 'result', 'decision']):
    review_ok = True
elif fallback and require_fields('Review Fallback Evidence', fallback, ['reviewer', 'scope', 'checks', 'risks', 'decision', 'evidence']):
    review_ok = True
else:
    print('ERROR_FOR_AGENT: PR body must include either ## External Review Evidence or ## Review Fallback Evidence with required fields.')

merge = section('Merge Readiness')
merge_ok = require_fields('Merge Readiness', merge, ['base', 'expected-head-sha', 'ci', 'threads', 'approval'])
if merge_ok:
    value = field(merge, 'expected-head-sha') or ''
    m = re.search(r'\b[0-9a-f]{7,40}\b', value, re.I)
    if not m:
        print('ERROR_FOR_AGENT: ## Merge Readiness expected-head-sha: must contain a concrete commit SHA.')
        merge_ok = False
    elif head_sha and not (head_sha.lower().startswith(m.group(0).lower()) or m.group(0).lower().startswith(head_sha.lower())):
        print('ERROR_FOR_AGENT: ## Merge Readiness expected-head-sha does not match the PR head SHA.')
        merge_ok = False

if not (review_ok and merge_ok):
    sys.exit(1)
print('PR review and merge-readiness evidence passed')
PY

bash "$SCRIPT_DIR/check-operational-behavior-evidence.sh" --body "$BODY_FILE"

work_history_args=(--body "$BODY_FILE" --head-sha "$HEAD_SHA" --artifact "$WORK_HISTORY_ARTIFACT" --root "$ROOT")
if [ -n "$CHANGED_FILES" ]; then
  work_history_args+=(--changed-files "$CHANGED_FILES")
fi
bash "$SCRIPT_DIR/check-operational-work-history-evidence.sh" "${work_history_args[@]}"
