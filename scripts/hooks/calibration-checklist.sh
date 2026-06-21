#!/usr/bin/env bash
# calibration-checklist.sh — Stop hook
# יורה רק כשכלי כלשהו רץ בתור (flag מוגדר ע"י PreToolUse hook).
# הפלט נכנס לClaude כ-hookSpecificOutput ומשמש למילוי סעיף "🔍 ביקורת עצמית".

FLAG="${1:-/tmp/claude-tools-ran-$PPID}"
[ -f "$FLAG" ] || exit 0
rm -f "$FLAG"

printf '%s' '{"hookSpecificOutput":{"hookEventName":"Stop","additionalContext":"🔍 רשימת-כיול לביקורת עצמית — מלא את הסעיף '\''🔍 ביקורת עצמית (כיול)'\'' בתשובתך:\n\nL2 MANDATORY — בדוק אם הטריגר התקיים ואם הפעלת:\n  □ graphify — האם השתמשת לפני קריאת קבצי-קוד? (טריגר: כל חקירת קוד)\n  □ security-review — האם diff > 50 שורות קוד? האם רץ? (טריגר: כל שינוי קוד)\n  □ superpowers:brainstorm — האם היה feature חדש / בעיה עמומה? (טריגר: לפני כתיבה)\n  □ superpowers:verify — האם בדקת לפני הכרזת סיום? (טריגר: לפני כל '\''סיימתי'\'')\n  □ Context7 — האם הרצת npm/pip/install? האם בדקת docs? (טריגר: התקנת ספרייה)\n  □ nemotron — האם generation > 50 שורות ולא השתמשת? (טריגר: כש-Nemotron_api_key קיים)\n\nנהלים מרכזיים — בדוק ציות:\n  □ האם היה plan file לפני כתיבת קוד?\n  □ האם קראת קובץ-core רלוונטי לפני ביצוע (ולא מזיכרון)?\n  □ האם דיווחת על סקיל L2 חסר (במקום לדלג בשקט)?\n  □ האם ביצעת פעולה הרסנית/ל-shared-state ללא אישור מפורש?"}}'
