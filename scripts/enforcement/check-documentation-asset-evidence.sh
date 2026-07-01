#!/usr/bin/env bash
# check-documentation-asset-evidence.sh — dedicated Documentation/reference asset gate.
#
# Fails a pull request that changes code/config/tests but whose changed Route Plan(s)
# contain neither valid Documentation Asset Evidence nor a valid Documentation Asset
# Waiver. Documentation/reference assets are broader than code templates/patterns:
# architecture docs, integration/deployment docs, product/domain docs, lessons-learned,
# failed-solutions, templates, patterns, and external docs retrieved through Context7.
#
# This is intentionally a SEPARATE gate from check-workflow-evidence.sh so that the
# shared workflow checker and its fixtures are not perturbed.
set -euo pipefail
python3 - "$@" <<'PY'
import os, re, subprocess, sys

base = sys.argv[1] if len(sys.argv) > 1 else 'HEAD~1'
head = sys.argv[2] if len(sys.argv) > 2 else 'HEAD'

def sh(*args):
    return subprocess.check_output(args, text=True).splitlines()

# --- file classification: identical to the rest of the project -----------------
changed = sh('git', 'diff', '--name-only', base, head)
plans = [p for p in changed if re.match(r'^\.claude/plans/.*\.md$', p) and os.path.exists(p)]
code = [p for p in changed
        if p and not re.match(r'^\.claude/plans/|^docs/|^README\.md$|^CHANGELOG\.md$|^LICENSE', p)]

if not code:
    print('No code/config/test changes; documentation asset evidence not required.')
    sys.exit(0)

if not plans:
    print('ERROR_FOR_AGENT: code/config/test changes require a changed .claude/plans/*.md '
          'Route Plan with ## Documentation Asset Evidence or ## Documentation Asset Waiver.')
    sys.exit(1)

# --- markdown helpers (mirrors check-workflow-evidence.sh conventions) ----------
def clean(s):
    return re.sub(r'[`*_]', '', s or '').strip()

def section(text, title_re):
    lines = text.splitlines(); out = []; on = False
    for line in lines:
        if re.match(r'^#{1,4}\s+' + title_re + r'(\s|$)', line, re.I):
            on = True; continue
        if on and re.match(r'^#{1,4}\s+', line):
            break
        if on:
            out.append(line)
    return '\n'.join(out)

def has_heading(text, title_re):
    return re.search(r'^#{1,4}\s+' + title_re + r'(\s|$)', text, re.I | re.M) is not None

def field_value(section_text, name):
    """Return the value of a `- name: value` / `name: value` line, or None if absent."""
    pat = re.compile(r'^\s*[-*]?\s*' + re.escape(name) + r'\s*:\s*(.*)$', re.I)
    for line in section_text.splitlines():
        m = pat.match(line)
        if m:
            return m.group(1).strip()
    return None

# Anchored bare-placeholder set. A field whose entire cleaned value is one of these
# (or empty) carries no real information.
PLACEHOLDER_RE = re.compile(
    r'^(todo|tbd|tba|none|n/?a|na|not\s+checked|not\s+applicable|not\s+needed|'
    r'not\s+required|later|unknown|placeholder|to\s*decide|pending|xxx|\?+|-+|\.+)$',
    re.I)

def is_placeholder(value):
    c = clean(value)
    return (not c) or bool(PLACEHOLDER_RE.match(c))

# A concrete source names a real artifact: a slash path (foo/bar) or a filename with a
# known extension. This rejects generic statements like "docs checked".
SOURCE_TOKEN_RE = re.compile(
    r'(?:[A-Za-z0-9_.-]+/[A-Za-z0-9_./-]+'
    r'|\b[\w.-]+\.(?:md|py|sh|ya?ml|tsv|json|txt|js|ts|adr)\b'
    r'|https?://\S+)', re.I)

def names_concrete_source(value):
    return bool(SOURCE_TOKEN_RE.search(clean(value)))

