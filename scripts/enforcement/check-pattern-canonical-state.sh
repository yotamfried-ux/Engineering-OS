#!/usr/bin/env bash
# check-pattern-canonical-state.sh — patterns/registry.yaml is the single canonical
# owner of pattern lifecycle state (status, score, used_in, evidence).
#
# Background: lifecycle state used to be declared independently in
# patterns/registry.yaml, docs/operations/template-pattern-ratings.tsv, and the
# domain README files, with no cross-validation. Any of them could contradict the
# executable registry (gap: pattern-registry-canonical-drift).
#
# This gate fails closed on six distinct classes:
#   conflicting status      — a competing surface declares a different status
#   conflicting score       — a competing surface declares a different score
#   conflicting usage       — a competing surface declares a different use count
#   conflicting evidence    — a competing surface cites evidence the registry lacks
#   unknown row             — a competing surface declares state for an unknown id
#   active-below-threshold  — the registry declares active without meeting the
#                             canonical promotion thresholds
#
# Canonical promotion thresholds come from core/scoring-guide.md: a pattern may be
# `active` only with score >= 60 and used_in >= 2, backed by non-empty evidence.
#
# Competing-surface mapping: a `pattern`-typed row in the ratings TSV maps to a
# registry record by stripping a leading `pattern-` from its asset_id. Domain
# READMEs must not declare lifecycle state at all; they are implementation guidance.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REGISTRY="$ROOT/patterns/registry.yaml"
RATINGS="$ROOT/docs/operations/template-pattern-ratings.tsv"
PATTERNS_DIR="$ROOT/patterns"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --registry) REGISTRY="${2:-}"; shift 2 ;;
    --ratings) RATINGS="${2:-}"; shift 2 ;;
    --patterns-dir) PATTERNS_DIR="${2:-}"; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

[ -f "$REGISTRY" ] || { echo "pattern canonical state failed: missing registry $REGISTRY" >&2; exit 2; }
[ -f "$RATINGS" ] || { echo "pattern canonical state failed: missing ratings $RATINGS" >&2; exit 2; }

python3 - "$REGISTRY" "$RATINGS" "$PATTERNS_DIR" <<'PY'
import pathlib, re, sys

registry_path = pathlib.Path(sys.argv[1])
ratings_path = pathlib.Path(sys.argv[2])
patterns_dir = pathlib.Path(sys.argv[3])

ALLOWED_STATUS = {"candidate", "active", "deprecated", "retired"}
MIN_ACTIVE_SCORE = 60
MIN_ACTIVE_USES = 2

errors = []


def scalar(raw):
    """Normalize a YAML scalar to None or a stripped, unquoted string."""
    raw = raw.strip()
    if raw in ("null", "~", ""):
        return None
    if len(raw) >= 2 and raw[0] == raw[-1] and raw[0] in "\"'":
        return raw[1:-1]
    return raw


def as_int(value):
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


# ── parse the canonical registry ────────────────────────────────────────────────
records = {}
order = []
current = None
in_evidence = False

for lineno, line in enumerate(registry_path.read_text().splitlines(), 1):
    stripped = line.strip()
    if not stripped or stripped.startswith("#"):
        continue

    m = re.match(r"^\s{2}-\s+id:\s*(.+)$", line)
    if m:
        pid = scalar(m.group(1))
        current = {"id": pid, "line": lineno, "evidence": [], "domain": None,
                   "status": None, "score": None, "used_in": None}
        in_evidence = False
        if pid in records:
            errors.append(f"duplicate registry id: {pid} (line {lineno})")
        else:
            records[pid] = current
            order.append(pid)
        continue

    if current is None:
        continue

    # Collect list items belonging to an open evidence block.
    if in_evidence:
        m = re.match(r"^\s{6}-\s+(.*)$", line)
        if m:
            value = scalar(m.group(1))
            if value:
                current["evidence"].append(value)
            continue
        in_evidence = False

    m = re.match(r"^\s{4}([a-z_]+):\s*(.*)$", line)
    if not m:
        continue
    key, raw = m.group(1), m.group(2)

    if key == "evidence":
        value = raw.strip()
        if value in ("[]", "null", "~"):
            current["evidence"] = []
        elif value == "":
            current["evidence"] = []
            in_evidence = True
        elif value.startswith("[") and value.endswith("]"):
            inner = value[1:-1].strip()
            current["evidence"] = [scalar(p) for p in inner.split(",") if p.strip()] if inner else []
        else:
            current["evidence"] = [scalar(value)]
        continue

    if key in ("domain", "status", "score", "used_in"):
        current[key] = scalar(raw)

if not records:
    print("pattern canonical state failed: registry declares no pattern records", file=sys.stderr)
    sys.exit(2)


