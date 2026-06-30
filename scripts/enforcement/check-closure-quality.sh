#!/usr/bin/env bash
set -euo pipefail
file="${1:-}"
[ -n "$file" ] || exit 1
blob(){ git show ":$1" 2>/dev/null || true; }
sec(){ local f="$1" h="$2"; blob "$f" | awk -v re="^#{1,4}[[:space:]]+${h}([[:space:]:/-]|$)" '$0~re{on=1;next} on&&$0~/^#{1,4}[[:space:]]+/{exit} on{print}'; }
wc3(){ tr -cs '[:alnum:]_./-' '\n' | grep -E '.{3,}' | wc -l | tr -d ' '; }
need_text(){ local h="$1" min="$2" label="$3" txt n; txt="$(sec "$file" "$h")"; printf '%s\n' "$txt" | grep -qiE '\b(todo|tbd|placeholder|unknown|fix later|not sure|unclear)\b' && { echo "closure check failed: $label placeholder" >&2; exit 1; }; n="$(printf '%s\n' "$txt" | wc3)"; [ "${n:-0}" -ge "$min" ] || { echo "closure check failed: $label short" >&2; exit 1; }; }
need_text 'שורש הבעיה' 6 cause
need_text 'ראיה' 6 evidence
need_text 'איך מזהים מוקדם' 6 detection
need_text 'איך מונעים בעתיד' 8 prevention
echo ok
