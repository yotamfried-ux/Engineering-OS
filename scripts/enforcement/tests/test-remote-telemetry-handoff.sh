#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SESSION_START="$ROOT/scripts/monitoring/eos-telemetry-session-start.sh"
RECORDER="$ROOT/scripts/monitoring/eos-telemetry-event.sh"
BOUNDARY="$ROOT/scripts/monitoring/record-and-sync-telemetry.sh"
SYNC="$ROOT/scripts/monitoring/sync-telemetry-run.py"
REQUIRE="$ROOT/scripts/monitoring/require-telemetry-session.sh"
SELECT="$ROOT/scripts/monitoring/select-pr-telemetry.py"
COLLECT="$ROOT/scripts/monitoring/collect-pr-work-history.py"
REPO="example/target"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
REMOTE="$TMP/remote.git"; TARGET="$TMP/target"
export GITHUB_REPOSITORY="$REPO"
export EOS_TELEMETRY_HANDOFF_DISPATCH=0

git init --bare -q "$REMOTE"
git init -q "$TARGET"
git -C "$TARGET" config user.email telemetry@example.invalid
git -C "$TARGET" config user.name telemetry
printf 'base\n' > "$TARGET/README.md"
git -C "$TARGET" add README.md && git -C "$TARGET" commit -qm base
git -C "$TARGET" branch -M feature/test
BASE="$(git -C "$TARGET" rev-parse HEAD)"
printf 'change\n' > "$TARGET/app.txt"
git -C "$TARGET" add app.txt && git -C "$TARGET" commit -qm change
HEAD="$(git -C "$TARGET" rev-parse HEAD)"
git -C "$TARGET" remote add origin "$REMOTE"
git -C "$TARGET" push -q -u origin feature/test
mkdir -p "$TARGET/.engineering-os" "$TARGET/.claude"
POLICY="$TARGET/.engineering-os/telemetry-policy.json"
cat > "$POLICY" <<'JSON'
{"schema_version":"eos.telemetry.policy.v1","remote_handoff":{"mode":"required","remote":"origin","branch":"engineering-os-telemetry"}}
JSON
cat > "$TARGET/.claude/settings.json" <<JSON
{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"bash $SESSION_START"}]}],"PreToolUse":[{"matcher":".*","hooks":[{"type":"command","command":"bash $REQUIRE"},{"type":"command","command":"bash $RECORDER pre_tool_use"}]}],"PostToolUse":[{"matcher":".*","hooks":[{"type":"command","command":"bash $RECORDER post_tool_use"}]}],"Stop":[{"hooks":[{"type":"command","command":"bash $BOUNDARY stop"}]}],"StopFailure":[{"hooks":[{"type":"command","command":"bash $BOUNDARY stop_failure"}]}],"SessionEnd":[{"hooks":[{"type":"command","command":"bash $BOUNDARY session_end"}]}]}}
JSON

printf '%s' '{"session_id":"remote-session","hook_event_name":"SessionStart"}' | (cd "$TARGET" && bash "$SESSION_START")
(cd "$TARGET" && EOS_CLAUDE_SETTINGS_FILE="$TARGET/.claude/settings.json" bash "$REQUIRE") >/dev/null
RUN_ID="$(cat "$TARGET/.engineering-os/telemetry/run_id")"
git --git-dir="$REMOTE" show-ref --verify --quiet refs/heads/engineering-os-telemetry
printf '%s' '{"session_id":"remote-session","hook_event_name":"Stop"}' | (cd "$TARGET" && bash "$BOUNDARY" stop)
(cd "$TARGET" && EOS_CLAUDE_SETTINGS_FILE="$TARGET/.claude/settings.json" bash "$REQUIRE") >/dev/null

HANDOFF="$TMP/handoff"
git clone -q --branch engineering-os-telemetry "$REMOTE" "$HANDOFF"
PROVISIONAL="$TMP/provisional"
python3 "$SELECT" --root "$TARGET" --policy-file "$POLICY" --handoff-root "$HANDOFF" \
  --repo "$REPO" --pr-number 42 --head-ref feature/test --head-sha "$HEAD" --out "$PROVISIONAL" >/dev/null
