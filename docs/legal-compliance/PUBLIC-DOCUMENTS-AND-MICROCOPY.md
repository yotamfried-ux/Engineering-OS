# Public legal text: page catalog, drafting kit and inline disclosure

**All examples are for internal drafting ONLY: `DRAFT — NOT APPROVED FOR PUBLICATION`.** Real policies are factual descriptions of a real service. They must match code, tracking tools, contracts, user geography and processor configuration, and receive human legal approval. A Terms-of-Service page never absolves unlawful acts, compulsory consumer obligations or inadequate security.

See [official sources](OFFICIAL-SOURCES.md), [data inventory](DATA-INVENTORY-AND-RIGHTS.md), [consent](COOKIES-CONSENT-AND-MARKETING.md), [consumer/platform](COMMERCE-ACCESSIBILITY-AND-PLATFORMS.md).

## Where and when to show information

| Surface | Legal/consumer communication (conditional by product/jurisdiction) | Implementable evidence |
|---|---|---|
| Footer / navigation / app settings | Link to privacy notice, terms, contact/operator identity; cookie settings and accessibility route if relevant | Accessible links on desktop/mobile, real documents with version/date |
| Before submitting a personal-data form | Notice with controller, collection purpose, whether requested information is required, consequence of non-provision, sharing/relevant recipients and rights/contact, depending on applicable law | Screenshot at point of collection + no misleading copy |
| Signup/paid checkout | Clear action, essential terms, cost, renewal period, consent where needed; separate optional marketing | Review of click state, version and timestamp where meaningful |
| Analytics/tracking | Information and controls before activating non-exempt trackers where required | Block tag requests until valid signal, restore preferences, consent log |
| Payment / subscription | Total, currency, taxes/fees as applicable, trial expiry, recurring amount and timing, merchant, renewal/cancel/refund process | Real checkout + recurring event tests |
| Upload / AI / microphone / camera / location | Just-in-time explanation of handling and third-party destinations, access/permission consequences | Permission flow, off switch, actual SDK/provider evidence |
| Account / privacy center | Access/correction/deletion/withdrawal/marketing preferences as relevant; progress/status | Rights-workflow test and backend verified final state |
| Support & incident notice | Contact, realistic availability and, when triggered, incident notifications reviewed by owner | Approved notice version, secure recipient list, delivery proof |
| Product claims & testimonials | True, substantiated claims and permissions to use customer name/photo/feedback | Claims register; authentic evidence and consent |

## Privacy Notice — ORIGINAL **DRAFT** structure, not a published policy

```markdown
# מדיניות פרטיות — [שם המוצר]
סטטוס: טיוטה לבדיקת יועץ משפטי; אין לפרסם לפני השלמת הנתונים.
עודכן לאחרונה: [תאריך אמיתי]

1. מי מפעיל את השירות: [שם ישות משפטית, פרטי קשר, כתובת/מדינה בהתאם לדין].
2. על איזה מידע מדובר: [טבלה מדויקת של קטגוריות, מקור, האם חובה].
3. מטרות השימוש: [מטרה מפורשת לכל קטגוריית מידע].
4. בסיס חוקי / הסכמה לפי הדין החל: [לקבוע ולאשר לכל מטרה; אין להניח הסכמה כבסיס תמיד].
5. למי המידע נמסר: [ספקי אירוח, תשלומים, דיוור, אנליטיקה, AI, אנשי מקצוע; בפועל].
6. העברות בין מדינות: [ארצות, סוגי נמענים, מנגנון/הגנה לפי הדין הרלוונטי].
7. שמירת מידע ומחיקתו: [תקופות או קריטריונים אמיתיים, חריגים מבוססי דין].
8. אמצעי אבטחת מידע: [תיאור ברמת דיוק מתאימה שאינו מבטיח 100% הגנה].
9. זכויות המשתמש ודרך הפעלתן: [לפי מקום וסוג מידע — עיון, תיקון, מחיקה, התנגדות, וכו'].
10. קטינים: [אילו גילאים, האם נאסף מידע, בקרת הורים נדרשת אם חלה].
11. Cookies / SDKs / תקשורת שיווקית: [מטרות, בקרה על הסכמה והפניה להעדפות].
12. עדכונים למדיניות: [גרסאות ודרך יידוע במקרה של שינוי מהותי].
13. יצירת קשר ותלונות: [ערוץ עובד, רגולטור מתאים אם הדין דורש].
```

**Review requirements:** map each sentence to actual system behavior. No "we do not share data with third parties" if Supabase/hosting/email/analytics/AI service receives it; "we don't sell" is separate from transfers to providers. Avoid disclosure of detailed security topology or secrets.

## Terms of Service / SaaS Terms — ORIGINAL **DRAFT** headings

