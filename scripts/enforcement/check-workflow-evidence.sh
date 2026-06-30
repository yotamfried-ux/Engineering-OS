#!/usr/bin/env bash
set -euo pipefail
python3 - "$@" <<'PY'
import os, re, subprocess, sys
base = sys.argv[1] if len(sys.argv) > 1 else 'HEAD~1'
head = sys.argv[2] if len(sys.argv) > 2 else 'HEAD'

def sh(*args):
    return subprocess.check_output(args, text=True).splitlines()

def norm(s):
    return re.sub(r'[^a-z0-9_./-]+','-', re.sub(r'^[\s*`-]+|[\s`.,;:]+$','',s.lower())).strip('-')

def clean(s):
    return re.sub(r'[`*_]','',s or '').strip().lower()
changed=sh('git','diff','--name-only',base,head)
plans=[p for p in changed if re.match(r'^\.claude/plans/.*\.md$',p) and os.path.exists(p)]
code=[p for p in changed if p and not re.match(r'^\.claude/plans/|^docs/|^README\.md$|^CHANGELOG\.md$|^LICENSE',p)]
knowledge=[p for p in changed if re.match(r'^(lessons-learned/|failed-solutions/|templates/)',p)]
if code and not plans:
    print('ERROR_FOR_AGENT: code/config/test files changed without a changed .claude/plans/*.md Route Plan.'); sys.exit(1)
if code and plans:
    commits=sh('git','rev-list','--reverse',f'{base}..{head}')
    first_plan=first_code=0
    for idx,c in enumerate(commits,1):
        fs=sh('git','diff-tree','--no-commit-id','--name-only','-r',c)
        if not first_plan and any(re.match(r'^\.claude/plans/.*\.md$',f) for f in fs): first_plan=idx
        cfs=[f for f in fs if f and not re.match(r'^\.claude/plans/|^docs/|^README\.md$|^CHANGELOG\.md$|^LICENSE',f)]
        if not first_code and cfs: first_code=idx
    if not first_plan or not first_code or first_code <= first_plan:
        print('ERROR_FOR_AGENT: Route Plan must be committed before the first code/config/test change, not in the same or later commit.'); sys.exit(1)
if not plans:
    print('No changed plan files.'); sys.exit(0)

def field(text, name_re):
    for line in text.splitlines():
        if '|' not in line: continue
        cells=[re.sub(r'[`*_]','',c).strip() for c in line.split('|')]
        for i,c in enumerate(cells[:-1]):
            if re.search(name_re,c.lower()): return cells[i+1].strip()
    return ''

def section(text, title_re):
    lines=text.splitlines(); out=[]; on=False
    for line in lines:
        if re.match(r'^#{1,4}\s+'+title_re+r'(\s|$)', line, re.I): on=True; continue
        if on and re.match(r'^#{1,4}\s+', line): break
        if on: out.append(line)
    return '\n'.join(out)

def has_heading(text, title_re):
    return re.search(r'^#{1,4}\s+'+title_re+r'(\s|$)', text, re.I|re.M) is not None

def split_items(s): return [x for x in re.split(r'[,;]\s*',s or '') if x.strip()]
def list_has(s,w): return norm(w) in [norm(x) for x in split_items(s)]
def has_asset(s): return re.search(r'(^|\s)(templates|patterns)/\S+', s or '') is not None
def source_matches(src, targets):
    low=src.lower()
    for t in split_items(targets):
        k=norm(t)
        if not k: continue
        d=k.rsplit('/',1)[0] if '/' in k else k
        b=k.rsplit('/',1)[-1]
        if k in low or d in low or b in low: return True
        if (k.startswith('core/') or k == 'claude.md') and re.search(r'claude\.md|core/task-router\.md|core/workflow\.md', low): return True
    return False
