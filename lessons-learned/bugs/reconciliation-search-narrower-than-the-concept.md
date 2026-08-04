# A reconciliation search narrower than the concept it covers

## מה קרה
PR #269 moved `gap:telemetry-archive-import-integrity` from `open` to `closed`. Closing a gap in
this repo means reconciling every place the audit describes it, not just the registry row. I had
already been burned by this once — PR #267 needed a follow-up commit for exactly this — so this
time I searched for stale prose explicitly with
`grep -rn 'archive import\|archive-import' docs/operations/`, found nine locations, fixed all
nine, and wrote in the PR body that I had searched rather than trusted memory.

There were ten. The final current-state paragraph says "Telemetry **import** integrity ... remain
open" with no "archive" in it, so the pattern never saw it. Both ChatGPT Codex and CodeRabbit
flagged it independently within minutes of each other.

## שורש הבעיה
The search pattern was built from the gap's *identifier* (`telemetry-archive-import-integrity`)
and one nearby phrasing, while the thing being reconciled is a *concept* that prose refers to in
whatever words the sentence needed. Narrative text drops qualifiers freely: "telemetry archive
import integrity" becomes "telemetry import integrity" becomes "import integrity". A grep over one
spelling of an identifier is not a sweep over meaning, and reporting "I searched" gives the
reconciliation an air of completeness that the pattern did not earn.

The specific miss was the worst possible location. That paragraph ends with "under the current
canonical Experiment start decision, every remaining open gap still blocks the behavioral
experiment" — it is where the launch rule is stated. So a gap the same PR had just closed would
have continued to block the experiment, while the registry, the status table and the acceptance
checklist all said it was closed.

## השערות שנבדקו
- The registry row is the source of truth, so stale prose is cosmetic — **rejected**: the prose is
  where the experiment-start rule lives, so the contradiction is load-bearing, not decorative.
- Searching the gap identifier is sufficient because the audit is written around identifiers —
  **rejected**: measured, the identifier appears in 6 of the 10 locations; the other 4 are prose.
- A second occurrence means I was careless the first time — **partly**: PR #267's fix was correct
  for the locations it found. Both rounds failed the same way, which points at the method rather
  than the attention.

## ראיה
`grep -rn 'archive import\|archive-import' docs/operations/` returned 9 hits and did not include
the final current-state paragraph. Codex comment `#discussion_r3714016322` and CodeRabbit comment
`#discussion_r3714020640` on PR #269, raised independently against the same line. PR #267 needed
the same class of follow-up for three separate stale summaries.

## רמת ביטחון
High

## איך מזהים מוקדם
When closing a gap, do not search for the gap's name — search for what the gap is *about*, with
the qualifiers dropped, and read every hit rather than pattern-matching them. Then invert the
check: instead of asking "did I find every mention of this gap?", take each sentence in the
document that lists open or closed gaps and verify it against the registry row by row. That
direction is finite and checkable; the other direction depends on guessing every phrasing.

The tell that a reconciliation is incomplete is a claim in the PR body that it is complete without
saying what would have been missed.

## איך מונעים בעתיד
The durable fix is a checker that extracts gap-status claims from audit prose and compares them
against `docs/operations/known-gaps.tsv`, failing when a row marked `closed` is described as open
anywhere in the document. That does not exist yet and is recorded as `next_system_improvement` on
PR #269 rather than built inside a docs-only closure.

Until it does, the manual step is the inverted check above: for every sentence enumerating gap
status, list the gaps it names and diff that list against the registry. On PR #269 the corrected
sentence was verified this way — its four remaining phrases cover exactly the seven rows still
marked `open`, with `dispatch-scope-double-record` correctly absent because it is `mitigated`.

## טסט רגרסיה
None. Stated plainly rather than left implied: no deterministic gate catches this class today,
which is precisely why it has now recurred twice and why both catches came from external review
rather than from CI. `scripts/enforcement/tests/test-readiness-audit.sh` and
`test-known-gaps.sh` both pass on the defective document, because neither compares prose claims
against registry status.

## סטטוס הבשלה
Verified Lesson

## Applies To Paths
- docs/operations

## Domain Tags
- documentation
- readiness
- verification
- process

## Prevented Future Issues: 0
