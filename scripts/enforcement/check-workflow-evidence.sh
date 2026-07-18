#!/usr/bin/env bash
set -euo pipefail
python3 - "$@" <<'PY'
import os, re, subprocess, sys
base=sys.argv[1] if len(sys.argv)>1 else 'HEAD~1'
head=sys.argv[2] if len(sys.argv)>2 else 'HEAD'
def sh(*a): return subprocess.check_output(a,text=True).splitlines()
def gt(*a):
    try: return subprocess.check_output(a,text=True,stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError: return ''
def norm(s): return re.sub(r'[^a-z0-9_./-]+','-',re.sub(r'^[\s*`-]+|[\s`.,;:]+$','',(s or '').lower())).strip('-')
def clean(s): return re.sub(r'[`*_]','',s or '').strip().lower()
def split_items(s): return [x for x in re.split(r'[,;]\s*|\s+and\s+',s or '',flags=re.I) if x.strip()]
def field(text,name_re):
    for line in text.splitlines():
        if '|' not in line: continue
        cells=[re.sub(r'[`*_]','',c).strip() for c in line.split('|')]
        for i,c in enumerate(cells[:-1]):
            if re.search(name_re,c.lower()): return cells[i+1].strip()
    return ''
def section(text,title_re):
    out=[]; on=False
    for line in text.splitlines():
        if re.match(r'^#{1,4}\s+'+title_re+r'(\s|$)',line,re.I): on=True; continue
        if on and re.match(r'^#{1,4}\s+',line): break
        if on: out.append(line)
    return '\n'.join(out)
def has_heading(text,title_re): return re.search(r'^#{1,4}\s+'+title_re+r'(\s|$)',text,re.I|re.M) is not None
def assets(value,kind=None):
    out=[]
    pat=(kind or r'templates|patterns')
    for raw in split_items(value):
        for m in re.finditer(r'('+pat+r')/[^\s,;`]+',raw or '',re.I):
            out.append(m.group(0).strip('`.,;:)]}'))
    return out
def has_asset(value): return bool(assets(value))
def rating_assets(ev):
    out=[]
    for line in ev.splitlines():
        m=re.match(r'^\s*(?:[-*]\s*)?asset\s*:\s*(.+)$',line,re.I)
        if m: out.extend(assets(m.group(1),'patterns'))
    return out
def evidence_value(ev,key):
    pat=re.escape(key).replace(r'\ ',r'\s+')
    for line in ev.splitlines():
        m=re.match(r'^\s*(?:[-*]\s*)?'+pat+r'\s*:\s*(.+)$',line,re.I)
        if m: return m.group(1).strip()
    return ''
def evidence_has(ev,key): return bool(evidence_value(ev,key))
def source_matches(src,targets):
    low=src.lower()
    for t in split_items(targets):
        k=norm(t)
        if not k: continue
        d=k.rsplit('/',1)[0] if '/' in k else k; b=k.rsplit('/',1)[-1]
        if k in low or d in low or b in low: return True
        if (k.startswith('core/') or k=='claude.md') and re.search(r'claude\.md|core/task-router\.md|core/workflow\.md',low): return True
    return False
def exact_target_matches(value,targets):
    low=norm(value)
    for t in split_items(targets):
        k=norm(t)
        if not k: continue
        b=k.rsplit('/',1)[-1]
        if k in low or ('.' in b and b in low): return True
    return False
def source_entries(src):
    out=[]
    for line in src.splitlines():
        if '|' not in line: continue
        cells=[re.sub(r'[`*_]','',c).strip() for c in line.split('|')]
        cells=[c for c in cells if c]
        if len(cells)<2: continue
        if cells[0].lower()=='source' or re.match(r'^-+$',cells[0]): continue
        if re.match(r'^(checked|read|validated)$',cells[1],re.I): out.append(cells[0])
    return out
def concrete_source(v):
    s=(v or '').strip(); n=norm(s)
    if not n or any(ord(ch) in (42,63,91,93) for ch in s) or s.endswith('/') or n.endswith('/'): return False
    if re.match(r'^(docs|docs/operations|scripts|scripts/enforcement|\.github|\.github/workflows|core)$',n): return False
    if re.match(r'^[a-z0-9_.-]+/[a-z0-9_.-]+$',n) and '.' not in n.rsplit('/',1)[-1]: return False
    return bool('/' in n or '.' in n)
changed=sh('git','diff','--name-only',base,head)
plans=[p for p in changed if re.match(r'^\.claude/plans/.*\.md$',p) and os.path.exists(p)]
code=[p for p in changed if p and not re.match(r'^\.claude/plans/|^docs/|^README\.md$|^CHANGELOG\.md$|^LICENSE',p)]
knowledge=[p for p in changed if re.match(r'^(lessons-learned/|failed-solutions/|templates/)',p)]
commits=[]; commit_files={}; code_idxs=[]
if code:
    commits=sh('git','rev-list','--reverse',f'{base}..{head}')

    # A branch may legitimately build on another open PR/branch whose commits are
    # already merged in (e.g. via fast-forward) before this branch's own Route Plan
    # commit. Those inherited commits should not be treated as this PR's own
    # code-before-plan violation. A plan may declare the exact inherited boundary via
    # "Inherited base commit: <sha>" (+ a concrete "Inherited base reason: ..." of at
    # least 20 characters) naming the tip of the pre-existing history it builds on.
    # This only ever exempts commits at/before that declared, git-verified ancestor
    # from "code" classification — every commit from there to head (including this
    # branch's own plan and its own code) is still fully subject to the ordering rule,
    # so a branch cannot use the marker to move its own code ahead of its own plan.
    inherited_marker_re=re.compile(r'^\s*Inherited\s+base\s+commit\s*:\s*([0-9a-fA-F]{7,40})\s*$',re.I|re.M)
    inherited_reason_re=re.compile(r'^\s*Inherited\s+base\s+reason\s*:\s*(.+)$',re.I|re.M)
    inherited_plan=inherited_sha=inherited_reason=None
    for p in plans:
        ptext=gt('git','show',f'{head}:{p}')
        if not ptext: continue
        m=inherited_marker_re.search(ptext)
        if m:
            inherited_plan, inherited_sha = p, m.group(1)
            rm=inherited_reason_re.search(ptext)
            inherited_reason = rm.group(1).strip() if rm else ''
            break

    exempt_idx=0
    if inherited_sha:
        resolved=gt('git','rev-parse',inherited_sha).strip()
        if not resolved or resolved not in commits:
            print(f'ERROR_FOR_AGENT: {inherited_plan} declares Inherited base commit {inherited_sha} but it is not an ancestor commit within this diff range ({base}..{head}).'); sys.exit(1)
        if len(clean(inherited_reason))<20:
            print(f'ERROR_FOR_AGENT: {inherited_plan} declares Inherited base commit {inherited_sha} but Inherited base reason is missing or too short (need a concrete reason of at least 20 characters explaining what is inherited and from where).'); sys.exit(1)
        exempt_idx=commits.index(resolved)+1

    first_plan=first_code=0
    plan_first_idx={}
    for idx,c in enumerate(commits,1):
        fs=sh('git','diff-tree','--no-commit-id','--name-only','-r',c); commit_files[c]=fs
        for f in fs:
            if re.match(r'^\.claude/plans/.*\.md$',f) and f not in plan_first_idx: plan_first_idx[f]=idx
        cfs=[f for f in fs if f and not re.match(r'^\.claude/plans/|^docs/|^README\.md$|^CHANGELOG\.md$|^LICENSE',f)]
        if cfs and idx>exempt_idx: code_idxs.append(idx)
        if not first_code and cfs and idx>exempt_idx: first_code=idx

    # Plan files whose first appearance is at/before the exempted boundary belong to
    # the inherited history, not this branch's own Route Plan — exclude them from
    # first_plan and from the downstream per-plan evidence checks below, the same way
    # exempt_idx already excludes inherited commits from code classification. Without
    # this, an inherited branch's own (already-validated-elsewhere) plan file would
    # both miscompute first_plan and get re-validated against this branch's own
    # DoD/Progress-Lifecycle timeline, which this script was never meant to do for a
    # plan this PR didn't author.
    if exempt_idx:
        plans=[p for p in plans if plan_first_idx.get(p,0)>exempt_idx]
    first_plan=min((i for p,i in plan_first_idx.items() if not exempt_idx or i>exempt_idx),default=0)

    if exempt_idx:
        if not first_plan or exempt_idx>=first_plan:
            print(f'ERROR_FOR_AGENT: {inherited_plan} Inherited base commit {inherited_sha} must be an ancestor of this branch\'s own Route Plan commit, not at or after it — it cannot be used to exempt commits from the ordering rule.'); sys.exit(1)

    if not first_plan or (code_idxs and (not first_code or first_code<=first_plan)):
        print('ERROR_FOR_AGENT: Route Plan must be committed before the first code/config/test change, not in the same or later commit.'); sys.exit(1)
if not plans:
    print('No changed plan files.'); sys.exit(0)
FUTURE_RE=re.compile(r'\b(will|planned|pending|todo|tbd|later|must\s+be|needs?\s+to|to\s+be)\b',re.I)
def checkpoint_lines(text,marker):
    return [l.strip() for l in section(text,r'Progress\s+Lifecycle\s+Evidence').splitlines() if re.search(r'(^|[^a-z])'+re.escape(marker)+r'\s*:',l,re.I)]
def real_lines(text,marker): return {l for l in checkpoint_lines(text,marker) if l and not FUTURE_RE.search(l)}
def introduced(prev,cur,marker): return bool(real_lines(cur,marker)-real_lines(prev,marker))
def plan_events(plan):
    out=[]
    for idx,c in enumerate(commits,1):
        if plan not in commit_files.get(c,[]): continue
        cur=gt('git','show',f'{c}:{plan}'); prev=gt('git','show',f'{c}^:{plan}')
        if cur: out.append((idx,prev,cur))
    return out
def progress_failures(plan):
    if not code_idxs: return []
    events=plan_events(plan); first=min(code_idxs); last=max(code_idxs); fails=[]
    start=[i for i,p,c in events if i<first and introduced(p,c,'start')]
    mid=[i for i,p,c in events if i>first and introduced(p,c,'mid')]
    pre=[i for i,p,c in events if i>last and introduced(p,c,'pre-merge')]
    if not start: fails.append('start checkpoint evidence must be introduced in the Route Plan before the first code/config/test change.')
    if not mid: fails.append('mid checkpoint evidence must be introduced or materially updated after work begins, not only copied from a prefilled plan.')
    if not pre: fails.append('pre-merge checkpoint evidence must be introduced or materially updated after the last code/config/test change.')
    if mid and pre and not any(m<p for m in mid for p in pre): fails.append('mid and pre-merge checkpoint evidence must be committed as ordered lifecycle updates, not a single final backfill.')
    return fails
bad=False
for plan in plans:
    text=open(plan,encoding='utf-8').read()
    vals={n:field(text,r'^'+re.escape(n.lower())+r'$') for n in ['Task-router evidence','Workflow evidence','Templates','Patterns','Skills','Validation gates']}
    targets=field(text,r'^target paths?$')
    for n,v in vals.items():
        if not clean(v) or re.match(r'^(todo|tbd|placeholder|unknown|later|fix\s*later|to\s*decide)$',clean(v)):
            print(f'ERROR_FOR_AGENT: {plan} has missing or placeholder {n}.'); bad=True
    src=section(text,r'Source\s+of\s+Truth\s+Checks')
    if not has_heading(text,r'Source\s+of\s+Truth\s+Checks'):
        print(f'ERROR_FOR_AGENT: {plan} is missing ## Source of Truth Checks.'); bad=True
    else:
        if len(re.findall(r'\|\s*[^|]+\s*\|\s*(checked|read|validated)\s*\|',src,re.I))<2:
            print(f'ERROR_FOR_AGENT: {plan} Source of Truth Checks must include at least two checked/read sources.'); bad=True
        for source in source_entries(src):
            if not concrete_source(source): print(f'ERROR_FOR_AGENT: {plan} Source of Truth Checks must reference concrete files, not broad source "{source}".'); bad=True
        if code and clean(targets) and not source_matches(src,targets):
            print(f'ERROR_FOR_AGENT: {plan} Source of Truth Checks do not reference any Target paths or canonical routing/workflow source.'); bad=True
    if code:
        # DoD quality schema: items must be concrete and at least one must name a
        # verification signal. Deep DoD quality stays review-based by design.
        dod_re=r'(DoD|Definition\s+of\s+Done)'
        if not has_heading(text,dod_re):
            print(f'ERROR_FOR_AGENT: {plan} changes code/config/tests but lacks a ## DoD / Definition of Done section.'); bad=True
        else:
            dod=section(text,dod_re)
            items=[re.sub(r'^\s*[-*]\s*(\[[ xX]\]\s*)?','',l).strip() for l in dod.splitlines() if re.match(r'^\s*[-*]',l)]
            if not items:
                print(f'ERROR_FOR_AGENT: {plan} DoD section must contain checklist items.'); bad=True
            for it in items:
                if len(clean(it))<12 or re.search(r'\b(todo|tbd|placeholder|later|unknown|etc)\b',it,re.I):
                    print(f'ERROR_FOR_AGENT: {plan} DoD item is vague or placeholder: "{it}".'); bad=True
            if items and not any(re.search(r'\b(test|tests|tested|fixture|fixtures|ci|checker|suite|gate|gates|validator)\b',it,re.I) for it in items):
                print(f'ERROR_FOR_AGENT: {plan} DoD must include at least one item naming a concrete verification signal (test/fixture/CI/checker/suite/gate).'); bad=True
        if not has_heading(text,r'Claude\s+Run\s+Trace'): print(f'ERROR_FOR_AGENT: {plan} changes code/config/tests but lacks ## Claude Run Trace.'); bad=True
        if not has_heading(text,r'Progress\s+Lifecycle\s+Evidence'):
            print(f'ERROR_FOR_AGENT: {plan} changes code/config/tests but lacks ## Progress Lifecycle Evidence.'); bad=True
        else:
            for m in ['start','mid','pre-merge']:
                if not real_lines(text,m): print(f'ERROR_FOR_AGENT: {plan} Progress Lifecycle Evidence must include concrete {m} checkpoint evidence, not a future/pending placeholder.'); bad=True
            for f in progress_failures(plan): print(f'ERROR_FOR_AGENT: {plan} {f}'); bad=True
    sc=clean(vals['Skills'])
    if sc and not re.match(r'^(none|n/a|na|not\s+required|no\s+skills)$',sc):
        ev=section(text,r'Skill\s+Evidence').lower()
        if not has_heading(text,r'Skill\s+Evidence'):
            print(f"ERROR_FOR_AGENT: {plan} declares skills '{vals['Skills']}' but lacks ## Skill Evidence."); bad=True
        else:
            for raw in split_items(vals['Skills']):
                if norm(raw) and norm(raw) not in ev: print(f"ERROR_FOR_AGENT: {plan} declares skill '{raw}' but Skill Evidence does not mention it."); bad=True
    if code and any(norm(x)=='rtk' for x in split_items(vals['Skills'])):
        if has_heading(text,r'RTK\s+Usage\s+Waiver'):
            w=section(text,r'RTK\s+Usage\s+Waiver')
            if 'rtk' not in w.lower() or len(w)<40: print(f'ERROR_FOR_AGENT: {plan} RTK Usage Waiver must explain why RTK decision-impact evidence is not available.'); bad=True
        else:
            ev=section(text,r'RTK\s+Usage\s+Evidence')
            if not has_heading(text,r'RTK\s+Usage\s+Evidence'):
                print(f'ERROR_FOR_AGENT: {plan} declares rtk for code/config/test changes but lacks ## RTK Usage Evidence.'); bad=True
            else:
                for m in ['source','action','result','decision','prior assumption','finding','impact','target','confidence','limitation']:
                    if not evidence_has(ev,m): print(f'ERROR_FOR_AGENT: {plan} RTK Usage Evidence must include {m}: evidence.'); bad=True
                if evidence_value(ev,'target') and not exact_target_matches(evidence_value(ev,'target'),targets):
                    print(f'ERROR_FOR_AGENT: {plan} RTK Usage Evidence target must match a declared Target path.'); bad=True
                impact=evidence_value(ev,'impact')
                if impact and not re.search(r'\b(changed|confirmed|rejected|limited|selected|avoided|narrowed)\b',impact,re.I):
                    print(f'ERROR_FOR_AGENT: {plan} RTK Usage Evidence impact must state how RTK changed, confirmed, rejected, limited, selected, avoided, or narrowed the decision.'); bad=True
    declared={norm(a) for a in assets(vals['Patterns'],'patterns')}
    if code and (declared or has_asset(vals['Templates'])):
        if has_heading(text,r'Template/Pattern\s+Rating\s+Waiver'):
            if len(section(text,r'Template/Pattern\s+Rating\s+Waiver'))<40: print(f'ERROR_FOR_AGENT: {plan} Template/Pattern Rating Waiver must explain why rating evidence is unavailable.'); bad=True
        else:
            ev=section(text,r'Template/Pattern\s+Rating\s+Evidence')
            if not has_heading(text,r'Template/Pattern\s+Rating\s+Evidence'):
                print(f'ERROR_FOR_AGENT: {plan} uses templates/patterns assets but lacks ## Template/Pattern Rating Evidence.'); bad=True
            else:
                for m in ['asset','rating','outcome','decision']:
                    if not re.search(r'^\s*([-*]\s*)?'+m+r'\s*:',ev,re.I|re.M): print(f'ERROR_FOR_AGENT: {plan} Template/Pattern Rating Evidence must include {m}: evidence.'); bad=True
                if not re.search(r'^\s*([-*]\s*)?confidence\s*:',ev,re.I|re.M) and not re.search(r'\bconfidence\b',ev,re.I):
                    print(f'ERROR_FOR_AGENT: {plan} Template/Pattern Rating Evidence must include confidence evidence.'); bad=True
                rated={norm(a) for a in rating_assets(ev)}
                missing=sorted(declared-rated); extra=sorted(rated-declared)
                if missing: print(f'ERROR_FOR_AGENT: {plan} Template/Pattern Rating Evidence is missing declared pattern assets: {", ".join(missing)}.'); bad=True
                if extra: print(f'ERROR_FOR_AGENT: {plan} Template/Pattern Rating Evidence names undeclared pattern assets: {", ".join(extra)}.'); bad=True
                if declared and not rated: print(f'ERROR_FOR_AGENT: {plan} Template/Pattern Rating Evidence must name concrete patterns/ assets.'); bad=True
    tc=clean(vals['Templates'])
    if re.search(r'(gap|missing|none|no\s+template|not\s+available|too\s+heavy)',tc) and not knowledge and not has_heading(text,r'Template\s+Gap\s+Waiver'):
        print(f'ERROR_FOR_AGENT: {plan} records a template gap but lacks changed learning/template artifact or ## Template Gap Waiver.'); bad=True
if bad: sys.exit(1)
print('Workflow evidence checks passed.')
PY