bad=False
for plan in plans:
    text=open(plan,encoding='utf-8').read()
    vals={n:field(text,r'^'+re.escape(n.lower())+r'$') for n in ['Task-router evidence','Workflow evidence','Templates','Patterns','Skills','Validation gates']}
    targets=field(text,r'^target paths?$')
    for n,v in vals.items():
        cv=clean(v)
        if not cv or re.match(r'^(todo|tbd|placeholder|unknown|later|fix\s*later|to\s*decide)$',cv):
            print(f'ERROR_FOR_AGENT: {plan} has missing or placeholder {n}.'); bad=True
    if not has_heading(text,r'Source\s+of\s+Truth\s+Checks'):
        print(f'ERROR_FOR_AGENT: {plan} is missing ## Source of Truth Checks.'); bad=True
    else:
        src=section(text,r'Source\s+of\s+Truth\s+Checks')
        if len(re.findall(r'\|\s*[^|]+\s*\|\s*(checked|read|validated)\s*\|', src, re.I)) < 2:
            print(f'ERROR_FOR_AGENT: {plan} Source of Truth Checks must include at least two checked/read sources.'); bad=True
        if code and clean(targets) and not source_matches(src, targets):
            print(f'ERROR_FOR_AGENT: {plan} Source of Truth Checks do not reference any Target paths or canonical routing/workflow source.'); bad=True
    if code:
        if not has_heading(text,r'Claude\s+Run\s+Trace'):
            print(f'ERROR_FOR_AGENT: {plan} changes code/config/tests but lacks ## Claude Run Trace.'); bad=True
        if not has_heading(text,r'Progress\s+Lifecycle\s+Evidence'):
            print(f'ERROR_FOR_AGENT: {plan} changes code/config/tests but lacks ## Progress Lifecycle Evidence.'); bad=True
        else:
            prog=section(text,r'Progress\s+Lifecycle\s+Evidence').lower()
            for m in ['start','mid','pre-merge']:
                if not re.search(r'(^|[^a-z])'+re.escape(m)+r'([^a-z]|$)',prog): print(f'ERROR_FOR_AGENT: {plan} Progress Lifecycle Evidence must include {m} checkpoint evidence.'); bad=True
    skills=vals['Skills']; sc=clean(skills)
    if sc and not re.match(r'^(none|n/a|na|not\s+required|no\s+skills)$',sc):
        if not has_heading(text,r'Skill\s+Evidence'):
            print(f"ERROR_FOR_AGENT: {plan} declares skills '{skills}' but lacks ## Skill Evidence."); bad=True
        else:
            ev=section(text,r'Skill\s+Evidence').lower()
            for raw in split_items(skills):
                if norm(raw) and norm(raw) not in ev: print(f"ERROR_FOR_AGENT: {plan} declares skill '{raw}' but Skill Evidence does not mention it."); bad=True
    if code and list_has(skills,'rtk'):
        if has_heading(text,r'RTK\s+Usage\s+Waiver'):
            w=section(text,r'RTK\s+Usage\s+Waiver')
            if 'rtk' not in w.lower() or len(w)<40: print(f'ERROR_FOR_AGENT: {plan} RTK Usage Waiver must explain why RTK decision-impact evidence is not available.'); bad=True
        elif not has_heading(text,r'RTK\s+Usage\s+Evidence'):
            print(f'ERROR_FOR_AGENT: {plan} declares rtk for code/config/test changes but lacks ## RTK Usage Evidence.'); bad=True
        else:
            ev=section(text,r'RTK\s+Usage\s+Evidence')
            for m in ['source','action','result','decision']:
                if not re.search(r'^\s*([-*]\s*)?'+m+r'\s*:',ev,re.I|re.M): print(f'ERROR_FOR_AGENT: {plan} RTK Usage Evidence must include {m}: evidence.'); bad=True
    if code and (has_asset(vals['Templates']) or has_asset(vals['Patterns'])):
        if has_heading(text,r'Template/Pattern\s+Rating\s+Waiver'):
            if len(section(text,r'Template/Pattern\s+Rating\s+Waiver')) < 40: print(f'ERROR_FOR_AGENT: {plan} Template/Pattern Rating Waiver must explain why rating evidence is unavailable.'); bad=True
        elif not has_heading(text,r'Template/Pattern\s+Rating\s+Evidence'):
            print(f'ERROR_FOR_AGENT: {plan} uses templates/patterns assets but lacks ## Template/Pattern Rating Evidence.'); bad=True
        else:
            ev=section(text,r'Template/Pattern\s+Rating\s+Evidence')
            for m in ['asset','rating','outcome','decision']:
                if not re.search(r'^\s*([-*]\s*)?'+m+r'\s*:',ev,re.I|re.M): print(f'ERROR_FOR_AGENT: {plan} Template/Pattern Rating Evidence must include {m}: evidence.'); bad=True
    tc=clean(vals['Templates'])
    if re.search(r'(gap|missing|none|no\s+template|not\s+available|too\s+heavy)',tc) and not knowledge and not has_heading(text,r'Template\s+Gap\s+Waiver'):
        print(f'ERROR_FOR_AGENT: {plan} records a template gap but lacks changed learning/template artifact or ## Template Gap Waiver.'); bad=True
if bad: sys.exit(1)
print('Workflow evidence checks passed.')
PY
