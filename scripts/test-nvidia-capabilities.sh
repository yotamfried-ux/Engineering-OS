#!/usr/bin/env bash
# test-nvidia-capabilities.sh — Nemotron API smoke test
# Runs from session-setup.sh when Nemotron_api_key is set.
# Non-fatal: Nemotron is L1 optional. Warn loudly on failure, never exit 1.
# Governing policy: core/resource-management.md <nemotron-routing>

G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; Z=$'\033[0m'

[ -z "${Nemotron_api_key:-}" ] && exit 0  # Not configured — skip silently

BASE_URL="https://integrate.api.nvidia.com/v1"
MODEL="nvidia/llama-3.1-nemotron-ultra-253b-v1"

RESPONSE=$(python3 -c "
import urllib.request, json, sys

url = '${BASE_URL}/chat/completions'
headers = {
    'Authorization': 'Bearer ${Nemotron_api_key}',
    'Content-Type': 'application/json'
}
body = json.dumps({
    'model': '${MODEL}',
    'messages': [{'role': 'user', 'content': 'Reply with exactly: OK'}],
    'max_tokens': 10
}).encode()

try:
    req = urllib.request.Request(url, data=body, headers=headers)
    with urllib.request.urlopen(req, timeout=15) as resp:
        data = json.loads(resp.read())
        content = data['choices'][0]['message']['content']
        print('OK' if 'OK' in content else 'UNEXPECTED:' + content)
except Exception as e:
    print('ERROR:' + str(e))
" 2>/dev/null)

if echo "$RESPONSE" | grep -q "^OK"; then
  printf '%s✅%s Nemotron smoke test passed — API responsive\n' "$G" "$Z"
elif echo "$RESPONSE" | grep -q "^ERROR"; then
  printf '\n%s🔴 NEMOTRON UNAVAILABLE%s: %s\n' "$R" "$Z" "${RESPONSE#ERROR:}"
  printf '   nemotron-coder / nemotron-code-reviewer tools will FAIL SILENTLY.\n'
  printf '   Fix: verify Nemotron_api_key is valid + integrate.api.nvidia.com is reachable.\n'
  printf '   Nemotron is L1 optional — session continues without it.\n\n'
else
  printf '%s⚠️%s  Nemotron unexpected response: %s\n' "$Y" "$Z" "$RESPONSE"
  printf '   Nemotron is L1 optional — session continues.\n'
fi
