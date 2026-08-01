#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
SOURCE_LIB="$ROOT/scripts/enforcement/lib/evidence.sh"
POLICY="$ROOT/scripts/enforcement/bypass-policy.tsv"
CONTROL="$ROOT/scripts/enforcement/bypass-control-plane.json"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
pass() { printf 'PASS: %s\n' "$*"; }

make_fixture() {
  local dst="$1"
  mkdir -p "$dst/scripts/enforcement/lib" "$dst/.claude/.evidence"
  cp "$SOURCE_LIB" "$dst/scripts/enforcement/lib/evidence.sh"
  cp "$POLICY" "$dst/scripts/enforcement/bypass-policy.tsv"
  cp "$CONTROL" "$dst/scripts/enforcement/bypass-control-plane.json"
  cat > "$dst/scripts/enforcement/validate-bypass-approval.py" <<'PY'
import json
import os
from pathlib import Path
Path(os.environ["STUB_CALLS"]).write_text("called\n", encoding="utf-8")
print(json.dumps({"authorized": True, "schema": "stub"}))
PY
}

run_request() {
  local root="$1" name="$2"; shift 2
  (
    cd "$root"
    export EOS_EVIDENCE_DIR="$root/.claude/.evidence"
    export STUB_CALLS="$root/stub-calls"
    # shellcheck source=/dev/null
    . "$root/scripts/enforcement/lib/evidence.sh"
    bypass_active "$name" "$@"
  )
}

fp="$(printf 'a%.0s' {1..64})"
commit="$(printf 'b%.0s' {1..40})"
context=(workflow allow-work-command-before-plan PreToolUse yotamfried-ux/Engineering-OS 'command:echo test' "$fp" "$commit" 123)

fixture="$TMP/base"
make_fixture "$fixture"

if EOS_BYPASS_ENTRY=0 run_request "$fixture" EOS_BYPASS_ENTRY "${context[@]}"; then
  fail 'false request unexpectedly authorized'
fi
[ ! -e "$fixture/stub-calls" ] || fail 'validator called for false request'
pass 'non-truthy request is inactive'

rm -f "$fixture/stub-calls" "$fixture/.claude/.evidence/ledger"
if EOS_BYPASS_ENTRY=1 run_request "$fixture" EOS_BYPASS_ENTRY; then
  fail 'legacy env-only call unexpectedly authorized'
fi
[ ! -e "$fixture/stub-calls" ] || fail 'validator called for incomplete context'
! grep -q $'\tbypass_authorized\t' "$fixture/.claude/.evidence/ledger" 2>/dev/null || fail 'rejected legacy request recorded authorization'
pass 'env-only legacy request fails closed'

while IFS=$'\t' read -r name _gate _action _surface _target _fingerprint _commit classification; do
  [ "$classification" = master-disabled ] || continue
  rm -f "$fixture/stub-calls" "$fixture/.claude/.evidence/ledger"
  if env "$name=1" bash -c '
      set -euo pipefail
      root="$1"; request="$2"; fp="$3"; commit="$4"
      cd "$root"; export EOS_EVIDENCE_DIR="$root/.claude/.evidence" STUB_CALLS="$root/stub-calls"
      . "$root/scripts/enforcement/lib/evidence.sh"
      bypass_active "$request" master disabled PreToolUse yotamfried-ux/Engineering-OS target "$fp" "$commit" 123
    ' bash "$fixture" "$name" "$fp" "$commit"; then
    fail "$name master request unexpectedly authorized"
  fi
  [ ! -e "$fixture/stub-calls" ] || fail "$name reached validator"
  ! grep -q $'\tbypass_authorized\t' "$fixture/.claude/.evidence/ledger" 2>/dev/null || fail "$name recorded authorization"
done < <(tail -n +2 "$POLICY")
pass 'all master bypass requests are explicitly disabled'


