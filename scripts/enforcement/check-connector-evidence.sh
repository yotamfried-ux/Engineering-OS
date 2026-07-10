#!/usr/bin/env bash
set -euo pipefail
python3 - "$@" <<'PY'
import os, re, subprocess, sys
base = sys.argv[1] if len(sys.argv) > 1 else 'HEAD~1'
head = sys.argv[2] if len(sys.argv) > 2 else 'HEAD'

def sh(*args):
    return subprocess.check_output(args, text=True).splitlines()

def clean(s):
    return re.sub(r'[`*_]', '', s or '').strip()

def norm(s):
    return re.sub(r'[^a-z0-9]+', ' ', clean(s).lower()).strip()

def split_items(s):
    out=[]
    for part in re.split(r'[,;]|\band\b', s or '', flags=re.I):
        item=clean(part).strip(' .:-')
        if item: out.append(item)
    return out

def field(text, name_re):
    for line in text.splitlines():
        if '|' not in line: continue
        cells=[clean(c) for c in line.split('|')]
        for i,c in enumerate(cells[:-1]):
            if re.fullmatch(name_re, c, re.I): return cells[i+1].strip()
    # name_re may itself contain capturing groups (e.g. an alternation like
    # "systems/connectors|systems|connectors"), so the value must be captured
    # by a uniquely-named group rather than a positional one, or a match on the
    # field-name alternation itself would be mistaken for the field's value.
    m=re.search(r'(?:'+name_re+r')\s*[:=-]\s*(?P<value>.+)$', text, re.I|re.M)
    return m.group('value').strip() if m else ''

def section(text, title_re):
    lines=text.splitlines(); out=[]; on=False
    for line in lines:
        if re.match(r'^#{1,4}\s+'+title_re+r'(\s|$)', line, re.I): on=True; continue
        if on and re.match(r'^#{1,4}\s+', line): break
        if on: out.append(line)
    return '\n'.join(out)

def has_heading(text, title_re):
    return re.search(r'^#{1,4}\s+'+title_re+r'(\s|$)', text, re.I|re.M) is not None

def noneish(value):
    v = norm(value) or ''
    return v in {
        'none', 'n a', 'na', 'not required',
        'no external connectors', 'no connectors'
    }

def mentioned(needle, hay):
    n=norm(needle); h=norm(hay)
    if not n: return False
    return re.search(r'(?<![a-z0-9])'+re.escape(n)+r'(?![a-z0-9])', h) is not None

def connector_contexts(conn, text):
    lines = text.splitlines()
    contexts = []
    for idx, line in enumerate(lines):
        if not mentioned(conn, line):
            continue
        block = [line]
        base_indent = len(line) - len(line.lstrip())
        for nxt in lines[idx + 1:]:
            if not nxt.strip():
                break
            if re.match(r'^#{1,4}\s+', nxt):
                break
            indent = len(nxt) - len(nxt.lstrip())
            starts_new_peer_item = re.match(r'^\s*[-*]\s+\S', nxt) and indent <= base_indent
            if starts_new_peer_item and not mentioned(conn, nxt):
                break
            if indent > base_indent or mentioned(conn, nxt):
                block.append(nxt)
                continue
            break
        contexts.append('\n'.join(block))
    return contexts

def unavailable(conn, evidence, usage):
    marker = re.compile(r'\b(unavailable|not available|fallback|waived|waiver|not used)\b', re.I)
    for text in (evidence, usage):
        for ctx in connector_contexts(conn, text):
            if marker.search(ctx):
                return True
    return False

def label_values(text, key):
    pat = re.compile(r'^\s*(?:[-*]\s*)?'+re.escape(key)+r'\s*:\s*(\S.*)$', re.I)
    values=[]
    for line in text.splitlines():
        m = pat.match(line)
        if m:
            values.append(m.group(1).strip())
    return values

def target_matches(target_text, targets):
    low=target_text.lower()
    for t in targets:
        k=t.lower().strip()
        if not k: continue
        d=k.rsplit('/',1)[0] if '/' in k else k
        b=k.rsplit('/',1)[-1]
        if k in low or d in low or b in low: return True
    return False