python3 - "$PROVISIONAL" "$RUN_ID" "$REPO" <<'PY'
import json,sys
from pathlib import Path
bundle=Path(sys.argv[1]); run_id=sys.argv[2]; repo=sys.argv[3]
m=json.loads((bundle/'manifest.json').read_text())
rows=[json.loads(x) for x in (bundle/'events.jsonl').read_text().splitlines() if x.strip()]
assert m['repo']==repo and m['handoff']['repo']==repo
assert m['event_count']==len(rows)>=2
assert all(x['trace_id']==run_id for x in rows)
assert m['handoff']['pr_number']==0 and m['handoff']['pr_binding']=='provisional'
assert m['handoff']['boundary_position']==len(rows)
raw=(bundle/'events.jsonl').read_text()
assert '"eos.git.branch"' not in raw and 'eos.git.branch.hash' in raw
PY

# The selector must use the explicit trusted policy, not a disabled PR-controlled root policy.
MALICIOUS_ROOT="$TMP/malicious-root"
mkdir -p "$MALICIOUS_ROOT/.engineering-os"
cat > "$MALICIOUS_ROOT/.engineering-os/telemetry-policy.json" <<'JSON'
{"schema_version":"eos.telemetry.policy.v1","remote_handoff":{"mode":"disabled"}}
JSON
trusted_output="$(python3 "$SELECT" --root "$MALICIOUS_ROOT" --policy-file "$POLICY" \
  --handoff-root "$HANDOFF" --repo "$REPO" --pr-number 42 --head-ref feature/test \
  --head-sha "$HEAD" --out "$TMP/trusted-selected")"
case "$trusted_output" in *"selected telemetry bundle:"*) ;; *) echo "$trusted_output"; echo 'trusted policy was not exercised'; exit 1 ;; esac
[ -f "$TMP/trusted-selected/manifest.json" ] || { echo 'trusted selector produced no bundle'; exit 1; }

# A stale process that first learns the PR number must bind the newer remote bundle
# and refresh local durable state instead of leaving preflight provisional.
cp "$TARGET/.engineering-os/telemetry/events.jsonl" "$TMP/provisional-full-events.jsonl"
head -n 1 "$TMP/provisional-full-events.jsonl" > "$TARGET/.engineering-os/telemetry/events.jsonl"
race_output="$(cd "$TARGET" && EOS_TELEMETRY_PR_NUMBER=42 python3 "$SYNC" --repo "$REPO")"
case "$race_output" in *"skipped stale local bundle"*) ;; *) echo "$race_output"; echo 'missing stale provisional rebind path'; exit 1 ;; esac
(cd "$TARGET" && EOS_TELEMETRY_PR_NUMBER=42 EOS_CLAUDE_SETTINGS_FILE="$TARGET/.claude/settings.json" bash "$REQUIRE") >/dev/null
git -C "$HANDOFF" pull -q
python3 - "$HANDOFF/runs/$RUN_ID/manifest.json" "$TARGET/.engineering-os/telemetry/handoff-state.json" <<'PY'
import json,sys
remote=json.load(open(sys.argv[1])); state=json.load(open(sys.argv[2]))
assert remote['event_count']>=2
assert remote['handoff']['pr_number']==42 and remote['handoff']['pr_binding']=='exact'
assert state['pr_number']==42 and state['pr_binding']=='exact'
PY
if (cd "$TARGET" && EOS_TELEMETRY_PR_NUMBER=43 python3 "$SYNC" --repo "$REPO") >/dev/null 2>&1; then
  echo 'unexpected pass: remote run rebound to a conflicting PR'; exit 1
fi
mv "$TMP/provisional-full-events.jsonl" "$TARGET/.engineering-os/telemetry/events.jsonl"

