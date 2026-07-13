#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
WORKFLOW="$ROOT/.github/workflows/pr-policy.yml"
[ -f "$WORKFLOW" ] || { echo "missing $WORKFLOW"; exit 1; }
python3 - "$WORKFLOW" <<'PY'
import re,sys
text=open(sys.argv[1],encoding='utf-8').read(); failures=[]
def req(ok,msg):
    if not ok: failures.append(msg)
perm=re.search(r'^permissions:\n((?:  [a-z-]+: \w+\n)+)',text,re.M)
req(bool(perm),'missing permissions block')
perms=dict(re.findall(r'(\S+):\s*(\S+)',perm.group(1))) if perm else {}
for key in ['contents','pull-requests','checks','actions']:
    req(perms.get(key)=='read',f'permissions.{key} must be read')
req('workflow_dispatch:' in text and 'pr_number:' in text,'workflow must support telemetry-triggered dispatch by PR number')
req('gh api "repos/$REPO/pulls/$PR_NUMBER"' in text,'workflow must resolve live PR metadata for both event types')
checkouts=re.findall(r'uses:\s*actions/checkout@([0-9a-f]{40})\b',text)
req(len(checkouts)>=2,'product and telemetry checkouts must be pinned to full SHAs')
req('ref: ${{ env.PR_HEAD_SHA }}' in text,'product checkout must use exact live PR head')
req('refs/heads/engineering-os-telemetry' in text,'workflow must checkout isolated telemetry branch')
req('id: telemetry' in text and 'select-pr-telemetry.py' in text,'workflow must expose exact telemetry selection as a named step')
req('--pr-number "$PR_NUMBER"' in text and '--head-ref "$PR_HEAD_REF"' in text and '--head-sha "$PR_HEAD_SHA"' in text,'selector must receive PR, branch and exact head')
req('echo "available=true" >> "$GITHUB_OUTPUT"' in text and 'steps.telemetry.outputs.available' in text,'artifact upload must use explicit selector output')
req("hashFiles('.engineering-os/selected-telemetry/manifest.json')" not in text,'gitignored telemetry must not be detected with hashFiles')
req('--telemetry-file .engineering-os/selected-telemetry/events.jsonl' in text,'OWH collector must receive selected remote events')
req('session-telemetry-${{ env.PR_NUMBER }}-${{ github.run_id }}' in text,'matched telemetry must be uploaded as an artifact')
req('reviewThreads(first:100,after:$endCursor)' in text and 'check-live-review-threads.py' in text,'workflow must fetch and validate live review threads')
req('gh api --paginate' in text and 'index(${PR_NUMBER})' in text,'CI history must be paginated and PR-scoped')
req('-f branch="$HEAD_REF"' not in text and 'gh run list' not in text and '--limit 100' not in text,'branch-only or fixed-limit CI history must not return')
collector=text.find('collect-pr-work-history.py'); checker=text.find('check-pr-review-evidence.sh'); live=text.find('check-live-review-threads.py')
req(collector!=-1 and checker!=-1 and collector<checker,'OWH collector must precede evidence gate')
req(live!=-1 and checker!=-1 and live<checker,'live thread gate must precede PR-body evidence gate')
req('git diff --name-only "$PR_BASE_SHA...$PR_HEAD_SHA"' in text and '[ ! -s /tmp/changed-files.txt ]' in text,'changed-file evidence must fail closed')
for ref in re.findall(r'uses:\s*(actions/upload-artifact@\S+)',text):
    req(bool(re.search(r'@[0-9a-f]{40}\b',ref)),f'upload action not pinned: {ref}')
if failures:
    print('pr-policy workflow wiring failures:')
    for item in failures: print('-',item)
    raise SystemExit(1)
print('pr-policy workflow wiring passed')
PY
