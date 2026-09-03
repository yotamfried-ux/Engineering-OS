# CRLF מזהם את השדה האחרון בקריאת TSV ב־Bash

## מה קרה

מתקין Engineering OS קרא manifest מופרד בטאבים באמצעות `read`. ב־Windows, ‏Git עם
`core.autocrlf=true` שמר את הקובץ עם סיומות `CRLF`. השדה האחרון בכל שורה שמר תו
carriage return נסתר, ולכן בדיקת קיום דיווחה שקובץ קיים חסר ועצרה התקנה באמצע.

## שורש הבעיה

`IFS` מפריד את הטאב אך אינו מסיר `\r` מסוף השדה האחרון. הנתיב שנבדק היה למעשה
`check-pr-review-evidence.sh\r`, ולא שם הקובץ האמיתי.

## השערות שנבדקו

- shallow clone השמיט קבצים — נשללה: הקובץ המדווח נמצא בעותק המקומי.
- כשלי graphify, rtk או claude-mem עצרו את ההתקנה — נשללה: הם סומנו כלא־קריטיים.
- הרשאות GitHub גרמו לכשל — נשללה: הכשל התרחש בבדיקת קובץ מקומית.
- CRLF נשמר בתוך שדה ה־TSV — אומתה: נמצאו 29 סיומות CRLF ו־`core.autocrlf=true`.

## ראיה

ה־manifest המקומי הכיל 29 רצפי CRLF, בעוד
`scripts/enforcement/check-pr-review-evidence.sh` נמצא באותו checkout. הודעת השגיאה
התאימה לנתיב עם תו `\r` נסתר. רגרסיית ההתקנה ממירה כעת את fixture ה־manifest ל־CRLF
לפני הפעלת המתקין.

## רמת ביטחון

High

## איך מזהים מוקדם

כאשר Bash מדווח שקובץ שמופיע ב־`ls` חסר לאחר קריאת CSV/TSV, יש להציג את הקלט באופן
שחושף תווים נסתרים ולבדוק `CRLF`, ‏BOM ורווחים סופיים.

## איך מונעים בעתיד

- לנרמל שדות חיצוניים בגבול הקריאה לפני אימות או שימוש כנתיב.
- לקבוע `eol=lf` ב־`.gitattributes` עבור shell manifests.
- לבדוק את המימוש גם עם fixture אמיתי של CRLF; אין להסתמך רק על checkout של Linux CI.
- להשאיר את בדיקת התלות fail-closed — לתקן את הקלט, לא להחליש את השער.

## טסט רגרסיה

`scripts/enforcement/tests/test-install-policy-gate-coverage.sh` ממיר את
`policy-gate-dependencies.tsv` ל־CRLF ומוודא שהמתקין עדיין מעתיק כל dependency.

## סטטוס הבשלה

Verified Lesson

## Prevented Future Issues: 0