printf '%s' '{"session_id":"remote-session","hook_event_name":"PostToolUse","tool_name":"Read"}' | (cd "$TARGET" && bash "$RECORDER" post_tool_use)
(cd "$TARGET" && EOS_TELEMETRY_PR_NUMBER=42 python3 "$SYNC" --repo "$REPO") >/dev/null
git -C "$HANDOFF" pull -q
SELECTED="$TMP/selected"
python3 "$SELECT" --root "$TARGET" --policy-file "$POLICY" --handoff-root "$HANDOFF" \
  --repo "$REPO" --pr-number 42 --head-ref feature/test --head-sha "$HEAD" --out "$SELECTED" >/dev/null
python3 - "$SELECTED" <<'PY'
import json,sys
from pathlib import Path
m=json.loads((Path(sys.argv[1])/'manifest.json').read_text())
assert m['handoff']['pr_number']==42 and m['handoff']['pr_binding']=='exact'
assert m['event_count']>=3
PY
(cd "$TARGET" && EOS_TELEMETRY_PR_NUMBER=42 EOS_CLAUDE_SETTINGS_FILE="$TARGET/.claude/settings.json" bash "$REQUIRE") >/dev/null

if (cd "$TARGET" && EOS_TELEMETRY_PR_NUMBER=42 python3 "$SYNC" --repo target) >/dev/null 2>&1; then
  echo 'unexpected pass: non-canonical repository identity'; exit 1
fi

expect_selector_failure() {
  local label="$1"; shift
  if python3 "$SELECT" --root "$TARGET" --policy-file "$POLICY" --handoff-root "$HANDOFF" \
    "$@" --out "$TMP/bad-$label" >/dev/null 2>&1; then
    echo "unexpected pass: $label"; exit 1
  fi
}
expect_selector_failure wrong-repo --repo other/repo --pr-number 42 --head-ref feature/test --head-sha "$HEAD"
expect_selector_failure wrong-pr --repo "$REPO" --pr-number 9 --head-ref feature/test --head-sha "$HEAD"
expect_selector_failure wrong-branch --repo "$REPO" --pr-number 42 --head-ref other --head-sha "$HEAD"
expect_selector_failure stale-head --repo "$REPO" --pr-number 42 --head-ref feature/test --head-sha 0000000000000000000000000000000000000000

# A stale overlapping sync cannot downgrade the newer remote event/boundary count.
cp "$TARGET/.engineering-os/telemetry/events.jsonl" "$TMP/full-events.jsonl"
head -n 2 "$TMP/full-events.jsonl" > "$TARGET/.engineering-os/telemetry/events.jsonl"
stale_output="$(cd "$TARGET" && EOS_TELEMETRY_PR_NUMBER=42 python3 "$SYNC" --repo "$REPO")"
case "$stale_output" in *"skipped stale local bundle"*) ;; *) echo "$stale_output"; echo 'missing stale-sync protection'; exit 1 ;; esac
mv "$TMP/full-events.jsonl" "$TARGET/.engineering-os/telemetry/events.jsonl"
git -C "$HANDOFF" pull -q
python3 - "$HANDOFF/runs/$RUN_ID/manifest.json" <<'PY'
import json,sys
m=json.load(open(sys.argv[1]))
assert m['event_count']>=3 and m['handoff']['pr_number']==42
PY

cp -R "$HANDOFF" "$TMP/corrupt"
printf 'tamper\n' >> "$TMP/corrupt/runs/$RUN_ID/events.jsonl"
if python3 "$SELECT" --root "$TARGET" --policy-file "$POLICY" --handoff-root "$TMP/corrupt" \
  --repo "$REPO" --pr-number 42 --head-ref feature/test --head-sha "$HEAD" --out "$TMP/bad-checksum" >/dev/null 2>&1; then
  echo 'unexpected pass: checksum mismatch'; exit 1
fi

