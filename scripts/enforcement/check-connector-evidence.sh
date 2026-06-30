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
    m=re.search(name_re+r'\s*[:=-]\s*(.+)$', text, re.I|re.M)
    return m.group(1).strip() if m else ''

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
    return re.fullmatch(r'(none|n/a|na|not\s+required|no\s+external\s+connectors|no\s+connectors)', norm(value) or '', re.I) is not None

def mentioned(needle, hay):
    n=norm(needle); h=norm(hay)
    if not n: return False
    first=n.split()[0]
    return n in h or (len(first) >= 4 and re.search(r'\b'+re.escape(first)+r'\b', h)) is not None

def unavailable(conn, evidence, usage):
    blob='\n'.join([evidence, usage]).lower()
    if not mentioned(conn, blob): return False
    return re.search(r'\b(unavailable|not available|fallback|waived|waiver|not used)\b', blob, re.I) is not None

def target_matches(usage, targets):
    low=usage.lower()
    for t in targets:
        k=t.lower().strip()
        if not k: continue
        d=k.rsplit('/',1)[0] if '/' in k else k
        b=k.rsplit('/',1)[-1]
        if k in low or d in low or b in low: return True
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
        if not mentioned(conn, usage):
            print(f'ERROR_FOR_AGENT: {plan} Connector Usage Evidence must mention declared connector {conn}.'); bad=True
    if active:
        for key in ['source','action','result','decision']:
            if not re.search(r'^\s*([-*]\s*)?'+key+r'\s*:', usage, re.I|re.M):
                print(f'ERROR_FOR_AGENT: {plan} Connector Usage Evidence must include {key}: evidence.'); bad=True
        if code:
            if not re.search(r'^\s*([-*]\s*)?target\s*:', usage, re.I|re.M):
                print(f'ERROR_FOR_AGENT: {plan} Connector Usage Evidence must include target: evidence for code/config/script changes.'); bad=True
            elif not target_matches(usage, code):
                print(f'ERROR_FOR_AGENT: {plan} Connector Usage Evidence target must reference a changed target path, directory, or filename.'); bad=True
        if not re.search(r'\b(decision|chose|selected|changed|limited|implemented|updated|kept|blocked)\b', usage, re.I):
            print(f'ERROR_FOR_AGENT: {plan} Connector Usage Evidence must show decision impact, not only that data was read.'); bad=True
if bad: sys.exit(1)
print('Connector route plan checks passed.')
PY