root="$TMP/master-helper"
make_fixture "$root"
if EOS_BYPASS_WORKFLOW=1 bash -c '
  set -euo pipefail
  root="$1"; cd "$root"; export EOS_EVIDENCE_DIR="$root/.claude/.evidence"
  . "$root/scripts/enforcement/lib/evidence.sh"
  bypass_reject_disabled_master_requests EOS_BYPASS_WORKFLOW
' bash "$root"; then
  fail 'truthy master request passed bypass_reject_disabled_master_requests'
fi
! grep -q $'\tbypass_authorized\t' "$root/.claude/.evidence/ledger" 2>/dev/null || fail 'master helper rejection recorded authorization'
pass 'truthy master request is denied by canonical master helper'

for helper in eos_truthy _bypass_reject; do
  root="$TMP/missing-helper-$helper"
  make_fixture "$root"
  if EOS_BYPASS_WORKFLOW=1 bash -c '
    set -euo pipefail
    root="$1"; helper="$2"; cd "$root"; export EOS_EVIDENCE_DIR="$root/.claude/.evidence"
    . "$root/scripts/enforcement/lib/evidence.sh"
    unset -f "$helper"
    bypass_reject_disabled_master_requests EOS_BYPASS_WORKFLOW
  ' bash "$root" "$helper"; then
    fail "missing $helper unexpectedly allowed master request"
  fi
  ! grep -q $'\tbypass_authorized\t' "$root/.claude/.evidence/ledger" 2>/dev/null || fail "missing $helper recorded authorization"
done
pass 'missing master-request helpers fail closed'

root="$TMP/missing-library"
mkdir -p "$root/scripts/enforcement"
cp "$ROOT/scripts/enforcement/enforce-bash-entry.sh" "$root/scripts/enforcement/enforce-bash-entry.sh"
set +e
printf '%s\n' '{"tool_input":{"command":"echo test"}}' | EOS_BYPASS_ENTRY=1 bash "$root/scripts/enforcement/enforce-bash-entry.sh" >"$root/out" 2>"$root/err"
rc=$?
set -e
[ "$rc" -ne 0 ] || fail 'missing canonical library unexpectedly allowed enforcer'
grep -q 'canonical bypass library is unavailable' "$root/err" || fail 'missing canonical library did not emit fail-closed denial'
pass 'missing canonical bypass library fails closed'

for missing in validator policy control; do
  root="$TMP/missing-$missing"
  make_fixture "$root"
  case "$missing" in
    validator) rm "$root/scripts/enforcement/validate-bypass-approval.py" ;;
    policy) rm "$root/scripts/enforcement/bypass-policy.tsv" ;;
    control) rm "$root/scripts/enforcement/bypass-control-plane.json" ;;
  esac
  if EOS_BYPASS_ENTRY=1 run_request "$root" EOS_BYPASS_ENTRY "${context[@]}"; then
    fail "missing $missing unexpectedly authorized"
  fi
  ! grep -q $'\tbypass_authorized\t' "$root/.claude/.evidence/ledger" 2>/dev/null || fail "missing $missing recorded authorization"
done
pass 'missing validator, policy, or control configuration fails closed'

root="$TMP/override"
make_fixture "$root"
if EOS_BYPASS_ENTRY=1 EOS_BYPASS_VALIDATOR_PATH=/tmp/evil.py run_request "$root" EOS_BYPASS_ENTRY "${context[@]}"; then
  fail 'path override unexpectedly authorized'
fi
[ ! -e "$root/stub-calls" ] || fail 'path override reached validator'
pass 'validator path override fails closed'

root="$TMP/success"
make_fixture "$root"
EOS_BYPASS_ENTRY=1 run_request "$root" EOS_BYPASS_ENTRY "${context[@]}" || fail 'structured verified success was denied'
grep -q $'\tbypass_authorized\tEOS_BYPASS_ENTRY:123:' "$root/.claude/.evidence/ledger" || fail 'verified success did not record authorization evidence'
[ -f "$root/stub-calls" ] || fail 'verified success did not invoke validator'
pass 'authorization evidence is written only after structured success'

printf 'test-bypass-request-fail-closed: PASS\n'
