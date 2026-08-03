#!/usr/bin/env bash
# Verify that every settings surface derives from one canonical required-hook manifest.
#
# The failure this guards against is silent: a hook wired on one install path and absent
# on another makes an unrecorded event look like an action the model never took. Each
# case below is one way the four surfaces can drift apart.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SETTINGS="$ROOT/.claude/settings.json"
REGISTRY="$ROOT/scripts/enforcement/hook-criticality.tsv"
PATCHER="$ROOT/scripts/monitoring/patch-settings-telemetry.py"
CONTRACT="$ROOT/scripts/enforcement/check-hard-hook-contract.py"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

pass=0
fail=0
ok() { printf '  ✅ %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf '  ❌ %s\n' "$1"; fail=$((fail + 1)); }

# Build a fresh, correct target settings file for a named case.
fixture() {
  local name="$1"
  local dir="$WORK/$name"
  mkdir -p "$dir"
  python3 "$PATCHER" "$dir/settings.json" --mode direct --home "$ROOT" --no-backup >/dev/null
  printf '%s' "$dir/settings.json"
}

# Assert --verify rejects the mutated fixture with the expected reason.
expect_reject() {
  local name="$1" needle="$2" settings="$3"
  if python3 "$PATCHER" "$settings" --mode direct --home "$ROOT" --verify >"$WORK/$name.out" 2>"$WORK/$name.err"; then
    bad "$name: --verify accepted a drifted surface"
    return
  fi
  if grep -q "$needle" "$WORK/$name.err"; then
    ok "$name"
  else
    bad "$name: wrong failure reason: $(head -1 "$WORK/$name.err")"
  fi
}

mutate() {
  python3 - "$1" "$2" <<'PY'
import json, sys
from pathlib import Path
path, mode = Path(sys.argv[1]), sys.argv[2]
data = json.loads(path.read_text())
hooks = data["hooks"]


def entries(event):
    return [hook for block in hooks[event] for hook in block.get("hooks", [])]


def drop(event, needle):
    """Remove one owned hook, leaving the block and any unowned siblings in place.

    This is what real drift looks like: an installer writes a partial set rather than
    deleting a whole event.
    """
    removed = 0
    for block in hooks[event]:
        keep = [h for h in block.get("hooks", []) if needle not in h.get("command", "")]
        removed += len(block.get("hooks", [])) - len(keep)
        block["hooks"] = keep
    assert removed == 1, (event, needle, removed)


if mode == "missing":
    drop("PostToolUse", "eos-telemetry-event.sh")
elif mode == "missing_boundary":
    # Drop only the terminal boundary; the Stop enforcement hook stays wired.
    drop("Stop", "record-and-sync-telemetry.sh")
elif mode == "mismatched":
    # Point a recorder at the wrong unit.
    for hook in entries("PostToolUse"):
        hook["command"] = hook["command"].replace(
            "eos-telemetry-event.sh", "record-and-sync-telemetry.sh"
        )
elif mode == "duplicate":
    hooks["PostToolUse"][0]["hooks"].append(dict(entries("PostToolUse")[0]))
elif mode == "legacy":
    # An obsolete pre-gate command left behind by an older installer.
    hooks.setdefault("PostToolUse", []).append({
        "matcher": "Read",
        "hooks": [{
            "type": "command",
            "command": 'bash "/opt/eos/scripts/monitoring/eos-telemetry-event.sh" post_tool_use',
        }],
    })
elif mode == "criticality":
    # The hard session guard wired without the hard gate: fails open instead of closed.
    for hook in entries("PreToolUse"):
        if "require-telemetry-session.sh" in hook["command"]:
            hook["command"] = 'bash "/opt/eos/scripts/monitoring/require-telemetry-session.sh"'
else:
    raise SystemExit(f"unknown mutation: {mode}")

path.write_text(json.dumps(data, indent=2))
PY
}

# 1. The checked-in Engineering OS surface is exactly what the registry derives.
if python3 "$PATCHER" "$SETTINGS" --mode direct --verify >/dev/null 2>&1; then
  ok "checked-in settings match the canonical manifest"
else
  bad "checked-in settings drifted from the canonical manifest"
fi

# 2. A generated target derives the identical required set, terminal boundary included.
TARGET="$(fixture generated)"
if python3 "$PATCHER" "$TARGET" --mode direct --home "$ROOT" --verify >/dev/null 2>&1 \
   && grep -q 'record-and-sync-telemetry.sh' "$TARGET"; then
  ok "generated target settings match the canonical manifest"
else
  bad "generated target settings drifted from the canonical manifest"
fi

# 3. Source and generated surfaces agree on every event/matcher pair and criticality.
if python3 - "$SETTINGS" "$TARGET" <<'PY'
import json, re, sys

source, target = sys.argv[1], sys.argv[2]


def owned(path):
    data = json.loads(open(path).read())
    found = {}
    for event, blocks in data.get("hooks", {}).items():
        for block in blocks:
            for hook in block.get("hooks", []):
                command = hook.get("command", "")
                if "scripts/monitoring/" not in command:
                    continue
                unit = re.search(r"scripts/monitoring/[A-Za-z0-9_.-]+", command).group(0)
                argument = re.search(r" -- ([a-z_]+)", command)
                gate = "hard" if "/lib/hook-gate.sh" in command else "soft"
                found[(event, str(block.get("matcher")))] = (
                    unit, argument.group(1) if argument else None, gate
                )
    return found


a, b = owned(source), owned(target)
assert a == b, sorted(set(a.items()) ^ set(b.items()))
assert a, "no owned hooks found"
PY
then
  ok "source and generated surfaces agree on unit, argument, and criticality"
else
  bad "source and generated surfaces disagree"
fi

# 4-9. Each drift class must be rejected, not tolerated.
for case in missing missing_boundary mismatched duplicate legacy criticality; do
  settings="$(fixture "$case")"
  mutate "$settings" "$case"
  case "$case" in
    missing|missing_boundary) needle="missing required hook" ;;
    mismatched|criticality) needle="mismatched required hook" ;;
    duplicate) needle="duplicate required hook" ;;
    legacy) needle="unregistered or legacy owned hook" ;;
  esac
  expect_reject "rejects_${case}" "$needle" "$settings"
