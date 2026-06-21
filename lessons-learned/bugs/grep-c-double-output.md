# `grep -c ... || echo 0` מייצר פלט דו-שורתי ושובר בדיקות שלמים

> באג בשכבת האכיפה: שגיאת `integer expression expected` ב-hooks שאוכפים את כללי ה-md.

## מה קרה
בפלט ה-SessionStart הופיעה השגיאה
`scripts/session-setup.sh: line 130: [: 0\n0: integer expression expected`.
בדיקת ה-learning_loop (שורה 130) לא רצה כלל, וה-Stop hook ב-`.claude/settings.json`
פלט אותה שגיאה ל-stderr בכל עצירה כשהיו קבצים ב-staging אך לא קבצי קוד.  **(נדרש)**

## שורש הבעיה
`grep -c PAT` **מדפיס `0` לפלט וגם יוצא עם קוד יציאה 1** כשאין התאמות. לכן
`VAR=$(... | grep -c PAT || echo 0)` מריץ את `echo 0` *בנוסף* ל-`0` ש-grep כבר הדפיס,
וה-משתנה מקבל ערך דו-שורתי `"0\n0"`. בשימוש ב-`[ "$VAR" -gt 0 ]` bash מפרש זאת
כביטוי לא-תקין ופולט `integer expression expected`.  **(נדרש)**

## השערות שנבדקו
- `wc -l` משאיר רווחים/newline שלא נוקו ב-`tr -d ' '` — נשללה: השורה עם `wc -l` תקינה.
- `grep -c` מחזיר ערך לא-מספרי — נשללה: `grep -c` תמיד מספרי.
- ה-`|| echo 0` הוא המקור — אומתה: הריצה `printf 'a\nb' | grep -c zzz || echo 0`
  מחזירה שתי שורות `0` ו-`0`.

## ראיה
```
$ RF=$(git log --oneline -10 | grep -c "zzz-no-match" || echo 0)
$ printf '%s' "$RF" | wc -l      # → 1  (כלומר שני ערכים: "0\n0")
$ [ "$RF" -gt 0 ]
bash: [: 0
0: integer expression expected
```  **(נדרש)**

## רמת ביטחון
High  **(נדרש)**

## איך מזהים מוקדם
כל `grep -c` שמוזרם ל-`|| echo`/`|| true` ואז נכנס לבדיקה אריתמטית. `shellcheck`
(SC2185 וסביבתו) ובדיקת `wc -l` על הערך תופסות זאת לפני ריצה.

## איך מונעים בעתיד
הדפוס הנכון מטפל בקוד-היציאה בהשמה במקום בהזרמה:
`VAR=$(... | grep -c PAT) || VAR=0` — הפלט תמיד שורה אחת. נוסף guard סטטי בטסט
הרגרסיה שסורק את `scripts/` ו-`.claude/settings.json` ונכשל אם הדפוס חוזר.  **(נדרש)**

## טסט רגרסיה
`scripts/enforcement/tests/test-no-grep-c-echo.sh` — סורק את הדפוס (נכשל לפני התיקון
על שתי השורות הבעייתיות) + בדיקת התנהגות שמוודאת שהצורה התקינה מחזירה שורה אחת
ועוברת `[ -gt ]` בלי שגיאה. רץ ב-CI דרך glob `test-*.sh` ב-`enforcement-tests.yml`.  **(נדרש)**

## סטטוס הבשלה
Verified Lesson  **(נדרש)**

## Prevented Future Issues: 0
