# awk case-insensitive matching must not rely on gawk's IGNORECASE

## מה קרה
`scripts/enforcement/tests/test-plan-scope.sh`'s scenario "should allow when graphify_used and
findings both present" failed locally in an Engineering OS operational acceptance burn-in
(remote container, `/usr/bin/awk` → mawk 1.3.4), even though the identical fixture passes in
GitHub Actions CI (`ubuntu-latest`, run `28628591263`, head SHA
`8cb774d030ed6c6f5f8d17ac89f421980f31a615`, conclusion `success`). `check-plan-scope.sh`
returned `ERROR_FOR_AGENT: missing structured graph usage evidence` for a plan file that
clearly contained a `## Graphify findings` section.

## שורש הבעיה
`check-plan-scope.sh`'s `section_text()` and `section_field()` used `BEGIN{IGNORECASE=1}` to
make heading/field matching case-insensitive. `IGNORECASE` is a **gawk-only** extension — it
is silently ignored (not an error) by POSIX/mawk implementations. mawk is the default
`/usr/bin/awk` on Debian/Ubuntu via `update-alternatives`, so any environment without gawk
explicitly installed degrades this gate to case-sensitive matching without any warning. A
plan's heading/field casing that differs from the literal capitalization the script expected
no longer matched once case-insensitivity silently stopped working, causing a false block.
Verified as the root cause by reproducing the exact failure with a minimal `awk` one-liner
under mawk (see Evidence below): the missing gawk extension, not a logic regression, caused
the case-sensitive fallback.

## השערות שנבדקו
- Logic regression in a recently merged change — rejected: `check-known-gaps.sh` and
  `check-readiness-audit.sh` both pass clean on `main`, and the identical CI job succeeded on
  the exact same commit SHA on `ubuntu-latest`.
- Flaky/non-deterministic test — rejected: re-running the isolated test five times in the same
  container reproduced the failure identically every time; it is not a race condition.
- awk implementation difference (mawk vs gawk) — verified: `awk 'BEGIN{IGNORECASE=1; if ("ABC"
  ~ /abc/) print "works"; else print "not supported"}'` printed "not supported" in the burn-in
  container; `dpkg -l | grep awk` showed only `mawk` installed, no `gawk`.

## ראיה
Manual reproduction: `echo "## Graphify Findings" | awk -v re='...Findings' 'BEGIN{IGNORECASE=1}...'`
matched; the same command with `"## Graphify findings"` (lowercase f) did not match, confirming
case-sensitive fallback. `mcp__github__pull_request_read` (`get_check_runs`, `get_commits`) on
PR #185 confirmed the enforcement-tests workflow ran green (`conclusion=success`) on
`ubuntu-latest` for head SHA `8cb774d030ed6c6f5f8d17ac89f421980f31a615`, proving the
gawk-equipped CI runner masks this class of bug. `graphify explain "check-plan-scope.sh"`
confirmed `section_text()`/`section_field()` are self-contained (14-node file, no other script
depends on either function), so the fix's blast radius is isolated to this one file. After the
fix, `bash scripts/enforcement/tests/test-plan-scope.sh` passes all checks including a new
mixed-case regression scenario (`scenario_evidence_mixed_case`) that fails without the fix.

## רמת ביטחון
Medium (root cause proven with direct reproduction and a regression test that fails on the old
code and passes on the fix; observed in one environment/container so far, not yet confirmed
across multiple independent downstream projects).

## איך מזהים מוקדם
Grep enforcement scripts for `IGNORECASE` before merging any awk-based gate change; run the
enforcement suite once under a container/base image whose `/usr/bin/awk` is mawk (e.g. plain
`debian:slim` or `ubuntu:latest` without `apt-get install gawk`) to catch this class of bug
before it reaches a downstream project that lacks gawk.

## איך מונעים בעתיד
Replaced `BEGIN{IGNORECASE=1}` with an explicit `tolower()` fold on both the search pattern and
the input line/field in `section_text()`/`section_field()`
(`scripts/enforcement/check-plan-scope.sh`), matching the portable style already used by
`field_value()` in the same file. No other enforcement script under `scripts/enforcement/` uses
`IGNORECASE` (verified via `grep -rl IGNORECASE scripts/enforcement/*.sh`), so the blast radius
was isolated to this one file.

## Prevention/Enforcement Update
Added a new regression test (`scenario_evidence_mixed_case` in
`scripts/enforcement/tests/test-plan-scope.sh`) that fails without the fix and passes with it,
so this class of gawk-only-extension regression is caught by CI going forward. Also verified
via `grep -rl IGNORECASE scripts/enforcement/*.sh` that no other enforcement gate depends on
`IGNORECASE`, so no further enforcement update was needed beyond this one file.

## טסט רגרסיה
`scripts/enforcement/tests/test-plan-scope.sh` — scenario `scenario_evidence_mixed_case` (new)

## סטטוס הבשלה
Verified Lesson

## Applies To Paths
- scripts/enforcement/check-plan-scope.sh

## Domain Tags
- enforcement
- portability
- testing

## Prevented Future Issues: 0
