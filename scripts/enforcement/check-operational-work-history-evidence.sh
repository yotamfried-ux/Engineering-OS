#!/usr/bin/env bash
set -euo pipefail

# check-operational-work-history-evidence.sh — validates the Operational Work
# History artifact and its minimal PR-body pointer for system-affecting PRs.
#
# Source of truth is the CI-generated artifact
# (.engineering-os/work-history/latest.json), never the PR body prose. The PR
# body only carries a path pointer plus learning-loop routing fields — see
# docs/operations/operational-work-history.md.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BODY_FILE=""
HEAD_SHA=""
ARTIFACT="$ROOT/.engineering-os/work-history/latest.json"
CHANGED_FILES_FILE=""
CHANGED_FILES_PROVIDED=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --body) BODY_FILE="${2:-}"; shift 2 ;;
    --head-sha) HEAD_SHA="${2:-}"; shift 2 ;;
    --artifact) ARTIFACT="${2:-}"; shift 2 ;;
    --changed-files) CHANGED_FILES_FILE="${2:-}"; CHANGED_FILES_PROVIDED=1; shift 2 ;;
    --root) ROOT="${2:-}"; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

[ -n "$BODY_FILE" ] && [ -f "$BODY_FILE" ] || { echo "ERROR_FOR_AGENT: missing readable --body file." >&2; exit 2; }

CHANGED_FILES_EMPTY="$(mktemp)"
trap 'rm -f "$CHANGED_FILES_EMPTY"' EXIT
CHANGED_FILES_ARG="$CHANGED_FILES_EMPTY"
if [ "$CHANGED_FILES_PROVIDED" -eq 1 ]; then
  [ -n "$CHANGED_FILES_FILE" ] && [ -f "$CHANGED_FILES_FILE" ] || { echo "ERROR_FOR_AGENT: --changed-files was provided but is not readable." >&2; exit 2; }
  CHANGED_FILES_ARG="$CHANGED_FILES_FILE"
fi

python3 - "$BODY_FILE" "$HEAD_SHA" "$ARTIFACT" "$ROOT" "$CHANGED_FILES_ARG" "$CHANGED_FILES_PROVIDED" <<'PY'
import json
import re
import sys
from pathlib import Path

body_file, head_sha, artifact_path, root, changed_files_file, changed_files_provided = sys.argv[1:7]
changed_files_provided = changed_files_provided == "1"
body = Path(body_file).read_text(encoding="utf-8", errors="replace")
changed_files = [line.strip() for line in Path(changed_files_file).read_text(encoding="utf-8", errors="replace").splitlines() if line.strip()]
root_path = Path(root)
artifact = Path(artifact_path)

placeholder = re.compile(r"^\s*(todo|tbd|placeholder|unknown|n/?a|none|later|fix later|not sure|unclear)\W*$", re.I)
friction_signal_re = re.compile(
    r"\b(ci|failure|failing|retry|revert|waiver|unavailable|review|cycle|metadata)\b"
    r"|כשל|נכשל|נכשלה|נכשלו|בדיק|בדיקות|ריוויו|סקירה|מטאדאטה|מטא-דאטה|ויתור|מחזור|נסיון|ניסיון|חזרה",
    re.I,
)


def section(text: str, title: str) -> str:
    match = re.search(r"^##\s+" + re.escape(title) + r"\s*$", text, re.I | re.M)
    if not match:
        return ""
    rest = text[match.end():]
    nxt = re.search(r"^##\s+", rest, re.M)
    return rest[:nxt.start()] if nxt else rest


def field_value(text: str, field: str):
    match = re.search(r"(^|\n)\s*[-*]?\s*" + re.escape(field) + r"\s*:\s*(.+)", text, re.I)
    return match.group(2).strip() if match else None


def concrete(value) -> bool:
    if value is None:
        return False
    clean = value.strip()
    return len(clean) >= 12 and not placeholder.fullmatch(clean)