cp -R "$HANDOFF" "$TMP/privacy"
python3 - "$TMP/privacy/runs/$RUN_ID" <<'PY'
import hashlib,json,sys
from pathlib import Path
b=Path(sys.argv[1]); e=b/'events.jsonl'; m=b/'manifest.json'
rows=[json.loads(x) for x in e.read_text().splitlines() if x.strip()]
rows[0]['prompt']='VALUE_SHOULD_NOT_APPEAR'
e.write_text('\n'.join(json.dumps(x,sort_keys=True) for x in rows)+'\n')
manifest=json.loads(m.read_text()); manifest['checksums']['events_sha256']=hashlib.sha256(e.read_bytes()).hexdigest(); m.write_text(json.dumps(manifest,sort_keys=True))
PY
if python3 "$SELECT" --root "$TARGET" --policy-file "$POLICY" --handoff-root "$TMP/privacy" \
  --repo "$REPO" --pr-number 42 --head-ref feature/test --head-sha "$HEAD" --out "$TMP/bad-privacy" >/dev/null 2>&1; then
  echo 'unexpected pass: privacy-invalid bundle'; exit 1
fi

cp -R "$HANDOFF" "$TMP/array-secret"
python3 - "$TMP/array-secret/runs/$RUN_ID" <<'PY'
import hashlib,json,sys
from pathlib import Path
b=Path(sys.argv[1]); e=b/'events.jsonl'; m=b/'manifest.json'
rows=[json.loads(x) for x in e.read_text().splitlines() if x.strip()]
rows[0].setdefault('attributes', {})['labels']=['safe', 'ghp_12345678901234567890']
e.write_text('\n'.join(json.dumps(x,sort_keys=True) for x in rows)+'\n')
manifest=json.loads(m.read_text()); manifest['checksums']['events_sha256']=hashlib.sha256(e.read_bytes()).hexdigest(); m.write_text(json.dumps(manifest,sort_keys=True))
PY
if python3 "$SELECT" --root "$TARGET" --policy-file "$POLICY" --handoff-root "$TMP/array-secret" \
  --repo "$REPO" --pr-number 42 --head-ref feature/test --head-sha "$HEAD" --out "$TMP/bad-array" >/dev/null 2>&1; then
  echo 'unexpected pass: array-nested secret'; exit 1
fi

cp -R "$HANDOFF" "$TMP/empty"
python3 - "$TMP/empty/runs/$RUN_ID" <<'PY'
import hashlib,json,sys
from pathlib import Path
b=Path(sys.argv[1]); e=b/'events.jsonl'; m=b/'manifest.json'
e.write_text(''); manifest=json.loads(m.read_text())
manifest['event_count']=0; manifest['handoff']['event_count']=0; manifest['handoff']['boundary_position']=0
manifest['checksums']['events_sha256']=hashlib.sha256(b'').hexdigest(); m.write_text(json.dumps(manifest,sort_keys=True))
PY
if python3 "$SELECT" --root "$TARGET" --policy-file "$POLICY" --handoff-root "$TMP/empty" \
  --repo "$REPO" --pr-number 42 --head-ref feature/test --head-sha "$HEAD" --out "$TMP/bad-empty" >/dev/null 2>&1; then
  echo 'unexpected pass: zero-event bundle'; exit 1
fi

CHECKOUT="$TMP/checkout"
git clone -q "$REMOTE" "$CHECKOUT"; git -C "$CHECKOUT" checkout -q feature/test
cat > "$TMP/body.md" <<'MD'
## Operational Work History Evidence
selected_result_loop_contract: booking-system
MD
python3 "$COLLECT" --root "$CHECKOUT" --pr-head-sha "$HEAD" --base-sha "$BASE" --pr-number 42 \
  --pr-body-file "$TMP/body.md" --telemetry-file "$SELECTED/events.jsonl" --out "$TMP/work-history" >/dev/null
python3 - "$TMP/work-history/latest.json" <<'PY'
import json,sys
r=json.load(open(sys.argv[1])); assert r['telemetry_available'] is True and r['telemetry_events_count'] >= 3
PY

STATE="$TARGET/.engineering-os/telemetry/handoff-state.json"
cp "$STATE" "$TMP/state-valid.json"
assert_state_mismatch() {
  local field="$1" value="$2"
  python3 - "$STATE" "$field" "$value" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p)); d[sys.argv[2]]=sys.argv[3]; open(p,'w').write(json.dumps(d))
