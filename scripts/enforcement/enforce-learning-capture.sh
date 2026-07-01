#!/usr/bin/env bash
set -euo pipefail

# enforce-learning-capture.sh — deterministic capture gate for core/learning-loop.md
#
# Bug/debug/incident/rollback implementation work must stage a complete lesson.
# Failed-solutions are additional evidence, not a substitute for the bug lesson.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/evidence.sh" 2>/dev/null || true
if ! declare -f bypass_active >/dev/null 2>&1; then
  bypass_active() {
    local name="${1:-}"; [ -z "$name" ] && return 1
    case "${!name:-}" in 1|true|TRUE|yes|YES) return 0 ;; *) return 1 ;; esac
  }
fi

bypass_active EOS_BYPASS_LEARNING && exit 0
bypass_active EOS_BYPASS_LEARNING_CAPTURE && exit 0

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

staged="$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)"
[ -n "$staged" ] || exit 0

code_staged="$(printf '%s\n' "$staged" | grep -E '\.(ts|tsx|js|jsx|py|go|rs|java|kt|rb|cs|cpp|c|h|php|scala|lua|sh|bash|zsh)$' || true)"
[ -n "$code_staged" ] || exit 0

field_value() {
  local plan_file="$1" field_re="$2"
  awk -F'|' -v re="$field_re" '
    NF > 1 {
      for (i = 1; i < NF; i++) {
        field = tolower($i); gsub(/[*_`]/, "", field); gsub(/^[ \t]+|[ \t]+$/, "", field)
        if (field ~ re) { value = $(i + 1); gsub(/^[ \t]+|[ \t]+$/, "", value); print value; exit }
      }
    }
  ' "$plan_file" 2>/dev/null || true
}

has_heading() {
  local file="$1" heading_re="$2"
  grep -qiE "^#{1,4}[[:space:]]+${heading_re}([[:space:]:]|$)" "$file" 2>/dev/null
}

staged_blob_has_heading() {
  local path="$1" heading="$2"
  git show ":$path" 2>/dev/null | grep -qiE "^#{1,4}[[:space:]]+${heading}([[:space:]:]|$)"
}

complete_staged_lesson() {
  local path="$1" missing=""
  for heading in \
    'מה קרה' \
    'שורש הבעיה' \
    'השערות שנבדקו' \
    'ראיה' \
    'רמת ביטחון' \
    'איך מזהים מוקדם' \
    'איך מונעים בעתיד' \
    'טסט רגרסיה' \
    'סטטוס הבשלה' \
    'Prevented Future Issues'; do
    staged_blob_has_heading "$path" "$heading" || missing="${missing}${heading}; "
  done
  if ! staged_blob_has_heading "$path" 'Prevention[[:space:]/-]+Enforcement[[:space:]]+Update' \
     && ! staged_blob_has_heading "$path" 'Prevention[[:space:]/-]+Enforcement[[:space:]]+Waiver' \
     && ! staged_blob_has_heading "$path" 'עדכון[[:space:]/-]+מניעה[[:space:]/-]+אכיפה' \
     && ! staged_blob_has_heading "$path" 'ויתור[[:space:]/-]+מניעה[[:space:]/-]+אכיפה'; then
    missing="${missing}Prevention/Enforcement Update or Waiver; "
  fi
  [ -z "$missing" ] || { echo "learning capture failed: staged lesson '$path' is incomplete: ${missing}" >&2; return 1; }

  python3 - "$path" <<'PY'
import re, subprocess, sys

path = sys.argv[1]
try:
    text = subprocess.check_output(['git', 'show', f':{path}'], text=True, stderr=subprocess.DEVNULL)
except Exception:
    try:
        text = open(path, encoding='utf-8').read()
    except FileNotFoundError:
        text = ''

placeholder = re.compile(r'\b(todo|tbd|placeholder|unknown|n/?a|none|later|fix later|not sure|unclear)\b', re.I)

headings = []
for match in re.finditer(r'(?m)^#{1,4}\s+(.+?)\s*$', text):
    headings.append({'title': match.group(1).strip(), 'start': match.end(), 'end': len(text)})
for idx in range(len(headings) - 1):
    headings[idx]['end'] = headings[idx + 1]['start']

def section(patterns):
    for item in headings:
        if any(re.search(pattern, item['title'], re.I) for pattern in patterns):
            return text[item['start']:item['end']].strip()
    return ''

def visible(value):
    lines = []
    for line in value.splitlines():
        stripped = re.sub(r'^[\s>*`_\-#]+', '', line).strip()
        if stripped:
            lines.append(stripped)
    return ' '.join(lines).strip()

def fail(message):
    print(message, file=sys.stderr)
    sys.exit(1)

def require_content(label, patterns, min_chars, cue_re):
    value = visible(section(patterns))
    if len(value) < min_chars or placeholder.search(value):
        fail(f"learning capture failed: staged lesson '{path}' has weak or placeholder content for {label}.")
    if cue_re and not re.search(cue_re, value, re.I):
        fail(f"learning capture failed: staged lesson '{path}' {label} must include concrete evidence words.")

require_content('root cause', [r'שורש הבעיה'], 30, r'root cause|caused|because|verified|reproduced|regression|mutation|race|state|dependency|mismatch|missing|גרם|גורם|סיבה|נבע|אומת|שוחזר')
require_content('evidence', [r'ראיה'], 30, r'test|tests|log|logs|trace|ci|fail|failed|pass|passed|repro|fixture|assert|command|בדיקה|לוג|נכשל|עבר|שוחזר')
require_content('regression test', [r'טסט רגרסיה'], 10, r'test|pytest|npm|bash|script|ci|workflow|spec|fixture|\.sh|\.py|\.ts|בדיקה|סקריפט')
require_content('prevention', [r'איך מונעים בעתיד'], 30, r'prevent|enforce|guard|gate|check|test|ci|monitor|alert|block|מנע|אכיפ|בדיקה|חסם|התראה')

update = section([r'Prevention[\s/-]+Enforcement[\s]+Update', r'עדכון[\s/-]+מניעה[\s/-]+אכיפה'])
waiver = section([r'Prevention[\s/-]+Enforcement[\s]+Waiver', r'ויתור[\s/-]+מניעה[\s/-]+אכיפה'])
if update:
    value = visible(update)
    if len(value) < 30 or placeholder.search(value) or not re.search(r'added|kept|updated|created|blocked|implemented|enforce|gate|guard|test|ci|check|הוספ|עדכנ|אכיפ|חסם|בדיקה', value, re.I):
        fail(f"learning capture failed: staged lesson '{path}' Prevention/Enforcement Update must describe a concrete prevention change.")
elif waiver:
    value = visible(waiver)
    if len(value) < 30 or placeholder.search(value) or not re.search(r'because|reason|out of scope|not applicable|low risk|manual|סיבה|כי|לא רלוונטי|מחוץ להיקף', value, re.I):
        fail(f"learning capture failed: staged lesson '{path}' Prevention/Enforcement Waiver must explain the reason.")
else:
    fail(f"learning capture failed: staged lesson '{path}' needs Prevention/Enforcement Update or Waiver content.")
PY
}

select_plan() {
  if [ -n "${EOS_ACTIVE_PLAN:-}" ] && [ -f "${EOS_ACTIVE_PLAN:-}" ]; then printf '%s\n' "$EOS_ACTIVE_PLAN"; return 0; fi
  if [ -f .claude/plans/active.md ]; then printf '%s\n' .claude/plans/active.md; return 0; fi
  local candidate
  for candidate in $(ls -t .claude/plans/*.md 2>/dev/null || true); do
    case "$(basename "$candidate")" in README.md|_TEMPLATE.md) continue ;; esac
    printf '%s\n' "$candidate"; return 0
  done
}

plan="$(select_plan || true)"
[ -n "$plan" ] || exit 0

requires_full_lesson() {
  local plan_file="$1" task tags combined
  task="$(field_value "$plan_file" '^task class$|^task-class$|^type$')"
  tags="$(field_value "$plan_file" '^domain tags$|^domains$|^tags$')"
  combined="$(printf '%s %s' "$task" "$tags" | tr '[:upper:]' '[:lower:]')"
  printf '%s' "$combined" | grep -qE 'bug|debug|incident|rollback|hotfix|regression|production[ -_]*(failure|bug|incident)|post[ -_]*mortem'
}

requires_full_lesson "$plan" || exit 0

lesson_staged="$(printf '%s\n' "$staged" | grep -E '^lessons-learned/bugs/[^/]+\.md$' | grep -vE '/(README|_TEMPLATE)\.md$' || true)"
if [ -n "$lesson_staged" ]; then
  while IFS= read -r lesson; do
    [ -n "$lesson" ] || continue
    complete_staged_lesson "$lesson" || exit 1
  done <<EOF_LESSONS
$lesson_staged
EOF_LESSONS
  exit 0
fi

failed_staged="$(printf '%s\n' "$staged" | grep -E '^failed-solutions/[^/]+\.md$' | grep -vE '/(README|_TEMPLATE)\.md$' || true)"

if has_heading "$plan" 'Learning[[:space:]]+Capture[[:space:]]+Waiver'; then
  echo "learning capture failed: waiver cannot replace a bug/debug/incident lesson." >&2
  echo "active plan: $plan" >&2
  echo "action: stage lessons-learned/bugs/<lesson>.md with the full required schema." >&2
  exit 1
fi

if [ -n "$failed_staged" ]; then
  echo "learning capture failed: failed-solution staged but no bug lesson staged." >&2
  echo "active plan: $plan" >&2
  echo "action: also stage lessons-learned/bugs/<lesson>.md with root cause, evidence, prevention, regression test, and maturity status." >&2
  exit 1
fi

echo "learning capture failed: bug/debug/incident work requires a full lesson." >&2
echo "active plan: $plan" >&2
echo "action: stage lessons-learned/bugs/<lesson>.md with the required lesson schema." >&2
exit 1
