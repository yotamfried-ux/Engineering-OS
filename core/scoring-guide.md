# scoring-guide.md — כיצד לדרג pattern בפועל

> חלק מ-Engineering OS. מצורף ל-[`pattern-lifecycle.md`](./pattern-lifecycle.md).
>
> **מתי לגשת לקובץ הזה:**
> - לפני שמשנים ציון של pattern קיים
> - כשרוצים להעביר pattern מ-`Candidate` ל-`Active`
> - כשצריך להחליט אם pattern כושל מוריד ציון או מוביל ל-`Deprecated`

---

## עיקרון יסוד

**ציון מבוסס תוצאות בלבד — לא תיאוריה.**

Pattern שנראה נכון תיאורטית אך לא שימש בפרויקט אמיתי אינו מקבל ציון. הוא נשאר `Score: Candidate` עד שיש ראיה מ-≥1 שימוש אמיתי. ראה [`pattern-lifecycle.md`](./pattern-lifecycle.md) › `<scoring>`.

---

## <scoring_process>

### שלב 1 — תנאי סף לפני כניסה לתהליך

לפני שמנסים לדרג, ודא שקיימים:

```
[ ] הקוד של ה-pattern שימש בפרויקט אחד לפחות (לא רק תיעוד/דוגמה)
[ ] יש תוצאה מדידה: הפרויקט פועל בפרודקשן, עבר בדיקות, או הושלם
[ ] ה-pattern לא שונה בצורה מהותית מהתיעוד שלו בעת השימוש
```

אם אחד מהתנאים לא מתקיים → `Score: Candidate` — אל תנסה לדרג.

---

### שלב 2 — אסוף ראיות

צור רשומת `evidence` ב-`registry.yaml`. לכל פרויקט שהשתמש ב-pattern, תעד:

```yaml
evidence:
  - "Project: [שם פרויקט] | Duration: [כמה זמן בפרודקשן] | Incidents: [מספר] | Notes: [הערה]"
```

דוגמה:
```yaml
evidence:
  - "Project: api-gateway | Duration: 3 months prod | Incidents: 0 | Notes: adapted pool.max for serverless"
  - "Project: analytics-service | Duration: 6 weeks | Incidents: 1 (connection leak, fixed via pattern update) | Notes: required try/finally addition"
```

---

### שלב 3 — דרג כל קריטריון

דרג 0–5 לכל קריטריון. אפס = ראיה לכשל מוחלט; 5 = ביצועים מושלמים בכל השימושים.

#### Reliability (0–5)
שאלה: האם ה-pattern פעל בפרודקשן ללא incidents שנגרמו ממנו ישירות?

| ציון | קריטריון |
|---|---|
| 5 | ≥3 שימושים, 0 incidents |
| 4 | ≥2 שימושים, לכל היותר incident קל שטופל בקל |
| 3 | שימוש אחד, 0 incidents; או 2 שימושים עם incident אחד |
| 2 | שימוש עם incident שדרש תיקון מהותי ב-pattern |
| 1 | כשל חלקי; ה-pattern לא התאים לתנאי הפרודקשן |
| 0 | כשל מוחלט; ה-pattern גרם ל-outage או data loss |

#### Maintainability (0–5)
שאלה: כמה קל היה להתאים את ה-pattern לפרויקט ספציפי?

| ציון | קריטריון |
|---|---|
| 5 | אומץ as-is בכל השימושים; שינויים מינוריים בלבד |
| 4 | שינויים קטנים (שם משתנה, ערך קונפיגורציה) ב-<25% מהשימושים |
| 3 | שינויים מתונים (הוספת שדה, שינוי logic קל) ב-≥50% מהשימושים |
| 2 | שכתוב משמעותי נדרש ב->50% מהשימושים |
| 1 | ה-pattern שימש כנקודת מוצא בלבד; הסוף שונה מהותית |
| 0 | ה-pattern לא ניתן לשימוש as-is; כל שימוש הצריך שכתוב מחדש |

#### Security (0–5)
שאלה: האם ה-pattern עבר סקירת אבטחה ולא נמצאו בו חורים?

| ציון | קריטריון |
|---|---|
| 5 | עבר סקירת אבטחה פורמלית; 0 ממצאים |
| 4 | נסקר ב-code review; 0 ממצאים קריטיים |
| 3 | לא נסקר פורמלית; אך Security Considerations מתועדים ואומצו |
| 2 | נמצאה חולשה אבטחה קלה; תוקנה ב-pattern |
| 1 | נמצאה חולשה מהותית; תוקנה אבל מעידה על בעיה בעיצוב |
| 0 | חולשת אבטחה חמורה (injection, data leak, auth bypass) |

#### Performance (0–5)
שאלה: האם ה-pattern עמד בדרישות ביצועים בשימוש אמיתי?

| ציון | קריטריון |
|---|---|
| 5 | ביצועים מצוינים; מעל דרישות ה-SLO |
| 4 | עמד בדרישות ה-SLO בכל השימושים |
| 3 | עמד בדרישות ב-≥75% מהשימושים; התאמה קלה לאחרים |
| 2 | בעיות ביצועים בחלק מהשימושים שהצריכו שינויים |
| 1 | בעיות ביצועים מהותיות; ה-pattern אינו מתאים לעומסים גבוהים |
| 0 | כשל ביצועים מוחלט (timeout, OOM, deadlock) |