# ── registry internal lifecycle consistency ─────────────────────────────────────
for pid in order:
    rec = records[pid]
    status = rec["status"]
    score = as_int(rec["score"])
    used_in = as_int(rec["used_in"])

    if not rec["domain"]:
        errors.append(f"{pid}: missing domain")
    if status not in ALLOWED_STATUS:
        errors.append(f"{pid}: invalid status {status!r}")
    if rec["score"] is not None and score is None:
        errors.append(f"{pid}: score must be null or an integer, got {rec['score']!r}")
    elif score is not None and not (0 <= score <= 100):
        errors.append(f"{pid}: score {score} outside the canonical 0-100 range")
    if used_in is None or used_in < 0:
        errors.append(f"{pid}: used_in must be a non-negative integer, got {rec['used_in']!r}")

    if status == "active":
        reasons = []
        if score is None:
            reasons.append("score is unset")
        elif score < MIN_ACTIVE_SCORE:
            reasons.append(f"score {score} < {MIN_ACTIVE_SCORE}")
        if used_in is None or used_in < MIN_ACTIVE_USES:
            reasons.append(f"used_in {rec['used_in']} < {MIN_ACTIVE_USES}")
        if not rec["evidence"]:
            reasons.append("evidence is empty")
        if reasons:
            errors.append(
                f"active-below-threshold: {pid} is active but " + ", ".join(reasons)
                + " (core/scoring-guide.md requires score >= 60, used_in >= 2, non-empty evidence)"
            )


# ── competing surface: pattern-typed rows in the ratings TSV ────────────────────
SCORE_SCALE_NOTE = "ratings score is a 1-5 scale; the canonical registry score is 0-100"

for lineno, line in enumerate(ratings_path.read_text().splitlines(), 1):
    if not line.strip() or line.startswith("#"):
        continue
    parts = line.split("\t")
    if len(parts) != 14:
        continue  # row shape is owned by check-template-pattern-ratings.sh
    asset, typ, _path, status, score, _conf, used = parts[:7]
    evidence = parts[12]
    if typ != "pattern":
        continue

    pid = asset[len("pattern-"):] if asset.startswith("pattern-") else asset
    rec = records.get(pid)
    if rec is None:
        errors.append(
            f"unknown row: ratings line {lineno} declares pattern state for {asset!r}, "
            f"which maps to no record in {registry_path.name}"
        )
        continue

    if status != rec["status"]:
        errors.append(
            f"conflicting status: ratings line {lineno} declares {status!r} for {pid} "
            f"but the registry declares {rec['status']!r}"
        )

    reg_score = as_int(rec["score"])
    row_score = as_int(score)
    if reg_score is None:
        if row_score is not None:
            errors.append(
                f"conflicting score: ratings line {lineno} declares score {score!r} for {pid} "
                f"but the registry leaves it unscored ({SCORE_SCALE_NOTE})"
            )
    elif row_score is None or row_score * 20 != reg_score:
        errors.append(
            f"conflicting score: ratings line {lineno} declares score {score!r} for {pid} "
            f"but the registry declares {reg_score} ({SCORE_SCALE_NOTE})"
        )

    if as_int(used) != as_int(rec["used_in"]):
        errors.append(
            f"conflicting usage: ratings line {lineno} declares used_count {used!r} for {pid} "
            f"but the registry declares used_in {rec['used_in']!r}"
        )

    if evidence and evidence not in set(rec["evidence"]):
        errors.append(
            f"conflicting evidence: ratings line {lineno} cites {evidence!r} for {pid}, "
            f"which is absent from the registry evidence for that record"
        )


# ── competing surface: lifecycle state embedded in domain READMEs ───────────────
STATE_LINE = re.compile(r"^\s*\*\*(Score|Status|Lifecycle state|Used in)\s*:\*\*", re.IGNORECASE)

if patterns_dir.is_dir():
    for readme in sorted(patterns_dir.glob("*/README.md")):
        for lineno, line in enumerate(readme.read_text().splitlines(), 1):
            if STATE_LINE.match(line):
                rel = readme.relative_to(patterns_dir.parent)
                errors.append(
                    f"conflicting status: {rel}:{lineno} declares pattern lifecycle state "
                    f"({line.strip()[:60]!r}); domain READMEs are implementation guidance and "
                    f"must defer to patterns/registry.yaml"
                )

if errors:
    for err in errors:
        print(f"pattern canonical state failed: {err}", file=sys.stderr)
    sys.exit(1)

active = sum(1 for pid in order if records[pid]["status"] == "active")
print(
    f"pattern canonical state checks passed ({len(order)} registry records, "
    f"{active} active, single owner {registry_path.name})"
)
PY