done

# 10. A missing terminal boundary is also caught on the source surface by the contract,
#     which is the check that stayed silent while this drift existed.
BOUNDARY_ROOT="$WORK/contract"
mkdir -p "$BOUNDARY_ROOT"
cp -r "$ROOT/scripts" "$BOUNDARY_ROOT/scripts"
mkdir -p "$BOUNDARY_ROOT/.claude"
cp "$SETTINGS" "$BOUNDARY_ROOT/.claude/settings.json"
mutate "$BOUNDARY_ROOT/.claude/settings.json" missing_boundary
if python3 "$CONTRACT" --root "$BOUNDARY_ROOT" --surface source >/dev/null 2>"$WORK/contract.err"; then
  bad "hard-hook contract accepted a missing terminal boundary"
elif grep -q 'registered lifecycle unit is not wired' "$WORK/contract.err"; then
  ok "hard-hook contract rejects a missing terminal boundary"
else
  bad "hard-hook contract failed for the wrong reason: $(head -1 "$WORK/contract.err")"
fi

# 11. Without the canonical registry the patcher must refuse, never wire a partial set.
NOREG="$WORK/no-registry"
mkdir -p "$NOREG/scripts/monitoring" "$NOREG/scripts/enforcement"
cp "$PATCHER" "$NOREG/scripts/monitoring/"
if python3 "$NOREG/scripts/monitoring/patch-settings-telemetry.py" \
     "$NOREG/settings.json" --mode direct --no-backup >/dev/null 2>"$WORK/noreg.err"; then
  bad "patcher wired hooks with no canonical registry present"
elif grep -q 'required hook registry is missing' "$WORK/noreg.err"; then
  ok "patcher fails closed when the canonical registry is absent"
else
  bad "patcher failed for the wrong reason: $(head -1 "$WORK/noreg.err")"
fi

# 12. Every telemetry unit the registry declares is actually reachable on disk.
if python3 - "$REGISTRY" "$ROOT" <<'PY'
import sys
from pathlib import Path

registry, root = Path(sys.argv[1]), Path(sys.argv[2])
missing = []
for raw in registry.read_text().splitlines():
    if not raw.strip() or raw.startswith("#"):
        continue
    parts = raw.split("\t")
    if len(parts) == 10 and parts[2].startswith("scripts/monitoring/"):
        if not (root / parts[2]).is_file():
            missing.append(parts[2])
assert not missing, missing
PY
then
  ok "every registered telemetry unit exists"
else
  bad "registry names a telemetry unit that does not exist"
fi

printf '\nhook boundary parity: %d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