#### Production Success Rate (0–5)
שאלה: מה יחס השימושים שהצליחו ללא חזרה מהותית?

| ציון | קריטריון |
|---|---|
| 5 | 100% הצלחה (כל השימושים עבדו) |
| 4 | ≥80% הצלחה |
| 3 | ≥60% הצלחה |
| 2 | ≥40% הצלחה |
| 1 | <40% הצלחה |
| 0 | 0% הצלחה (כל השימושים נכשלו) |

#### Reusability (0–5)
שאלה: האם ה-pattern שימש ביותר מהקשר אחד ללא שכתוב מהותי?

| ציון | קריטריון |
|---|---|
| 5 | ≥3 הקשרים שונים בלי שינוי מהותי |
| 4 | 2–3 הקשרים; שינויים מינוריים בין הקשרים |
| 3 | 2 הקשרים; שינויים מתונים נדרשו |
| 2 | שימוש יחיד; פוטנציאל ברור לשימוש חוזר אך לא מאומת |
| 1 | שימוש יחיד; ספק אם ניתן לשימוש חוזר ללא שכתוב |
| 0 | ה-pattern ספציפי מדי לשמש מחדש |

---

### שלב 4 — חשב ציון כולל

```
Score = (Reliability × 2 + Maintainability + Security × 2 + Performance + Success_Rate × 2 + Reusability) / 10
× 100 / 5 = 0–100
```

נוסחה מפושטת:
```
raw = (R*2 + M + S*2 + P + SR*2 + Re) / 10
Score = raw * 20   (scale 0–100)
```

דוגמה:
```
Reliability=4, Maintainability=3, Security=5, Performance=4, Success_Rate=4, Reusability=3
raw = (8+3+10+4+8+3)/10 = 36/10 = 3.6
Score = 3.6 * 20 = 72
```

---

### שלב 5 — קבע lifecycle status

| ציון | `used_in` | מעבר מוצע |
|---|---|---|
| ≥60 | ≥2 | → `Active` |
| 40–59 | ≥1 | → `Candidate` (המשך לאסוף ראיות) |
| <40 | כלשהו | שקול `Deprecated`; פתח לקח ב-`learning-loop.md` |
| ≥60 + incident חמור | כלשהו | חזור ל-`Candidate`; פתח לקח |

---

### שלב 6 — עדכן registry.yaml

```yaml
- id: database-connection-pooling
  domain: database
  status: active       # אם עובר → active
  score: 72
  version: 1.0.0
  used_in: 2
  scored_at: 2026-06-15
  scored_by: [שם]
  evidence:
    - "Project: api-gateway | Duration: 3 months | Incidents: 0 | Notes: adapted pool.max"
    - "Project: analytics | Duration: 6 weeks | Incidents: 1 minor | Notes: added try/finally"
  code: ../patterns/database/README.md#connection-pooling
```

---

### שלב 7 — עדכן ה-pattern עצמו

בקובץ ה-pattern, שנה `Score: TBD` → `Score: 72/100 — Active`:

```markdown
**Score:** 72/100 — Active (see registry.yaml › database-connection-pooling)
```

---

## <scoring_faq>

**שאלה: מה עושים עם pattern שנוצר אבל עדיין לא שימש?**  
ממתינים. ה-pattern נשאר `Candidate` עם `Score: TBD`. אין ציון ללא ראיה.

**שאלה: מה אם ה-pattern שימש אבל אין לנו תיעוד מספיק?**  
הגדר את הראיה כ-"Low Confidence" וציין זאת ב-`evidence`. ציון מבוסס-ראיה-דלה עדיף על ציון ללא ראיה, אבל הגדרתו כ-`Low Confidence` מאפשרת לאחרים לשפוט.

**שאלה: האם ניתן לדרג pattern מעל 80 בלי ≥3 שימושים?**  
לא מומלץ. ציון ≥80 מייצג "Active + מוכח היטב" — זה דורש ≥3 שימושים. ציון 60–79 עם 2 שימושים הוא Active סביר.

**שאלה: מה קורה לציון אחרי incident?**  
Incident ישיר מ-pattern מוריד Reliability ב-2 ו-Success_Rate ב-2. חשב מחדש ועדכן. אם הציון יורד מתחת ל-40 → `Deprecated` + לקח ב-`learning-loop.md`.

</scoring_faq>

---

## <pattern_scoring_checklist>

לפני סגירת דירוג — ודא:

```
[ ] ≥1 ראיה אמיתית מפרויקט אמיתי תועדה ב-registry.yaml
[ ] כל 6 קריטריונים דורגו עם הסבר קצר
[ ] הציון חושב לפי הנוסחה (לא "נראה לי 75")
[ ] lifecycle status עודכן ב-registry.yaml
[ ] שורת Score ב-pattern file עודכנה (לא TBD)
[ ] אם ה-pattern עלה ל-Active — ≥2 ראיות קיימות
```

</pattern_scoring_checklist>