def validate_evidence(text, plan):
    """Return (ok, [messages]) for the ## Documentation Asset Evidence section."""
    sec = section(text, r'Documentation\s+Asset\s+Evidence')
    msgs = []
    internal = field_value(sec, 'internal')
    context7 = field_value(sec, 'context7')
    decision = field_value(sec, 'decision')

    if internal is None:
        msgs.append(f'ERROR_FOR_AGENT: {plan} Documentation Asset Evidence must include an internal: field.')
    elif is_placeholder(internal):
        msgs.append(f'ERROR_FOR_AGENT: {plan} Documentation Asset Evidence internal: is empty or a placeholder.')
    elif not names_concrete_source(internal):
        msgs.append(f'ERROR_FOR_AGENT: {plan} Documentation Asset Evidence internal: must name concrete '
                    f'docs/assets (a path or file), not a generic statement like "docs checked".')

    if context7 is None:
        msgs.append(f'ERROR_FOR_AGENT: {plan} Documentation Asset Evidence must include a context7: field.')
    elif is_placeholder(context7):
        msgs.append(f'ERROR_FOR_AGENT: {plan} Documentation Asset Evidence context7: is empty or a placeholder; '
                    f'name the external source checked or explain concretely why Context7 was not required.')
    else:
        c = clean(context7)
        negation = re.search(r'\bnot\s+(required|needed|applicable)\b|\bno\s+external\b|'
                             r'\bpurely\s+internal\b|\binternal[- ]only\b', c, re.I)
        if negation:
            reason = re.search(r'\bbecause\b|\bsince\b|\binternal\b|\benforcement\b|'
                               r'does\s+not\s+(implement|touch|use|integrate)|'
                               r'no\s+external\s+(library|framework|sdk|api|service)', c, re.I)
            if len(c) < 40 or not reason:
                msgs.append(f'ERROR_FOR_AGENT: {plan} Documentation Asset Evidence context7: says external docs '
                            f'were not required but gives no concrete reason why they were unnecessary.')
        elif not names_concrete_source(c) and 'context7' not in c.lower():
            msgs.append(f'ERROR_FOR_AGENT: {plan} Documentation Asset Evidence context7: must name a concrete '
                        f'external source (e.g. a Context7 library id or docs URL) or explain why it was not required.')

    if decision is None:
        msgs.append(f'ERROR_FOR_AGENT: {plan} Documentation Asset Evidence must include a decision: field.')
    elif is_placeholder(decision) or len(clean(decision)) < 15:
        msgs.append(f'ERROR_FOR_AGENT: {plan} Documentation Asset Evidence decision: must explain how the '
                    f'documentation changed the plan or confirmed the approach, not a placeholder.')

    return (not msgs, msgs)

def validate_waiver(text, plan):
    """Return (ok, [messages]) for the ## Documentation Asset Waiver section."""
    sec = section(text, r'Documentation\s+Asset\s+Waiver')
    msgs = []
    reason = field_value(sec, 'reason')
    scope = field_value(sec, 'scope')
    risk = field_value(sec, 'risk')

    if reason is None:
        msgs.append(f'ERROR_FOR_AGENT: {plan} Documentation Asset Waiver must include a reason: field.')
    elif is_placeholder(reason) or len(clean(reason)) < 20:
        msgs.append(f'ERROR_FOR_AGENT: {plan} Documentation Asset Waiver reason: must be a concrete reason, '
                    f'not "not needed"/"none"/placeholder.')

    if scope is None:
        msgs.append(f'ERROR_FOR_AGENT: {plan} Documentation Asset Waiver must include a scope: field.')
    elif is_placeholder(scope) or len(clean(scope)) < 5:
        msgs.append(f'ERROR_FOR_AGENT: {plan} Documentation Asset Waiver scope: must name what files/task it covers.')

    if risk is None:
        msgs.append(f'ERROR_FOR_AGENT: {plan} Documentation Asset Waiver must include a risk: field.')
    elif is_placeholder(risk) or len(clean(risk)) < 5:
        msgs.append(f'ERROR_FOR_AGENT: {plan} Documentation Asset Waiver risk: must state the remaining risk.')

    return (not msgs, msgs)

# --- gate: at least one changed plan must carry valid Evidence or Waiver --------
collected = []
missing_both = []
for plan in plans:
    text = open(plan, encoding='utf-8').read()
    has_ev = has_heading(text, r'Documentation\s+Asset\s+Evidence')
    has_wv = has_heading(text, r'Documentation\s+Asset\s+Waiver')

    if not has_ev and not has_wv:
        missing_both.append(plan)
        continue

    if has_ev:
        ok, msgs = validate_evidence(text, plan)
        if ok:
            print('Documentation asset evidence checks passed.')
            sys.exit(0)
        collected.extend(msgs)
    if has_wv:
        ok, msgs = validate_waiver(text, plan)
        if ok:
            print('Documentation asset evidence checks passed.')
            sys.exit(0)
        collected.extend(msgs)

for plan in missing_both:
    print(f'ERROR_FOR_AGENT: {plan} changes code/config/tests but has no ## Documentation Asset '
          f'Evidence or ## Documentation Asset Waiver.')
for msg in collected:
    print(msg)
if not missing_both and not collected:
    print('ERROR_FOR_AGENT: no changed Route Plan contains valid documentation/reference asset '
          'evidence or a valid waiver.')
sys.exit(1)
PY
