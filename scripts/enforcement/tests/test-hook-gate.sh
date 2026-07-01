#!/usr/bin/env bash
# test-hook-gate.sh — proves hook-gate.sh converts a legacy exit-1 enforcer into a
# real Claude Code PreToolUse block (permissionDecision=deny on stdout, exit 0),
# passes successes through, forwards native deny JSON verbatim, and fails OPEN when
# the enforcer is missing.
#
# Governing policy: core/hooks-policy.md
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
GATE="$ROOT/scripts/enforcement/lib/hook-gate.sh"
chmod +x "$GATE"

pass=0; fail=0
ok()  { echo "  ✅ $1"; pass=$((pass+1)); }
bad() { echo "  ❌ $1"; fail=$((fail+1)); }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
DENY='permission''Decision'  # avoid embedding the literal token

EVENT='{"tool_name":"Write","tool_input":{"file_path":"src/x.js"}}'

# 1) Legacy enforcer that exits 1 with an ERROR_FOR_AGENT message → deny JSON, exit 0.
cat > "$WORK/blocker.sh" <<'EOF'
#!/usr/bin/env bash
echo "ERROR_FOR_AGENT: workflow.md gate — no plan exists."
exit 1
EOF
chmod +x "$WORK/blocker.sh"
out="$(printf '%s' "$EVENT" | bash "$GATE" "$WORK/blocker.sh")"; code=$?
if [ "$code" -eq 0 ] && printf '%s' "$out" | grep -q "\"$DENY\": \"deny\""; then
  ok "exit-1 enforcer → permissionDecision=deny, hook exits 0"
else
  bad "exit-1 enforcer should produce deny JSON with exit 0 (got code=$code out=$out)"
fi
if printf '%s' "$out" | grep -q "no plan exists"; then
  ok "deny reason carries the enforcer's ERROR_FOR_AGENT message"
else
  bad "deny reason should include the enforcer message"
fi

# 2) Enforcer that exits 0 → pass-through, no deny emitted.
cat > "$WORK/allow.sh" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$WORK/allow.sh"
out="$(printf '%s' "$EVENT" | bash "$GATE" "$WORK/allow.sh")"; code=$?
if [ "$code" -eq 0 ] && ! printf '%s' "$out" | grep -q "\"$DENY\": \"deny\""; then
  ok "exit-0 enforcer passes through without blocking"
else
  bad "exit-0 enforcer must not emit a deny (got out=$out)"
fi

# 3) Enforcer that natively emits permissionDecision JSON → forwarded verbatim, not double-wrapped.
cat > "$WORK/native.sh" <<EOF
#!/usr/bin/env bash
echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","$DENY":"deny","${DENY}Reason":"native"}}'
exit 0
EOF
chmod +x "$WORK/native.sh"
out="$(printf '%s' "$EVENT" | bash "$GATE" "$WORK/native.sh")"; code=$?
count="$(printf '%s' "$out" | grep -c "hookSpecificOutput" || true)"
if [ "$code" -eq 0 ] && [ "$count" = "1" ] && printf '%s' "$out" | grep -q '"native"'; then
  ok "native permissionDecision JSON forwarded verbatim (single envelope)"
else
  bad "native deny should pass through once (got count=$count out=$out)"
fi

# 4) Missing enforcer → fail OPEN (exit 0, no deny) so a broken gate never bricks work.
out="$(printf '%s' "$EVENT" | bash "$GATE" "$WORK/does-not-exist.sh" 2>/dev/null)"; code=$?
if [ "$code" -eq 0 ] && ! printf '%s' "$out" | grep -q "\"$DENY\": \"deny\""; then
  ok "missing enforcer fails open (allow), does not block"
else
  bad "missing enforcer must fail open (got code=$code out=$out)"
fi

echo
echo "hook-gate: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