def sha_matches(expected: str, found: str) -> bool:
    if not expected or not found:
        return not expected
    e, f = expected.lower(), found.lower()
    return e.startswith(f) or f.startswith(e)


def fail(msg: str):
    print(f"ERROR_FOR_AGENT: {msg}")
    sys.exit(1)


# Backward compatibility for local script-level tests that call check-pr-review-evidence.sh
# without PR diff metadata: the Operational Work History gate is enforced only when the
# real PR workflow passes --changed-files. In CI that argument is mandatory and tested by
# test-pr-policy-workflow-wiring.sh.
if not changed_files_provided:
    print("changed-files metadata not provided — skipping Operational Work History evidence check outside PR workflow mode")
    sys.exit(0)

# 1. Changed-files evidence must be present and fail-closed in PR workflow mode.
if not changed_files:
    fail("changed-files metadata is empty in PR workflow mode; refusing to treat this as a no-op because it could hide a git diff failure.")

# 2. Artifact must never be part of the PR diff itself.
ARTIFACT_PATHS = {".engineering-os/work-history/latest.json", ".engineering-os/work-history/latest-summary.md"}
for changed in changed_files:
    normalized = changed.replace("\\", "/")
    if normalized in ARTIFACT_PATHS or normalized.startswith(".engineering-os/work-history/"):
        fail(f"PR diff must not include the generated artifact path {changed}; it is a build product, never committed.")

# 3. All PRs with changed files require evidence. There is no automatic single-file exemption
# until a future diff-aware classifier can prove a change is truly non-normative typo-only.
op_section = section(body, "Operational Work History Evidence")
if not op_section.strip():
    fail("PR body must include ## Operational Work History Evidence for any PR with changed files; no filename-only exemption is allowed.")

# 4. automatic_sources: must point at the artifact path, no manually copied counts required.
automatic_sources = field_value(op_section, "automatic_sources")
if not automatic_sources or ".engineering-os/work-history/latest.json" not in automatic_sources:
    fail("## Operational Work History Evidence automatic_sources: must reference .engineering-os/work-history/latest.json.")

# 5. Read the artifact directly — this is the actual source of truth.
if not artifact.is_file():
    fail(f"Operational Work History artifact not found at {artifact}; it must be generated by CI before this check runs.")

try:
    record = json.loads(artifact.read_text(encoding="utf-8"))
except Exception as exc:
    fail(f"Operational Work History artifact at {artifact} is not valid JSON: {exc}")

pr_head_sha = str(record.get("pr_head_sha") or "")
if head_sha and not sha_matches(head_sha, pr_head_sha):
    fail(f"artifact pr_head_sha ({pr_head_sha!r}) does not match the real PR head SHA ({head_sha!r}); the artifact may be stale or copy-pasted.")

changed_count = int(record.get("changed_files_count") or 0)
commits_count = int(record.get("commits_count") or 0)
empty_run = bool(record.get("empty_run"))
ci_unavailable = bool(record.get("ci_metadata_unavailable"))
review_unavailable = bool(record.get("review_metadata_unavailable"))

if changed_count != len(changed_files):
    fail(f"artifact changed_files_count ({changed_count}) does not match workflow changed-files metadata ({len(changed_files)}); artifact may be stale or generated from the wrong ref.")

if changed_count == 0 and commits_count == 0 and not empty_run and not ci_unavailable and not review_unavailable:
    fail("artifact has zero changed files, zero commits, and no unavailability/empty-run markers — looks like a dummy or placeholder artifact.")

# 6. Learning-loop routing — exactly one of learning_loop_artifact / learning_loop_result.
learning_artifact = field_value(op_section, "learning_loop_artifact")
learning_result = field_value(op_section, "learning_loop_result")

if learning_artifact and learning_result:
    fail("## Operational Work History Evidence must carry exactly one of learning_loop_artifact: or learning_loop_result:, not both.")
