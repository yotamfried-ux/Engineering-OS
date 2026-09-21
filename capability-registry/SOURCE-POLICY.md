# Source & Provenance Policy

## Trust tiers

**Tier A — canonical:** official vendor/framework documentation, recognized standards bodies/security projects, canonical upstream repositories.

**Tier B — maintained reference:** maintained example/reference repositories from the owning organization or a clearly identified project.

**Tier C — community capability:** third-party tools, skills, wrappers, curated lists and community repositories. Useful, but claims must be checked against their upstream and target environment.

**Tier D — historical evidence:** lessons, postmortems, archived Stage 3 material and failed solutions. Preserve for learning; never assume commands/paths remain current.

## Rules

- Exact product/API/install/release/security claims should use Tier A when available.
- A wrapper must name its upstream identity and distinguish upstream claims from locally reproduced evidence.
- Social-media discovery is a lead, not provenance. Resolve it to the canonical repo/article before cataloging.
- Share URLs must be stripped of personal query tokens before storage.
- A community benchmark, star count, token-saving percentage or performance claim is not an Engineering-OS fact until reproduced.
- For copied/adapted examples, record the upstream source and license/terms when relevant.
- When upstream changes invalidate a wrapper, mark it STALE or BROKEN rather than silently guessing.

## Minimum normalized capability record

Every new executable/installable capability should answer:
1. Purpose and trigger.
2. Do-not-use/overlap guidance.
3. Canonical upstream/source tier.
4. Mechanism and supported host(s).
5. Installation/activation.
6. Credentials/permissions.
7. Verification path.
8. What successful verification proves.
9. What it does **not** prove.
10. Security/privacy limitations.
11. Qualification status and verification date when actually tested.

Older assets may predate this contract. Their existence in the library does not imply live qualification.
