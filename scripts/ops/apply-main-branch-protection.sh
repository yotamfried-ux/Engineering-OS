#!/usr/bin/env bash
# apply-main-branch-protection.sh — apply server-side branch protection to `main`.
#
# WHY THIS IS A SCRIPT, NOT AUTOMATED IN CI:
#   Setting branch protection needs repo-admin GitHub API access. The Engineering OS
#   build/agent environment has no such access (no gh CLI; the agent proxy blocks the
#   admin REST API). So the repo owner runs this once with their own credentials.
#
# SAFE BY DEFAULT: dry-run prints the exact request + JSON body and makes NO network
# call. Pass --apply to actually PUT the protection.
#
# Required check CONTEXTS are the check-run/job names (NOT workflow names) — derived
# from each required workflow file's job `name:` (falling back to the job id). The
# set of required workflows is sourced from REQUIRED_WORKFLOWS_DEFAULT in
# check-merge-readiness.sh, so this never drifts.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OWNER="${EOS_GH_OWNER:-yotamfried-ux}"
REPO="${EOS_GH_REPO:-Engineering-OS}"
BRANCH="${EOS_PROTECT_BRANCH:-main}"
MERGE_CHECK="$ROOT/scripts/enforcement/check-merge-readiness.sh"
WF_DIR="$ROOT/.github/workflows"

APPLY=0
for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=1 ;;
    -h|--help)
      grep -E '^# ' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

# Required workflow set (authoritative): REQUIRED_WORKFLOWS_DEFAULT in the merge checker.
required_workflows() {
  awk -F'"' '/^REQUIRED_WORKFLOWS_DEFAULT=/ { print $2; exit }' "$MERGE_CHECK" \
    | tr ' ' '\n' | sed '/^$/d'
}

# job_context <workflow-file> — the check-run context GitHub shows for the workflow's
# single job: its `name:` if set, else the job-id key under `jobs:`.
job_context() {
  awk '
    /^jobs:[[:space:]]*$/ { injobs = 1; next }
    injobs && /^[[:space:]]{2}[A-Za-z0-9_-]+:[[:space:]]*$/ && jobid == "" {
      line = $0
      sub(/^[[:space:]]+/, "", line); sub(/:.*$/, "", line)
      jobid = line
    }
    injobs && /^[[:space:]]+name:[[:space:]]*/ && jobname == "" {
      line = $0
      sub(/^[[:space:]]+name:[[:space:]]*/, "", line)
      gsub(/^["'"'"']|["'"'"']$/, "", line)
      jobname = line
    }
    END { print (jobname != "" ? jobname : jobid) }
  ' "$1"
}

contexts=()
missing=0
while IFS= read -r wf; do
  [ -n "$wf" ] || continue
  file="$WF_DIR/$wf.yml"
  if [ ! -f "$file" ]; then
    echo "ERROR: required workflow file not found: $file" >&2
    missing=1
    continue
  fi
  ctx="$(job_context "$file")"
  if [ -z "$ctx" ]; then
    echo "ERROR: could not derive a check context from $file" >&2
    missing=1
    continue
  fi
  contexts+=("$ctx")
done < <(required_workflows)

[ "$missing" -eq 0 ] || { echo "Aborting: could not resolve all required check contexts." >&2; exit 1; }
[ "${#contexts[@]}" -gt 0 ] || { echo "Aborting: no required check contexts resolved." >&2; exit 1; }

# Build the protection body (classic branch-protection API).
BODY="$(python3 - "$BRANCH" "${contexts[@]}" <<'PY'
import json, sys
branch = sys.argv[1]
contexts = sys.argv[2:]
body = {
    "required_status_checks": {"strict": True, "contexts": contexts},
    "enforce_admins": True,
    "required_pull_request_reviews": {"required_approving_review_count": 0},
    "restrictions": None,
    "allow_force_pushes": False,
    "allow_deletions": False,
}
print(json.dumps(body, indent=2))
PY
)"

API_PATH="repos/$OWNER/$REPO/branches/$BRANCH/protection"

echo "Branch protection target: $OWNER/$REPO @ $BRANCH"
echo "Required check contexts (${#contexts[@]}):"
for c in "${contexts[@]}"; do echo "  - $c"; done
echo
echo "PUT /$API_PATH"
echo "$BODY"
echo

if [ "$APPLY" -ne 1 ]; then
  echo "DRY-RUN — nothing sent. Re-run with --apply (needs repo-admin credentials)."
  echo "  gh:   uses 'gh api -X PUT' if gh is installed and authenticated"
  echo "  curl: falls back to \$GITHUB_TOKEN against api.github.com"
  exit 0
fi

# --apply: prefer gh, fall back to curl + token.
if command -v gh >/dev/null 2>&1; then
  printf '%s' "$BODY" | gh api -X PUT "$API_PATH" \
    -H "Accept: application/vnd.github+json" --input - \
    && { echo "✅ branch protection applied via gh"; exit 0; }
  echo "gh call failed; trying curl fallback…" >&2
fi

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "ERROR: no gh and no \$GITHUB_TOKEN — cannot apply. Use the GitHub UI (see docs/operations/main-required-checks.md)." >&2
  exit 1
fi

code="$(printf '%s' "$BODY" | curl -sS -o /tmp/eos-protection-resp.json -w '%{http_code}' \
  -X PUT "https://api.github.com/$API_PATH" \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  --data-binary @-)"
if [ "$code" = "200" ]; then
  echo "✅ branch protection applied via curl (HTTP 200)"
  exit 0
fi
echo "ERROR: protection PUT returned HTTP $code" >&2
cat /tmp/eos-protection-resp.json >&2 2>/dev/null || true
exit 1