if not learning_artifact and not learning_result:
    fail("## Operational Work History Evidence must carry learning_loop_artifact: <path> or learning_loop_result: none-with-reason — <reason>.")

friction = record.get("friction_signals") or {}
friction_any = bool(friction.get("any"))

if learning_artifact:
    lesson_path = root_path / learning_artifact.strip()
    if not lesson_path.is_file():
        fail(f"learning_loop_artifact: {learning_artifact} does not exist.")
    rel = str(learning_artifact).replace("\\", "/")
    text = lesson_path.read_text(encoding="utf-8", errors="replace")
    if rel.startswith("lessons-learned/bugs/"):
        required_headings = ["מה קרה", "שורש הבעיה", "ראיה", "רמת ביטחון", "איך מונעים בעתיד", "טסט רגרסיה", "סטטוס הבשלה", "Prevented Future Issues"]
        missing = [h for h in required_headings if not re.search(r"^#{1,4}\s+" + re.escape(h), text, re.I | re.M)]
        if missing:
            fail(f"learning_loop_artifact: {learning_artifact} is missing required lesson headings: {', '.join(missing)}.")
    elif rel.startswith("failed-solutions/"):
        required_headings = ["מה ניסיתי", "למה לא עבד", "מה לבדוק במקום"]
        missing = [h for h in required_headings if not re.search(r"^#{1,4}\s+" + re.escape(h), text, re.I | re.M)]
        if missing:
            fail(f"learning_loop_artifact: {learning_artifact} is missing required failed-solution headings: {', '.join(missing)}.")
    elif rel.startswith("lessons-learned/postmortems/"):
        if len(text.strip()) < 40:
            fail(f"learning_loop_artifact: {learning_artifact} is too short to be a real postmortem.")
    else:
        fail(f"learning_loop_artifact: {learning_artifact} must be under lessons-learned/ or failed-solutions/.")
else:
    match = re.match(r"none-with-reason\s*[-—:]\s*(.+)$", learning_result.strip(), re.I)
    reason = match.group(1).strip() if match else ""
    if not match or not concrete(reason):
        fail("learning_loop_result: must be 'none-with-reason — <concrete reason>' with a non-placeholder reason.")
    if friction_any and not friction_signal_re.search(reason):
        fail("artifact shows friction signals (failures/retries/unavailable metadata/waiver); learning_loop_result reason must concretely address the observed signal, not generic prose.")

# 7. Result-loop contract selection (per-PR declaration dimension of
# gap:result-loop-contract-enforcement). Source of truth is the artifact's
# own result_loop_contract object, computed by collect-pr-work-history.py —
# this never re-parses the PR body for this field, so a hand-edited or stale
# PR-body claim cannot override what the freshly regenerated artifact says.
def concrete_id(value: str) -> bool:
    # Real project_type_id values (e.g. "cli-tool", "ai-agent") can be shorter
    # than the 12-char prose threshold `concrete()` uses, so ids get their own,
    # shorter, still placeholder-rejecting check.
    clean = value.strip()
    return len(clean) >= 2 and not placeholder.fullmatch(clean)


rlc = record.get("result_loop_contract")
if not isinstance(rlc, dict):
    fail("Operational Work History artifact is missing result_loop_contract; regenerate via collect-pr-work-history.py (stale or pre-upgrade artifact).")

if rlc.get("required"):
    if rlc.get("validation_status") != "valid":
        fail(rlc.get("reason") or "selected_result_loop_contract is required but not validly resolved.")
    if not concrete_id(str(rlc.get("selected_result_loop_contract") or "")):
        fail("result_loop_contract.selected_result_loop_contract must be a concrete, non-placeholder id when required.")
else:
    if not concrete(str(rlc.get("reason") or "")):
        fail("result_loop_contract.reason must be a concrete, non-placeholder explanation when required is false.")

print("operational work history evidence passed")
PY