```markdown
# תנאי שימוש — [מוצר]
סטטוס: טיוטה לבדיקת יועץ משפטי — לא להציג כמסמך מחייב ללא אישור
1. זהות מפעיל השירות, פרטי קשר ותחולת התנאים.
2. מה השירות עושה ומה אינו מתחייב לספק; שירותי צד שלישי והיקף אחריותם.
3. כשירות משתמש, חשבון, הרשאות ואחריות לאימות פעולות.
4. זכויות וקניין רוחני: רישיון שימוש מוגבל במוצר, בעלות על תוכן משתמשים והרשאות שימוש הכרחיות בלבד.
5. שימושים אסורים, התנהגות מותרת, העלאה/דיווח על תוכן מפר, פעולות נגד שימוש לרעה.
6. זמינות, שינויים, תחזוקה ותמיכה: ללא הבטחות שלא ניתן לקיים.
7. מחיר, מסים, תשלום, תקופת חיוב/התחדשות, ניסיון חינם ומועד הודעה אם יש.
8. ביטול מנוי/עסקה, החזרים, שינוי תור ומחלוקות בכפוף לזכויות קוגנטיות.
9. השעיה/סגירה ומחיקת מידע — הליך, הודעה, שימור לפי דין, אפשרות ערעור ככל שרלוונטי.
10. הגבלות אחריות ושיפוי — רק בהיקף המותר לפי הדין; ניסוח בידי יועץ משפטי, ללא ויתור גורף.
11. דין וסמכות שיפוט — משפטית רק לאחר סקירת מדינות יעד, זכויות צרכניות מחייבות והסכמים.
12. עדכונים, הודעות, דרכי יצירת קשר וגרסאות.
```

**Lawyer-review-only sections:** enforceability of arbitration/class-action waivers, disclaimers, indemnity, responsibility limits, governing law, content ownership, regulatory warranties and subscription cancellation exceptions. Never invent binding legal clauses to "remove lawsuit exposure".

## Additional documents (conditional)

- **Acceptable Use Policy (AUP):** abuse/bots, illegal content, IP, scraping, spam, security testing, enforcement/appeals. Useful for community, user uploads or hosted AI.
- **DPA / subprocessor list:** if providing B2B processing services and applicable controller-processor rules; contracts should match actual vendor integrations.
- **Cookie policy / preferences:** only based on actual tags/SDKs and applicable rules. No banner if genuinely no applicable consent duty — still disclose tracking appropriately.
- **Returns/cancellation/refunds:** prominent separate customer-facing page if business needs it, with product and jurisdiction-specific exceptions vetted by counsel.
- **Accessibility statement:** truthful test scope, known limitations and contact path, rather than false "fully accessible" badge.
- **AI disclosure / special sector notice:** AI role, meaningful limitations, human review and data use when relevant.
- **Community guidelines / moderation rules:** for posts, messaging, matching/marketplace and reporting abusive content; rights and due-process review.
- **Copyright notice / takedown contact:** where publishing user content or serving relevant territories; counsel decides DMCA/other regime and handling.

## Point-of-collection and consent microcopy (original, illustrative Hebrew)

**Appointment contact** (after real purpose is validated):
> `נשתמש במספר הטלפון כדי לשלוח מידע על התור ולטפל בשינויים. פרטי המפעיל, השימוש במידע וזכויותיך מופיעים במדיניות הפרטיות.`

**Optional marketing** (separate, initially unchecked where consent is appropriate):
> `אני רוצה לקבל הצעות ועדכונים שיווקיים מ-[שם העסק] ב-[ערוצים]. אפשר לבטל בכל עת.`

**Cookie preferences** (only when appropriate to actual implementation):
> `אנו משתמשים באמצעים חיוניים להפעלת השירות. אפשר לבחור בנפרד אם לאפשר מדידה ושיווק.` Buttons: `דחיית לא-חיוניים`, `שמירת בחירה`, `אישור הכול` (no pre-checked optional categories where consent is required).

**Account deletion**:
> `שליחת בקשת מחיקה` — `נציג מה יימחק ומה נידרש לשמור לפי הדין. הבקשה תיבדק לאחר אימות זהות כנדרש.`

**Subscription action**:
> `התחלת מנוי בסך [סכום אמיתי] ל-[תקופה], עם [תנאי חידוש מאומתים]`; show cancellation link and full terms next to action.

These are UX examples; not a guarantee that every statutory notice element is included. Require in-context disclosures as well as a complete policy where law calls for both.

## Publication guardrail

Before deploying: factual data map ✅, territory applicability ✅, policy versions ✅, screenshots ✅, links/contact tested ✅, legal counsel reviewed ✅, purchase/consent/deletion integration tests ✅. Missing approval = **DRAFT / NOT CLEARED**, not live.
