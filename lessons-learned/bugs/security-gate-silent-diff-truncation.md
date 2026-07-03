# Security gates must not silently truncate their input

## מה קרה
Codex review on Expiriens-saas-0.9 PR #2 (a real downstream install of Engineering OS) found that the generated `security-review-nemotron.yml` CI workflow sent only `diff[:12000]` to the Nemotron reviewer. Any PR whose patch exceeded 12000 characters had everything past that point excluded from the security review while the check still reported success — the downstream validation PR itself (an install commit with 28 files, ~2400 lines) was exactly such a PR.

## שורש הבעיה
The workflow template in `scripts/skill-bootstrap.sh` bounded the model prompt with a single silent slice instead of an explicit policy for oversized input. Bounding the input was necessary (model context limits), but the failure mode chosen was silent omission inside a gate whose entire purpose is that nothing ships unreviewed. A gate that quietly reviews a prefix is worse than one that fails loudly, because it converts "unreviewed" into "approved".

## השערות שנבדקו
- The 12KB limit is a Nemotron API constraint that forces truncation — rejected: the API accepts multiple sequential calls; chunking the diff across calls reviews everything within the same per-call bound.
- The workflow never runs in practice so the slice is harmless — rejected: it runs on every downstream PR when `Nemotron_api_key` is configured; the skip path only covers the missing-key case.

## ראיה
Codex P2 finding on Expiriens-saas-0.9 PR #2 (`.github/workflows/security-review-nemotron.yml` line 36); the pre-fix heredoc in `scripts/skill-bootstrap.sh` contained `{diff[:12000]}`; the new regression test fails on that generator (`fail: diff reviewed via single truncating slice diff[:12000]`, exit 1) and passes 7/7 on the fixed one, including a behavioral check that reassembled chunks equal the full diff and the tail content is present.

## רמת ביטחון
High

## איך מזהים מוקדם
Grep every gate/reviewer invocation for slicing or head-style bounding of the artifact under review (`[:N]`, `head -c`, `cut -c`); if the bounded artifact is the thing being validated, the bound must either cover everything (chunking/pagination) or fail closed — never both bounded and green.

## איך מונעים בעתיד
The generated workflow now reviews the whole diff in 12000-character chunks (hard cap 25 chunks ≈ 300KB) and exits 1 above the cap with an explicit message, so oversized diffs block instead of shipping partially reviewed; `test-security-review-workflow-generator.sh` extracts the heredoc, compiles the embedded python, rejects single-slice truncation, and behaviorally verifies chunk coverage, so the anti-pattern cannot silently return to the generator.

## טסט רגרסיה
scripts/enforcement/tests/test-security-review-workflow-generator.sh

## סטטוס הבשלה
Verified Lesson

## Applies To Paths
- scripts/skill-bootstrap.sh
- external-skills/security-review

## Domain Tags
- security
- enforcement
- ci

## Prevented Future Issues: 0