PY
  if (cd "$TARGET" && EOS_TELEMETRY_PR_NUMBER=42 EOS_CLAUDE_SETTINGS_FILE="$TARGET/.claude/settings.json" bash "$REQUIRE") >/dev/null 2>&1; then
    echo "unexpected pass: stale state $field"; exit 1
  fi
  cp "$TMP/state-valid.json" "$STATE"
}
assert_state_mismatch repo other/repo
assert_state_mismatch source_branch_hash 00000000000000000000000000000000
assert_state_mismatch head_sha 0000000000000000000000000000000000000000
assert_state_mismatch remote upstream
assert_state_mismatch remote_branch other-telemetry

printf 'new head\n' > "$TARGET/head-change.txt"
git -C "$TARGET" add head-change.txt && git -C "$TARGET" commit -qm 'test head change'
if (cd "$TARGET" && EOS_TELEMETRY_PR_NUMBER=42 EOS_CLAUDE_SETTINGS_FILE="$TARGET/.claude/settings.json" bash "$REQUIRE") >/dev/null 2>&1; then
  echo 'unexpected pass: durable state from previous head'; exit 1
fi
git -C "$TARGET" reset -q --hard HEAD~1
(cd "$TARGET" && EOS_TELEMETRY_PR_NUMBER=42 EOS_CLAUDE_SETTINGS_FILE="$TARGET/.claude/settings.json" bash "$REQUIRE") >/dev/null

rm -f "$STATE"
if (cd "$TARGET" && EOS_TELEMETRY_PR_NUMBER=42 EOS_CLAUDE_SETTINGS_FILE="$TARGET/.claude/settings.json" bash "$REQUIRE") >/dev/null 2>&1; then
  echo 'unexpected pass: missing durable handoff state'; exit 1
fi
cp "$TMP/state-valid.json" "$STATE"

# Remote data is untrusted: identity or progress tampering must fail before stale-skip/state success.
git -C "$HANDOFF" config user.email telemetry@example.invalid
git -C "$HANDOFF" config user.name telemetry
git -C "$HANDOFF" pull -q
cp "$HANDOFF/runs/$RUN_ID/manifest.json" "$TMP/remote-valid-manifest.json"
python3 - "$HANDOFF/runs/$RUN_ID/manifest.json" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p)); d['head_sha']='0'*40; d['handoff']['head_sha']='0'*40; open(p,'w').write(json.dumps(d))
PY
git -C "$HANDOFF" add "runs/$RUN_ID/manifest.json" && git -C "$HANDOFF" commit -qm 'tamper remote identity' && git -C "$HANDOFF" push -q
if (cd "$TARGET" && EOS_TELEMETRY_PR_NUMBER=42 python3 "$SYNC" --repo "$REPO") >/dev/null 2>&1; then
  echo 'unexpected pass: mismatched remote identity trusted'; exit 1
fi
cp "$TMP/remote-valid-manifest.json" "$HANDOFF/runs/$RUN_ID/manifest.json"
git -C "$HANDOFF" add "runs/$RUN_ID/manifest.json" && git -C "$HANDOFF" commit -qm 'restore remote identity' && git -C "$HANDOFF" push -q
python3 - "$HANDOFF/runs/$RUN_ID/manifest.json" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p)); d['event_count']=999; d['handoff']['event_count']=999; open(p,'w').write(json.dumps(d))
PY
git -C "$HANDOFF" add "runs/$RUN_ID/manifest.json" && git -C "$HANDOFF" commit -qm 'tamper remote progress' && git -C "$HANDOFF" push -q
if (cd "$TARGET" && EOS_TELEMETRY_PR_NUMBER=42 python3 "$SYNC" --repo "$REPO") >/dev/null 2>&1; then
  echo 'unexpected pass: invalid remote progress trusted'; exit 1
fi

echo 'remote telemetry handoff tests passed'