def has_identifier(text):
    if re.search(r'(?<![A-Za-z0-9_])#\d+(?![A-Za-z0-9_])', text or ''): return True
    if re.search(r'\b[0-9a-f]{7,40}\b', text or ''): return True
    if re.search(r'\b[A-Za-z0-9_.-]+/[A-Za-z0-9_./-]+\b', text or ''): return True
    if re.search(r'\b[A-Za-z0-9_.-]+\.(?:md|sh|py|ts|tsx|js|jsx|json|ya?ml|toml|tsv|csv|sql|txt)\b', text or ''): return True
    return False

changed=sh('git','diff','--name-only',base,head)
plans=[p for p in changed if re.match(r'^\.claude/plans/.*\.md$', p) and os.path.exists(p)]
code=[p for p in changed if p and not re.match(r'^\.claude/plans/|^docs/|^README\.md$|^CHANGELOG\.md$|^LICENSE', p)]
if code and not plans:
    print('ERROR_FOR_AGENT: code/config/script files changed without a changed .claude/plans/*.md Route Plan.'); sys.exit(1)
if not plans:
    print('No changed plan files.'); sys.exit(0)

bad=False
for plan in plans:
    text=open(plan,encoding='utf-8').read()
    value=field(text, r'external\s*(systems/connectors|systems|connectors)')
    if not value:
        print(f'ERROR_FOR_AGENT: {plan} is missing External systems/connectors.'); bad=True; continue
    if noneish(value): continue
    evidence=section(text, r'Connector\s+Evidence')
    usage=section(text, r'Connector\s+Usage\s+Evidence')
    if not has_heading(text, r'Connector\s+Evidence'):
        print(f"ERROR_FOR_AGENT: {plan} declares external connector(s) '{value}' but lacks ## Connector Evidence."); bad=True
    if not has_heading(text, r'Connector\s+Usage\s+Evidence'):
        print(f"ERROR_FOR_AGENT: {plan} declares external connector(s) '{value}' but lacks ## Connector Usage Evidence."); bad=True; continue
    active=[]
    for conn in split_items(value):
        if unavailable(conn, evidence, usage):
            continue
        active.append(conn)
        if not mentioned(conn, evidence):
            print(f'ERROR_FOR_AGENT: {plan} Connector Evidence must mention declared connector {conn}.'); bad=True
        if not any(mentioned(conn, val) for key in ['source','action','result','decision'] for val in label_values(usage, key)):
            print(f'ERROR_FOR_AGENT: {plan} Connector Usage Evidence must mention declared connector {conn} in source/action/result/decision evidence.'); bad=True
    if active:
        values_by_key={key: label_values(usage, key) for key in ['source','action','result','decision']}
        for key, vals in values_by_key.items():
            if not vals:
                print(f'ERROR_FOR_AGENT: {plan} Connector Usage Evidence must include non-empty {key}: evidence.'); bad=True
        for result in values_by_key.get('result', []):
            if not has_identifier(result):
                print(f'ERROR_FOR_AGENT: {plan} Connector Usage Evidence result must include a concrete identifier such as a path, PR or issue number, or SHA.'); bad=True
        decision_text='\n'.join(values_by_key.get('decision', []))
        if not decision_text or not re.search(r'\b(chose|selected|changed|limited|implemented|updated|kept|blocked|added)\b', decision_text, re.I):
            print(f'ERROR_FOR_AGENT: {plan} Connector Usage Evidence must show decision impact, not only that data was read.'); bad=True
        if code:
            target_vals=label_values(usage, 'target')
            if not target_vals:
                print(f'ERROR_FOR_AGENT: {plan} Connector Usage Evidence must include non-empty target: evidence for code/config/script changes.'); bad=True
            elif not target_matches('\n'.join(target_vals), code):
                print(f'ERROR_FOR_AGENT: {plan} Connector Usage Evidence target must reference a changed target path, directory, or filename.'); bad=True
if bad: sys.exit(1)
print('Connector route plan checks passed.')
PY
