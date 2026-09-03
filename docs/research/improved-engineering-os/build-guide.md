# Improved-Engineering-OS — End-to-End Build Guide

| Field | Value |
|---|---|
| Document status | `1.0-review` — execution guide layered on the owner's `Architecture Baseline 1.0` report |
| Source report | "Improved-Engineering-OS — דוח ארכיטקטורה סופי ותוכנית מימוש מבוססת ראיות" (4 Sep 2026) |
| Written from | Engineering-OS repository, branch `claude/engineering-os-project-guide-roj911` |
| Verified against | this repository's lessons and Project 8 findings; Supabase docs and MCP spec `2026-07-28` via Context7 (see Appendix B) |
| Consumers | (1) the owner, for the review verdict; (2) the coding agent that builds the new repository |
| Precedence | Architecture Constitution in the report > this guide > agent judgment. Where this guide changes the report, the change is marked `CHANGED` and explained. |

---

## 0. הקדמה למשתמש (עברית)

המסמך הזה עושה שלושה דברים:

1. **ביקורת** — עובר על 17 ההחלטות ועל תוכנית ה-Stages ומכריע לכל אחת: `CONFIRMED`, `CONFIRMED+CHANGE` או `GAP`. כל פער שעלול להפוך לחוב טכני מקבל מזהה `TD-xx`, חומרה, ופתרון קונקרטי (סעיף 1).
2. **השלמות** — מוסיף החלטות D18–D30 שהדוח לא סגר אבל אי אפשר לבנות בלעדיהן (שפה, פלטפורמות, זהות נכסים, אחסון ידע, credentials, סשנים מרוחקים, תלויות). כל אחת מסומנת `PROPOSED` עד שתאשר, עם ברירת מחדל מומלצת כדי שהסוכן לא ייתקע (סעיף 2).
3. **מדריך בנייה** — מבנה הריפו, ואז לכל Stage: מה בונים, באילו נתיבים, אילו ממשקים, אילו בדיקות/סימולציות, ומה שער היציאה (סעיפים 3–7). הסוכן אמור לעבוד Stage אחרי Stage בלי לנחש.

**איך להשתמש:** פתח ריפו חדש, הכנס לתוכו את הדוח המקורי כ-`ARCHITECTURE.md` ואת המסמך הזה כ-`BUILD-GUIDE.md`, אשר או שנה את D18–D30 (טבלה בסעיף 2.0), ואז תן לסוכן את ההנחיה בסעיף 6.1. השאר כתוב באנגלית בכוונה: זו השפה שבה הסוכן מפרש מפרט בצורה הכי חד-משמעית.

**שורה תחתונה של הביקורת:** הארכיטקטורה נכונה ועקבית. שני הפערים שבאמת יכלו לעלות ביוקר הם (א) הדוח מניח "Local Runtime" עם SQLite קבוע, בעוד חלק ניכר מהעבודה שלך רץ בסשנים מרוחקים/אפמרליים שבהם ה-outbox נמחק — בדיוק הכשל שנרשם ב-Project 8; (ב) הדוח לא בוחר stack, פלטפורמות ומבנה אחסון של הידע, וזו ההחלטה הראשונה שסוכן קוד יעשה לבד אם לא תקבע אותה. שניהם סגורים למטה (D18, D23).

---

## 1. Review verdict

### 1.1 Decision-by-decision

| Decision | Verdict | Note |
|---|---|---|
| D1 Personal system | CONFIRMED | Keep `owner_id` in every durable row from day one anyway (RLS needs it; costs nothing). |
| D2 Claude + Codex first, neutral core | CONFIRMED | Enforced mechanically by fitness test F1 (Section 4, Stage 0). |
| D3 Central canonical repo | CONFIRMED | Monorepo layout fixed in Section 3. |
| D4 Thin project footprint | CONFIRMED+CHANGE | The footprint must be *generated*, never hand-edited, and must include the agent bootstrap files (`.mcp.json` entry, one paragraph in `AGENTS.md`/`CLAUDE.md`). See D18.4 and TD-07. |
| D5 Dynamic Project Profile | CONFIRMED | `spec` in Git, `status` in Evidence Plane as written. Add `installation_id` to observations (TD-05). |
| D6 Asset model | CONFIRMED+CHANGE | Schema is metadata only; body storage, identity minting and legacy IDs were unspecified. Closed by D19, D20. |
| D7 Evidence-based catalog, Champion | CONFIRMED+CHANGE | Requires an offline score snapshot in the release or `resolve` fails without network. Closed by D24. |
| D8 Observation → Curation → Admission | CONFIRMED+CHANGE | "Promotion Proposal" and "user approval" need a concrete mechanism: a pull request into the canonical repo. Closed by D21. |
| D9 `resolve / inspect / expand` | CONFIRMED+CHANGE | Read-only contract has no write side, so the learning loop has no input other than passive telemetry. Add `observe`. Closed by D25. |
| D10 Adaptive Assurance | CONFIRMED+CHANGE | `stale_after_revision_change: true` on every commit makes every Control stale on every push. Scope staleness by paths. Closed by D27. |
| D11 Telemetry / Evidence | CONFIRMED+CHANGE | Correct for a persistent local machine; wrong for ephemeral remote sessions. Closed by D23. Attribute allowlist made mandatory by D26. |
| D12 Pinned releases, launcher | CONFIRMED+CHANGE | Launcher language/runtime unspecified; bootstrap problem if launcher needs the thing it installs. Closed by D18.2. |
| D13 Future-adaptive agent integration | CONFIRMED | MCP `2026-07-28` verified: stateless core, sessions removed from Streamable HTTP, explicit handles. The report's conclusion (MCP is transport, not domain) is reinforced. |
| D14 Verification, evals | CONFIRMED+CHANGE | Hidden evaluator workspace needs a physical mechanism (separate directory excluded from the agent sandbox), and agent trials need a headless driver per agent. Section 4, Stage 0/8. |
| D15 Dynamic external ecosystem | CONFIRMED | Freshness classes need a TTL policy file from Stage 11; no change to design. |
| D16 Reuse knowledge, rebuild system | CONFIRMED | Import corpus and exclusion list in Appendix A. |
| D17 Simulation-gated implementation | CONFIRMED | Stage order kept. Stage 5 (telemetry) gains a plan-tier decision gate (D30). |

### 1.2 Technical-debt findings

Severity: **S1** = would force a redesign or data migration later; **S2** = would cause recurring friction or silent wrong behavior; **S3** = cleanup cost only.

| ID | Sev | Finding | Why it becomes debt | Resolution |
|---|---|---|---|---|
| TD-01 | S1 | No implementation language, runtime, package layout or supported platforms are decided. | The first agent session decides them implicitly and every later stage inherits the accident. Windows support in particular cannot be retrofitted cheaply (this repo already carries a CRLF policy plan). | D18 |
| TD-02 | S1 | Telemetry design assumes a persistent local machine with a durable SQLite outbox. Claude Code on the web / cloud sessions run in ephemeral containers that are reclaimed; the outbox dies with them. This exact failure produced `telemetry_events_count: 0` in two real Project 8 runs (`lessons-learned/bugs/remote-workspace-telemetry-requires-durable-handoff.md`). | Stage 5 passes on a laptop and Stage 15 silently produces no evidence. | D23 |
| TD-03 | S1 | Asset Score is derived in the Supabase Evidence Plane but `resolve` must work offline and must not block coding. Nothing says where scores come from when the plane is unreachable. | Either `resolve` grows a hidden network dependency or scores are duplicated ad hoc. | D24 |
| TD-04 | S1 | Asset schema has no body/content model, no identity-minting rule, no rename rule, no legacy ID mapping. | Stage 2 import invents a layout under time pressure; Stage 4 retrieval then depends on it; changing it later means re-importing 300+ assets. | D19, D20 |
| TD-05 | S2 | Telemetry envelope lacks `installation_id` / `device_id` and `session_kind`. `source.sequence` is meaningless across machines and containers. | Dedupe and causal ordering break the first time two environments report on the same Work Item. | D26 (envelope fields) |
| TD-06 | S2 | `attributes: key: value` is free-form. This repository already learned that a denylist scanner leaks nested fields and that only an allowlist reconstruction is safe. | Secrets/prompt fragments end up in Supabase; retroactive purge is expensive. | D26 |
| TD-07 | S2 | "Optional minimal agent bootstrap" in the target project is undefined. If it is hand-written it drifts from the pin; if it is missing the agent never discovers EOS (hooks/MCP are loaded at session start, per Project 8 findings). | Stage 8 "no coaching" criterion fails for the wrong reason. | D18.4 |
| TD-08 | S2 | Promotion approval has no mechanism. A custom approval UI/CLI would be a new surface to maintain. | Approval state ends up in a side database that is not the canonical Git. | D21 |
| TD-09 | S2 | `stale_after_revision_change: true` at repository granularity. | Every commit invalidates every Control; Assurance becomes noise and gets ignored, or agents re-run everything. | D27 |
| TD-10 | S2 | Agent Contract is read-only. Observations, user decisions and "I applied asset X" have no first-class write path. | Attribution (`APPLIED` vs `EXPOSED`) has to be guessed from traces. | D25 |
| TD-11 | S2 | Supabase plan tier, backups and export are undecided. Free plan pauses after 7 days of inactivity and has no downloadable backups (verified, Appendix B). | The Evidence Plane pauses during a quiet fortnight; Stage 13 "graceful degradation" then runs in production by accident. | D30 |
| TD-12 | S2 | Credential boundary is described but not concretized: which Supabase auth identity the local runtime uses, where the token lives, what the agent process can read. | Someone puts a secret key in `.env` "temporarily". | D22 |
| TD-13 | S2 | Retrieval mechanism for `resolve` is unspecified. Starting with vendor embeddings couples the core to a provider and makes Stage 4 metrics non-reproducible. | Provider lock-in inside the resolver; eval drift when the embedding model changes. | D20.3 |
| TD-14 | S2 | Problem / capability taxonomy (`problem.id`, `capabilities[]`) has no owner or growth rule; Solution Set equivalence depends on it. | Taxonomy sprawl makes "one Champion per equivalent problem" undecidable. | D28 |
| TD-15 | S2 | No dependency policy for EOS itself (pins, lockfile, update cadence, SBOM) although releases are digest-pinned. | The pinned release is reproducible but its inputs are not. | D29 |
| TD-16 | S3 | Evaluator workspace isolation is stated as a principle without a mechanism. | Hidden fixtures leak into the agent checkout via a normal `git clone`. | Stage 0 layout: `evaluator/` excluded from agent sandboxes by construction. |
| TD-17 | S3 | Report citations are unresolved placeholders (`citeturn15view4` etc.). | The document cannot be audited or refreshed. | Replace with URLs from Appendix B before committing the report as `ARCHITECTURE.md`. |
| TD-18 | S3 | The 17 decisions exist only inside one large report. | No per-decision history, no supersession. | Stage 0: split into `docs/adr/ADR-0001..0017.md` with status fields. |
| TD-19 | S3 | Two named real projects ("Project 8", "SportReel") appear in stage manifests. | Core or fixtures acquire project-specific paths. | Fitness test F6; canaries live in `qualification/targets/*.yaml`, never in core. |
| TD-20 | S3 | Agent trial cost (tokens, wall-clock) for Stages 8, 12, 14, 15 is unbudgeted. | Stages get skipped "for now". | Stage 0 budget record; Section 7 register item 9. |

### 1.3 Corrections to the report text

- Replace every `citeturn…` token with a real URL (Appendix B has the verified ones).
- "MCP moved to a stateless core in July 2026": verified. Add to the same paragraph: protocol-level sessions and session headers were removed from Streamable HTTP, and HTTP+SSE is deprecated. Consequence for D13: the EOS MCP adapter must not keep per-connection state; handles go in tool arguments.
- "Supabase migrates from anon/service_role to publishable/secret keys by end of 2026": verified. Add: secret keys return HTTP 401 from browser contexts, which does not help a CLI process; the boundary is procedural, not technical (see D22.4).
- "Database backups do not include Storage objects": verified. Also add: Free plan has no automated daily backups and pauses after 7 idle days (D30).
- Stage 1 "OS/runtime combinations supported" must reference the platform list in D18.3, otherwise the gate is unfalsifiable.
- Stage 8 hidden condition "no instruction saying to call `resolve`" conflicts with D4's bootstrap unless clarified: the generated bootstrap may *describe* EOS tools generically; it may not contain task-specific coaching. Wording fixed in Section 4, Stage 8.

---

## 2. Added decisions (D18–D30)

### 2.0 Owner approval table

Each row is `PROPOSED` with a recommended default. The coding agent proceeds with the default unless the owner changes the row. Record the outcome in `docs/adr/ADR-00NN.md` at Stage 0.

| Decision | Recommended default | Alternative kept as Challenger |
|---|---|---|
| D18 Stack & platforms | TypeScript (Node 22 LTS), pnpm workspaces, one language for core and launcher; Linux, macOS, Windows native + WSL | Go launcher if the "Node is always present" assumption breaks |
| D19 Identity | Opaque ULID ids + mutable slugs + `content_hash`; `legacy_ids[]` | Path-derived ids (rejected: renames change identity) |
| D20 Asset storage & retrieval | One directory per asset (`asset.yaml` + `body.md` + files); deterministic retrieval (capability graph + SQLite FTS5) shipped as an index in the release | Embeddings behind an adapter, not before Stage 14 shows deterministic retrieval is insufficient |
| D21 Promotion mechanism | Curator opens a pull request; owner approval = merge; low-risk auto-merge gated by CI only after Stage 10 | Custom approval CLI/UI (rejected: second source of truth) |
| D22 Credential boundary | Owner Supabase Auth account + RLS; publishable key only on dev machines; token in OS keychain with 0600 file fallback; secret key only inside Edge Functions | Per-device ingestion tokens issued by an Edge Function (adopt if the owner token proves too broad) |
| D23 Remote/ephemeral sessions | Runtime detects `session_kind`; ephemeral sessions flush synchronously at terminal boundaries; fallback handoff bundle committed to the PR branch under `.ieos/telemetry/` | Rejected: "remote sessions are out of scope" — this is where most real runs happen |
| D24 Offline reads | Release artifact carries `knowledge.sqlite` (index) + `scores.snapshot.json`; live overlay when reachable; `resolve` reports `score_source` | Rejected: network-required resolve |
| D25 Agent Contract write side | Add `observe` (and run lifecycle via adapters); four tools total | Rejected: infer everything from traces |
| D26 Telemetry attribute registry | `contracts/telemetry-attributes.yaml` allowlist with type + sensitivity; exporter reconstructs events from it; envelope gains `installation_id`, `session_kind` | Rejected: denylist scanning as primary control |
| D27 Evidence staleness scope | Evidence bound to `repo_sha` + path scope + max age; stale only when scope touched or age exceeded | Rejected: any-commit staleness |
| D28 Taxonomy governance | `contracts/capabilities.yaml` seeded from this repo's `core/capability-registry.yaml`; additions only via promotion PR | Rejected: free-form tags |
| D29 EOS dependency policy | Exact pins + committed lockfile; weekly automated update PR; Context7 check noted in the PR; SBOM emitted per release | — |
| D30 Evidence Plane hosting | Supabase Pro (no pause, daily backups) **or** self-hosted Postgres; weekly `pg_dump` export to owner storage; restore drill each RC | Free plan (rejected: pauses, no backups) |

### D18 — Implementation stack and platforms (PROPOSED)

**D18.1 Language and runtime.** TypeScript, strict mode, Node 22 LTS, pnpm workspaces, ESM. Rationale: the official MCP SDK, `supabase-js`, Claude Code and Codex are all Node-based, so Node is already present on every machine that runs the agents. One language keeps the launcher, core and adapters testable with one toolchain.

**D18.2 Launcher.** Published as its own npm package (`@ieos/launcher`) with zero runtime dependencies beyond Node built-ins, invoked as `npx @ieos/launcher@<exact-version> <command>`. It downloads release artifacts, verifies digests, manages the version cache and never imports core packages. Fitness test F5 enforces the import boundary. If the Node assumption ever fails, the launcher is the only package to port.

**D18.3 Supported platforms (Stage 1 gate list).** Linux x64, macOS arm64, Windows 11 native (PowerShell), Windows WSL2. Rules that follow: no shell scripts in runtime paths (TypeScript only); `path.join` everywhere; `.gitattributes` with `* text=auto eol=lf` from the first commit; CI matrix on all four.

**D18.4 Generated project footprint.** `ieos init` writes exactly: `.ieos/installation.json` (pin + digest), `.ieos/profile.yaml` (`spec` only), an entry in `.mcp.json` (Claude Code) and `~/.codex/config.toml` guidance (Codex), and one generated paragraph in `AGENTS.md` and `CLAUDE.md` between `<!-- ieos:begin -->` / `<!-- ieos:end -->` markers. `ieos doctor` fails if the generated block differs from the template of the pinned release. Nothing else lands in the project.

**D18.5 Tooling.** `vitest` for tests, `eslint` + `prettier`, `zod` as the schema source of truth with JSON Schema exported to `contracts/` at build time, `better-sqlite3` for SQLite, `@modelcontextprotocol/sdk` pinned to a version that implements `2026-07-28`, Supabase CLI for migrations, `dependency-cruiser` for fitness rules.

### D19 — Identity and content addressing (PROPOSED)

- Every canonical object gets an opaque, immutable id: `asset_01J...` (ULID with type prefix). Slugs and titles are mutable metadata.
- `content_hash = sha256(canonical serialization of body + files)` is an addressing key, not a merge rule. The importer merges two assets only when their `content_hash` is equal **and** their recommendation-relevant metadata is equivalent (`type`, `problem.id`, `applicability`, `compatibility`, `risk`). Equal hash with different metadata yields a `related_to` link and a report entry, never a merge. A `failed_solution` is never merged with any other type, whatever its hash.
- `legacy_ids[]` records old Engineering-OS paths (for example `patterns/auth/oauth-pkce.md`) so provenance survives.
- Renames never change ids. Supersession is a relationship, never an overwrite.

### D20 — Asset storage layout and retrieval (PROPOSED)

**D20.1 Layout.** `knowledge/assets/<type>/<slug>/asset.yaml` (metadata, Section 5.1), `body.md` (the human/agent-readable content), optional `files/` (code, fixtures). `inspect` returns metadata + body; `resolve` returns metadata + `summary` only.

**D20.2 Index.** At release build time the knowledge tree is compiled into `knowledge.sqlite` (FTS5 over title/summary/tags/body, plus capability and solution-set tables). The runtime reads the index, never the tree. Rebuilding the index is deterministic (fitness test F8 diffs two builds).

**D20.3 Retrieval v1.** Deterministic ranking: (1) capability/problem match from Project Profile + task hints, (2) FTS5 BM25 score, (3) Project Fit filter, (4) Champion selection per Solution Set, (5) Asset Score tie-break. Embeddings are an optional `Retriever` adapter added only if Stage 14 shows deterministic recall is insufficient, and they never change contract semantics.

### D21 — Promotion is a pull request (PROPOSED)

The Curator materializes a Candidate as a branch in the canonical repo containing the proposed asset change plus `promotion.yaml` (evidence links, risk class, trust vector). CI validates schemas, fitness rules and evidence references. Owner approval is the merge. Low-risk categories (defined in `contracts/promotion-policy.yaml`, empty until Stage 10) may enable auto-merge after CI. Git history is the promotion audit log; no separate approval store.

### D22 — Credential boundary, concretized (PROPOSED)

1. One Supabase Auth user: the owner. Every table has `owner_id uuid not null default auth.uid()` and RLS policies `owner_id = auth.uid()` for select/insert; update/delete only where the domain allows.
2. Dev machines and agent containers hold only the project URL, the publishable key and the owner's refresh token, stored by the runtime in the OS keychain when available and otherwise in `~/.ieos/credentials.json` with mode `0600`. Remote environments receive the same three values as environment secrets.
3. The secret key exists only in Supabase Edge Functions (derivers, admin jobs) and in the owner's password manager. Fitness test F9 fails any commit containing a secret-shaped value or a privileged client outside `supabase/functions`.
4. Honest limit: an agent with shell access on the same machine can read the owner-scoped token. The boundary protects against admin/service-role authority and against other users' data, not against the agent reading the owner's own evidence rows. This is acceptable for D1 and must be stated in `SECURITY.md`.

### D23 — Remote and ephemeral sessions (PROPOSED)

- The runtime classifies each Run: `session_kind: local_persistent | remote_ephemeral | ci`. Detection: environment markers (Claude Code web/cloud variables, CI variables), overridable in the Run.
- `local_persistent`: SQLite outbox, background sync, as in the report.
- `remote_ephemeral`: outbox still used for batching, but every terminal boundary (`Stop`, `SessionEnd`, and every N minutes) flushes synchronously with a short timeout. Exit status of the terminal flush propagates (this repo's lesson: a soft-gated wrapper hid the failure).
- Fallback handoff bundle (only when the synchronous flush fails): unacknowledged events are written to `.ieos/telemetry/<run_id>/events.jsonl` plus `manifest.json` and committed to the working branch. The manifest carries `run_id`, `installation_id`, canonical `owner/repo`, branch, PR number when known, product head SHA, event count, last completed lifecycle boundary, and a SHA-256 over the event stream and over the manifest fields. CI validates the bundle before ingestion exactly as `lessons-learned/bugs/remote-workspace-telemetry-requires-durable-handoff.md` requires: strict UTF-8, schema allowlist, checksum match, manifest boundary equal to the boundary recomputed from events, repository identity, PR binding immutable per run, head equal to or an ancestor of the current head (bounded fetch before classifying ancestry), and monotonic event/boundary progress with incomparable progress failing closed. Only a validated bundle is ingested; CI then removes it from the branch. Because the bundle lives in a PR-controlled path, Evidence derived from it is marked `provenance.integrity: partial` unless the ingest function can also match it against a partial synchronous flush of the same run; Stage 5 tests must include an edited, a replayed and a removed bundle, each rejected or downgraded, never silently accepted.
- `ci`: direct ingestion with a CI-scoped token.
- Stage 5 gains a mandatory scenario: kill the container immediately after the last tool call, then prove the events arrive via one of the two paths.

### D24 — Offline reads (PROPOSED)

The release build queries the Evidence Plane and writes `scores.snapshot.json` (Asset Score, Champion state, evidence counts, `computed_at`, `scoring_policy_version`). The runtime overlays live values when the plane answers within a budget, otherwise uses the snapshot and marks `score_source: snapshot`. Fitness test F4 (core never reads raw telemetry) is unchanged.

### D25 — Agent Contract write side (PROPOSED)

Tools: `resolve`, `inspect`, `expand`, `observe`. `observe` accepts a typed Observation (`kind: asset_applied | asset_rejected | fact_seen | decision_recorded | lesson_candidate`, `subject`, `evidence_refs`, free text limited by the attribute registry). It writes to Observations only, never to canonical knowledge (fitness test F3). Run lifecycle (`run.begin`/`run.end`) is emitted by adapters, not by the agent.

### D26 — Telemetry attribute registry and envelope fields (PROPOSED)

- `contracts/telemetry-attributes.yaml`: every allowed attribute with `type`, `sensitivity: public | internal | never`, and `max_length`. The exporter and the ingestion function reconstruct events from this allowlist; unknown keys are dropped and counted.
- Envelope gains `installation_id` (stable per machine/container image), `session_kind`, and `source.sequence` becomes `(installation_id, source.type, sequence)`.
- Strict UTF-8 decoding before any scanning (lesson from this repo).

### D27 — Evidence staleness scope (PROPOSED)

Control evidence carries `scope: { paths: [globs], max_age_days }`. Evidence is `STALE` when a commit since `repo_sha` touched any path in scope, or `max_age_days` elapsed. Otherwise it is `VALID (revision drift)`. Controls declare their default scope; a Control without a scope is treated as whole-repository (loud, but explicit).

### D28 — Taxonomy governance (PROPOSED)

`contracts/capabilities.yaml` is versioned, seeded from `core/capability-registry.yaml` in this repository, and grows only via promotion PRs. A Solution Set is defined by `problem.id` + a compatibility key derived from `compatibility` fields. Two assets are "equivalent" only if both match; otherwise they are related, not competing.

### D29 — Dependency policy for EOS itself (PROPOSED)

Exact version pins, committed `pnpm-lock.yaml`, `pnpm install --frozen-lockfile` in CI, one weekly automated update PR, Context7 check recorded in the PR body for any new dependency, CycloneDX SBOM emitted with every release and referenced from the release manifest.

### D30 — Evidence Plane hosting (PROPOSED)

Supabase Pro (no inactivity pause, daily backups) or self-hosted Postgres with the same schema; the Free plan is not acceptable for the Evidence Plane. Independent of the plan: weekly `pg_dump` to owner-controlled storage, and a restore drill into a scratch project at every RC (Stage 17). If Supabase Storage is adopted for cold telemetry, its objects get a separate export job.

---

## 3. Target repository layout

Repository name: `Improved-Engineering-OS`. Monorepo, pnpm workspaces. Directories the agent must not create beyond this list without an ADR.

```text
Improved-Engineering-OS/
  ARCHITECTURE.md                 # the owner's report, citations fixed (TD-17)
  BUILD-GUIDE.md                  # this document
  SECURITY.md                     # threat model + D22.4 honest limit
  README.md                       # what/why/install/commands (kept current per stage)
  docs/
    adr/                          # ADR-0001..0017 from the report, ADR-0018+ from Section 2
    runbooks/                     # install, doctor, restore, rollback, backup drill, incident
    budgets.md                    # overhead baselines and versioned budgets (Section 7)
  contracts/                      # generated JSON Schema + hand-written YAML registries
    schemas/*.schema.json         # emitted from packages/core/src/contracts (zod)
    capabilities.yaml             # D28
    telemetry-attributes.yaml     # D26
    freshness-policy.yaml         # Stage 11
    promotion-policy.yaml         # D21, empty until Stage 10
    scoring-policy.yaml           # Stage 10
  packages/
    core/                         # domain model, contracts, pure logic; NO I/O, NO agent names
    store-sqlite/                 # outbox, local cache, knowledge index reader
    store-supabase/               # Evidence Plane client (owner-scoped), migrations live in supabase/
    resolver/                     # resolve/inspect/expand over the knowledge index
    curator/                      # observations -> candidates -> promotion PR
    telemetry/                    # envelope, sanitizer (allowlist), session_kind, flush strategies
    evidence/                     # derivers, attribution, investigation views
    assurance/                    # controls engine, applicability, staleness scope
    releases/                     # release manifest build, index build, score snapshot
    adapters/
      mcp/                        # MCP server exposing the Agent Contract (stateless per 2026-07-28)
      cli/                        # `ieos` command: same contract over a CLI
      claude-code/                # hooks/bootstrap templates for Claude Code
      codex/                      # config/bootstrap templates for Codex
    launcher/                     # @ieos/launcher, zero deps, never imports other packages
  knowledge/
    assets/<type>/<slug>/         # D20.1
    solution-sets/*.yaml
    controls/*.yaml
  supabase/
    migrations/                   # Supabase CLI migrations, versioned
    functions/                    # Edge Functions: ingest, derive, admin (secret key lives here only)
  simulations/
    manifests/*.yaml              # Simulation Manifests (public part)
    fixtures/                     # public fixtures
  evaluator/                      # hidden conditions, expected outputs, graders (TD-16)
                                  # NEVER copied into an agent sandbox; harness mounts it read-only outside the sandbox
  qualification/
    targets/*.yaml                # real target projects (Project 8, SportReel): paths, SHAs, rollback (TD-19)
    reports/                      # generated stage reports, one per stage run
  fitness/                        # architecture fitness tests (dependency-cruiser + custom)
  tools/
    import-legacy/                # Stage 2 importer from the old Engineering-OS checkout
    harness/                      # simulation runner: sandbox, agent drivers, graders, artifact collection
  .github/workflows/              # ci.yml (matrix), fitness.yml, release.yml, weekly-deps.yml
```

Package dependency direction (enforced by `fitness/` from Stage 0):

```text
launcher  -> (nothing)
core      -> (nothing)
store-*   -> core
resolver  -> core, store-sqlite
telemetry -> core, store-sqlite, store-supabase
evidence  -> core, store-supabase
assurance -> core, evidence
curator   -> core, evidence, store-supabase
releases  -> core, resolver, evidence
adapters/* -> core, resolver, telemetry, assurance   (never each other, never store-supabase directly)
```

---

## 4. Stage-by-stage build plan

Conventions for every stage:

- **Deliverables** are paths. If a path is not listed, ask before creating it.
- **Exit gate** is the report's ten-row gate table plus the stage-specific rows below. A stage is closed by a report in `qualification/reports/stage-NN-<date>.md` produced by the harness, not by hand.
- Work on stage N+1 may start while stage N's report is pending; **promotion** of anything from stage N+1 into a release may not.
- Every stage ends with README and runbook updates in the same PR.

### Stage 0 — Contracts + Simulation Harness

**Goal.** Schemas, identities and the harness are trustworthy enough to build on.

**Deliverables.**

- `packages/core/src/contracts/{asset,project-profile,telemetry,evidence,control,simulation,release,agent-contract}.ts` — zod schemas with `schema_version`, `stability`, `introduced_in`, `deprecated_in`, `replacement`, `migration_path` on every top-level contract. Build step emits `contracts/schemas/*.schema.json`.
- `packages/core/src/ids.ts` — ULID minting with type prefixes, `content_hash`, `legacy_ids` (D19).
- `contracts/capabilities.yaml` seeded from the old repo's `core/capability-registry.yaml` (D28); `contracts/telemetry-attributes.yaml` with the initial allowlist (D26).
- `docs/adr/ADR-0001..0017.md` (one per report decision, status `accepted`) and `ADR-0018..0030.md` (status `proposed` or `accepted` per the owner's answers to Section 2.0).
- `tools/harness/`: `sandbox.ts` (fresh temp dir per trial, no inherited env, no `evaluator/` inside), `drivers/{claude-code,codex}.ts` (headless invocations: `claude -p` / Agent SDK, `codex exec`), `graders/{deterministic,trace,model}.ts`, `collect.ts` (artifact bundle per trial), `report.ts` (stage report writer), `budget.ts` (tokens, wall-clock, tool calls per trial).
- `fitness/` with rules F1–F10 (below), wired into `.github/workflows/fitness.yml`.
- `docs/budgets.md` with an empty baseline table and the measurement method (the numbers come at Stage 8 and 14).
- Repo scaffolding: `.gitattributes` (`* text=auto eol=lf`), `.editorconfig`, `pnpm-workspace.yaml`, CI matrix on the four platforms (D18.3), `SECURITY.md` skeleton.

**Fitness rules (F1–F10), all executable at Stage 0 even if some packages are empty.**

| ID | Invariant | Mechanism |
|---|---|---|
| F1 | `packages/core` contains no `claude`, `codex`, `anthropic`, `openai` identifiers and imports nothing outside itself | dependency-cruiser + grep rule |
| F2 | adapters never own knowledge semantics: no file under `adapters/` imports `knowledge/` or defines ranking | dependency-cruiser |
| F3 | nothing under `packages/` writes into `knowledge/` at runtime; only `curator` produces branches | filesystem-write guard in tests + grep for `knowledge/` writes |
| F4 | `resolver` and Asset Score code never import raw telemetry types | dependency-cruiser |
| F5 | `launcher` imports only Node built-ins | dependency-cruiser + `package.json` dependency count = 0 |
| F6 | no real target-project names or absolute project paths in runtime or configuration paths (`packages/`, `contracts/`, `knowledge/`, `supabase/`, `simulations/`, `fitness/`, `tools/`, `.github/`); documentation (`docs/`, `*.md` at the root) and `qualification/` are excluded | grep rule with an explicit path scope and a committed exclusion list |
| F7 | runtime never resolves `latest`: release resolution requires an exact version + digest | unit test on launcher |
| F8 | knowledge index build is deterministic | build twice, compare hashes |
| F9 | no key-shaped secret values anywhere in the repo (pattern match on `sb_secret_[A-Za-z0-9]{20,}`, JWT-shaped strings and similar), and no `service_role` / secret-key client construction in runtime paths (`packages/`, `supabase/functions` excepted for the admin role); the identifier words themselves are allowed in documentation and in negative test fixtures listed in `fitness/allowlist.yaml` | secret-value scan in CI and pre-commit + scoped grep for privileged client construction |
| F10 | every Simulation Manifest references an evaluator entry that exists and is outside `simulations/` | manifest linter |

**Tests and simulations.** Contract property tests (valid accepted, invalid rejected with reason, unknown enum tolerated where declared, migration fixtures deterministic). Harness self-test: two trials cannot see each other's state; a trial that references a non-existent Run is rejected. Grader validity: each grader has positive, negative and mutation controls.

**Exit gate additions.** F1–F10 green on CI matrix; `contracts/schemas/` regenerated with no diff; a corrupted Evidence fixture referencing a missing Run is rejected; ADRs exist for all 30 decisions.

**Debt watch.** Do not add a UI, embeddings, or a daemon here. Do not put Supabase code here.

### Stage 1 — Runtime, Releases & Recovery

**Goal.** A project can be pinned, restored, upgraded and rolled back without drift, on all four platforms.

**Deliverables.**

- `packages/launcher`: commands `install`, `doctor`, `restore`, `update`, `rollback`, `which`. Version cache at `~/.ieos/releases/<version>/` with `manifest.json` + digest verification before activation; transaction-like activation (download → verify → stage → atomic symlink/junction swap → post-check → commit or revert).
- `packages/releases`: release manifest builder (`version`, `tag`, `source_commit`, `artifact_digest`, `sbom_ref`, `attestation_ref?`, `contracts_versions`, `index_digest`, `scores_snapshot_digest`).
- `.github/workflows/release.yml`: builds the artifact, emits SBOM, publishes an immutable GitHub release, attaches provenance attestation where the plan supports it.
- `docs/runbooks/{install,doctor,restore,rollback}.md`.
- `.ieos/installation.json` schema and generator (`ieos init`) with the generated bootstrap block (D18.4).

**Simulations.** The report's Stage 1 manifest plus: two projects on different versions on one machine; kill during `update`; corrupt cache file; manifest pointing at a different version than the tag; offline restore from cache; Windows path with spaces.

**Exit gate additions.** All scenarios pass on all four platforms; tampered artifact never activates; `doctor` names the fault; rollback restores exact previous digest.

### Stage 2 — Existing Engineering-OS Asset Import

**Goal.** Start from the existing knowledge without importing the old architecture.

**Deliverables.**

- `tools/import-legacy/`: reads a checkout of the old repository (Appendix A), classifies each file into an asset type or an exclusion, mints ids, records `legacy_ids`, computes `content_hash`, groups duplicates into Solution Sets without choosing a Champion, writes `knowledge/assets/...` and `knowledge/solution-sets/...`, and emits `qualification/reports/import-<date>.md` (inventory before/after, mapping table, duplicate groups, exclusions with reasons, items needing manual classification).
- Idempotent: re-running over the same input produces no diff.

**Simulations.** Full import; import twice; three near-duplicate auth patterns resolve to one Solution Set with two duplicates and one distinct-context asset; a failed solution is imported with `type: failed_solution` and can never be returned as a recommendation (unit test on resolver later reuses this fixture).

**Exit gate additions.** Every file in Appendix A's include list is accounted for (imported, merged, or excluded with reason); zero old workflow policies became runtime rules; provenance `integrity: unknown` is used where the source cannot be tied to a revision, never fabricated.

### Stage 3 — Project Profile & Onboarding

**Goal.** EOS understands a project incrementally and never guesses.

**Deliverables.**

- `packages/core/src/profile/` — `spec` schema, `status` observation schema, drift comparison (`ALIGNED | DRIFT | UNKNOWN`).
- `packages/assurance/src/probes/` — deterministic probes: package manager, frameworks, database providers (config files, env names, migrations dirs), CI presence, deployment workflows, test runners, lifecycle hints. Each probe returns `{fact, value, provenance, confidence}`; nothing is inferred without a provenance.
- `ieos profile {show,scan,ask}`: `ask` lists only consequential `UNKNOWN`s and records answers as `spec` + ADR stubs in the target project.

**Simulations.** Report's Stage 3 manifest plus: declared Supabase with a live Firebase config → `DRIFT`; `production=false` with a deploy workflow → `DRIFT`; repeated onboarding on an unchanged repo asks zero questions.

**Exit gate additions.** Question count is recorded per trial and is zero on re-onboarding; `status` is never written into the project's Git.

### Stage 4 — Knowledge Registry + Resolver (CLI only)

**Goal.** Find a few correct assets from a meaningful corpus.

**Deliverables.**

- `packages/releases/src/build-index.ts` → `knowledge.sqlite` (D20.2).
- `packages/resolver`: `resolve(request) → {items[≤N], champion_per_set, omitted_count, score_source}`, `inspect(id) → {metadata, body, evidence_summary}`, `expand(request) → wider search with explicit reason`. Progressive disclosure sizes are configuration, not code.
- `simulations/fixtures/task-bank/` — labeled tasks (task text, Project Profile, expected critical asset ids, deliberate near-miss ids). Seed the labels from Stage 2's mapping (each imported asset's problem id), then hand-verify a holdout subset that is stored under `evaluator/`.
- `ieos resolve|inspect|expand` CLI.

**Simulations.** Regression bank + holdout; metrics: critical recall, precision, returned bytes, latency; failure cases: full-catalog dump, failed solution recommended, two Champions in one set.

**Exit gate additions.** Targets are set *before* the run in the manifest (provisional numbers, Section 7 item 8); the same task through the CLI twice returns identical ids (determinism).

### Stage 5 — Telemetry Foundation

**Goal.** Events survive failures without leaking content or duplicating.

**Deliverables.**

- `packages/telemetry`: envelope (Section 5.3), sanitizer that reconstructs from `telemetry-attributes.yaml`, strict UTF-8 gate, `session_kind` detection (D23), flush strategies (`background`, `boundary_sync`, `handoff_bundle`), idempotent batch upload keyed by `event_id`.
- `packages/store-sqlite`: outbox with per-writer temp files and atomic replace; delete only after durable acknowledgement.
- `supabase/migrations/0001_telemetry.sql`: `raw_events` (append-only, unique `event_id`, `owner_id`, RLS), `runs`, `work_items`, `installations`. `supabase/functions/ingest/`: validates against the allowlist server-side too, returns acknowledged ids.
- Owner decision recorded: D30 plan tier; `docs/runbooks/backup-and-restore.md` with the weekly export job.
- Adapter hooks: `adapters/claude-code` (SessionStart/PostToolUse/Stop/SessionEnd emitters, failure-propagating terminal boundary), `adapters/codex` (equivalent where the harness allows; otherwise CLI wrapper emitting the same events).

**Simulations.** Report's Stage 5 manifest plus the D23 scenario: container killed right after the last tool call, in `remote_ephemeral` mode, events arrive through sync flush or handoff bundle; `local_persistent` with Supabase down for one hour then recovered; secret-like value in an allowed attribute is rejected at both client and ingest function.

**Exit gate additions.** Coding is never blocked by remote telemetry outage; terminal-boundary failure is visible (non-zero) in `required` mode; the export contains only allowlisted keys (test asserts absence of sentinel values in the serialized bundle).

### Stage 6 — Evidence + Investigation

**Goal.** Raw telemetry becomes explainable Evidence and reliable investigation.

**Deliverables.**

- `packages/evidence`: versioned derivers (`deriver_version` in every Evidence row), attribution levels `EXPOSED | INSPECTED | APPLIED | DIRECTLY_VERIFIED | FAILED`, `origin_class`, `independence_group`, staleness scope (D27), late-CI reclassification, rework/recurrence detection, failure taxonomy.
- `supabase/migrations/0002_evidence.sql`, `supabase/functions/derive/` (runs derivers server-side with the secret key; idempotent per `(run_id, deriver_version)`).
- `ieos investigate <run_id|work_id>` producing a Markdown timeline with source event ids; no custom dashboard.

**Simulations.** Golden traces with ground-truth timelines; CI failure a day later reclassifies evidence for the same revision; asset merely displayed never gets `APPLIED`; timestamp-only ordering is rejected when trace links say otherwise.

**Exit gate additions.** Replay of raw events with the same `deriver_version` reproduces identical Evidence rows (hash compare).

### Stage 7 — Agent Contract + Adapters

**Goal.** Same semantics over MCP and CLI; adapters stay thin.

**Deliverables.**

- `adapters/mcp`: stateless server (per MCP `2026-07-28`: no per-connection state; handles in arguments; discovery RPC advertising versions; caching hints), exposing `resolve`, `inspect`, `expand`, `observe`.
- `adapters/cli`: same four operations, same JSON output.
- Capability snapshot at run start: integrations advertised vs. authorized vs. healthy, recorded in Run metadata, never granting permission.
- Contract conformance suite executed against both transports with the same fixtures.

**Simulations.** Report's Stage 7 manifest plus: MCP server dies mid-run → CLI fallback produces the same object; an integration advertised but unauthorized is reported as `AVAILABLE, NOT AUTHORIZED` and never used.

**Exit gate additions.** Semantic parity diff is empty; no code path branches on agent name (F1 extended to adapters' shared code).

### Stage 8 — First Real Agent Vertical Slice

**Goal.** A real agent uses EOS naturally end to end.

**Clarified hidden condition (replaces the report's wording).** The target repo contains the generated bootstrap block (D18.4), which states that EOS tools exist and what they are for. It contains no task-specific hints, no asset names, and no instruction to call any tool for this task.

**Deliverables.** `simulations/manifests/stage-08-*.yaml`; harness drivers proven for the primary agent; `docs/budgets.md` baseline filled from these trials (tokens, tool calls, wall-clock, resolve latency, context bytes).

**Simulations.** Several independent tasks on a disposable realistic repo, one requiring a lesson imported at Stage 2; one misleading clue; a test failure mid-task.

**Exit gate additions.** No rescue; telemetry → evidence → investigation complete for every trial; baseline table committed. **If the slice is not natural, stop and simplify before Stage 9.**

### Stage 9 — Adaptive Assurance

**Deliverables.** `packages/assurance`: Control schema (Section 5.5), applicability rules from Project Profile, states `SATISFIED | MISSING | UNKNOWN | EXEMPT | STALE`, scoped staleness (D27), expiring exemptions with `decision_id`, fail-closed only for Controls marked `critical: true`. Initial Controls seeded from the old repo's quality gates (Appendix A) but re-expressed as conditional controls, not workflow steps.

**Simulations.** Report's Stage 9 manifest plus: a commit outside a Control's scope does not stale it; a commit inside does; exemption past expiry returns to `MISSING`.

**Exit gate additions.** Prototype-lifecycle project surfaces zero production Controls; critical Control with unverifiable evidence blocks only the destructive action, not coding.

### Stage 10 — Learning, Asset Scores & Canonicalization

**Deliverables.** `contracts/scoring-policy.yaml` (priors, weights, decay, independence discount, quarantine rule; versioned), `packages/evidence/src/score.ts` (deterministic, replayable), `packages/curator` (observations → candidates → promotion PR per D21), `contracts/promotion-policy.yaml` (initially: everything requires owner merge), `packages/releases/src/scores-snapshot.ts` (D24).

**Simulations.** 500 correlated repeats are discounted; one critical failure quarantines; Champion changes only after independent holdout evidence; two Champions in one set is impossible (unit test on the invariant).

**Exit gate additions.** Score explanation lists every contributing Evidence id; recompute under the previous policy version reproduces the previous score.

### Stage 11 — External Ecosystem

**Deliverables.** `contracts/freshness-policy.yaml` (classes, TTLs per fact type, provisional); provider/integration asset types with trust vectors; discovery adapters (MCP registry, official docs) producing Observations only; live overlay API (`verify(fact) → {value, source, retrieved_at, freshness}`); runtime health/authorization snapshot.

**Simulations.** Stale pricing during an architecture decision → live verification, baseline untouched; registry entry with weak security evidence → candidate, never auto-installed; provider deprecation → Observation.

**Exit gate additions.** No code path installs anything; the overlay never writes to `knowledge/`.

### Stage 12 — Multi-Agent & Capability Dynamics

**Deliverables.** Codex driver at parity in the harness; handoff of a Work Item between agents preserving Run lineage; concurrency test on the outbox and the Evidence Plane; capability negotiation for an unknown capability (`UNKNOWN`, not error).

**Exit gate additions.** Both agents complete the same Work Item via different integrations with no core change; no history loss across handoff.

### Stage 13 — Resilience, Security & Scale

**Deliverables.** Fault-injection suite in `tools/harness/faults/` (Supabase outage, SQLite lock, full disk, tampered release, prompt-injection fixtures in external content, concurrent runs); synthetic scale generator (100k assets, 10k controls, 1M events) used as a stress margin only; provisional budgets from `docs/budgets.md` enforced as thresholds in this suite.

**Exit gate additions.** External content never gains instruction authority (grader checks the agent did not execute injected instructions); release mismatch blocked; no corruption under concurrency.

### Stage 14 — Native vs Assisted, Ablation & Shadow

**Deliverables.** Paired-trial runner (same model, task, tools, budget); ablation switches per subsystem (Skills, Assurance, history, resolver); shadow mode for a candidate resolver/scoring version; vector dashboard as a generated Markdown/CSV report (no custom UI).

**Exit gate additions.** No critical regression on any vector dimension; a subsystem with no measurable benefit is listed as a removal candidate in the stage report.

### Stage 15 — Project 8 Canary

**Deliverables.** `qualification/targets/project-8.yaml` (repo, baseline SHA, test command, rollback procedure, telemetry mode `required`); at least two materially different bounded tasks; full evidence chain per task.

**Preconditions (from this repository's Project 8 findings).** Install the pinned candidate in the exact workspace that will run the agent, start a fresh session afterwards, run `ieos doctor` and confirm `telemetry: ready` with a positive event count *before* the task. Never mark this stage from CI artifacts alone.

### Stage 16 — Cross-Project Qualification

**Deliverables.** `qualification/targets/sportreel.yaml` (or another materially different archetype); same release; report of config delta and any core change requested (a core change here is a failure of D2/D13, not a task).

### Stage 17 — RC → Stable

**Deliverables.** `1.0.0-rc.N` artifact through Development → Simulation → Shadow → Canary → Cross-project → RC → Stable rings; restore drill of the Evidence Plane into a scratch project (D30); rollback proof from RC to previous stable on a real installation.

**Exit gate additions.** Artifact digest equals the tested digest; SBOM and attestation (where available) verified by the launcher, not only present; a failed canary holds promotion automatically.

### Continuous evolution

After Stable: weekly dependency PR (D29), monthly Champion challenge run (Stage 10 suite), native-vs-assisted rerun on every major model change (Stage 14), removal PRs for subsystems that lost their benefit.

---

## 5. Contracts (refined baselines)

These refine the report's conceptual schemas with the fields added by Section 2. They are the source for the zod definitions at Stage 0; every contract keeps the lifecycle block:

```yaml
schema_version: "1"
stability: development        # development | stable | deprecated | removed
introduced_in: "0.1.0"
deprecated_in: null
replacement: null
migration_path: null
```

### 5.1 Asset (`knowledge/assets/<type>/<slug>/asset.yaml`)

```yaml
id: "asset_01J9Z6Q0K3N6X4R8V2T7M5B1WQ"      # ULID, immutable (D19)
type: "pattern"                             # pattern | skill | template | reference_test | reference_repo | lesson | failed_solution | provider | integration | fact | control_guidance
slug: "oauth-pkce-web"                      # mutable
title: "OAuth 2.1 PKCE for browser apps"
summary: "≤ 400 chars, what `resolve` returns"
status: "candidate"                         # candidate | active | superseded | quarantined | deprecated
content_hash: "sha256:…"                    # over body.md + files/ (D19)
legacy_ids: ["patterns/auth/oauth-pkce.md"]
problem: { id: "problem.auth.browser-login", capabilities: ["auth.oauth.pkce"] }
solution_set_id: "solset_01J…"
applicability: { conditions: [ { fact: "platform", in: ["web"] } ] }
compatibility: { platforms: ["web"], providers: ["auth0", "supabase-auth"], constraints: [] }
provenance:
  - { source_type: "existing_eos", source_identity: "yotamfried-ux/Engineering-OS", source_revision: "<sha>", observed_at: "…", integrity: "verified" }
freshness: { class: "normal", last_verified_at: "…" }
risk: { execution_authority: "data_only", blast_radius: "read_only" }
relationships: { supersedes: [], superseded_by: [], related_to: [] }
evidence_policy: { eligible_origins: ["qualification", "operational", "holdout"] }
body: "body.md"
files: []
```

Champion is never a field here; it is derived from the Solution Set, `scoring-policy.yaml` and Evidence (D7).

### 5.2 Project Profile (`.ieos/profile.yaml` in the target project)

```yaml
schema_version: "1"
project_id: "proj_01J…"
eos: { pinned_release: "1.0.0", release_digest: "sha256:…" }
spec:
  lifecycle: "prototype"                    # prototype | internal | production
  database_provider: "supabase"
  authentication_required: true
  deployment: "vercel"
  architecture_constraints: []
decisions: [ { decision_id: "ADR-0003", subject: "database_provider", status: "accepted" } ]
known_unknowns: ["production_user_count"]
# status/observed lives in the Evidence Plane; drift = compare(spec, status)
```

### 5.3 Telemetry envelope

```yaml
schema_version: "1"
event_id: "evt_01J…"                        # idempotency key
event_type: "tool.call"                     # closed enum, versioned
project_id: "proj_…"
work_id: "work_…"
run_id: "run_…"
installation_id: "inst_…"                   # D26
session_kind: "remote_ephemeral"            # local_persistent | remote_ephemeral | ci (D23)
trace: { trace_id: "…", span_id: "…", parent_span_id: null, links: [] }
time: { occurred_at: "…", observed_at: "…", ingested_at: null }
source: { type: "agent", sequence: 42 }     # unique with (installation_id, source.type)
revision: { repo_sha: "…", eos_release: "1.0.0" }
harness: { agent: "claude-code", model: "…", adapter_version: "…", available_capabilities_hash: "…" }
attributes: {}                              # only keys present in contracts/telemetry-attributes.yaml
```

### 5.4 Evidence

```yaml
schema_version: "1"
evidence_id: "evd_01J…"
subject: { type: "asset", id: "asset_…" }
kind: "success"                             # success | failure | partial | verification | rework
origin_class: "operational"                 # development | qualification | operational | holdout | external_attestation
independence_group: "ig_…"
strength: { polarity: "positive", weight: 0.0, confidence: 0.0 }
attribution: { exposure: "applied", source_event_ids: ["evt_…"], trace_id: "…" }
revision: { repo_sha: "…", deriver_version: "…" }
scope: { paths: ["src/auth/**"], max_age_days: 90 }   # D27
lifecycle: { created_at: "…", expires_at: null }
```

### 5.5 Control

```yaml
schema_version: "1"
id: "ctl_01J…"
title: "Auth code paths have a security test"
critical: false                             # only critical controls may fail closed
applies_when: [ { fact: "authentication_required", eq: true }, { fact: "lifecycle", in: ["internal", "production"] } ]
satisfied_by: [ { evidence_kind: "verification", subject_type: "control", min_confidence: 0.8 } ]
default_scope: { paths: ["src/auth/**"], max_age_days: 90 }
exemption: { allowed: true, max_days: 30, requires_decision: true }
```

### 5.6 Agent Contract (identical over MCP and CLI)

```text
resolve(request: { task_hint, project_id, run_id, limit?, include_controls? })
  → { items: [{ id, type, title, summary, project_fit, champion_of?, score, score_source }], omitted_count, controls: [...] }

inspect(request: { id, run_id })
  → { asset (5.1 metadata), body, evidence_summary, challengers: [{ id, title, why_not_champion }] }

expand(request: { task_hint, project_id, run_id, reason, beyond: "solution_set" | "type" | "corpus" })
  → same shape as resolve, plus { expansion_reason }

observe(request: { run_id, kind, subject, evidence_refs?, note? })
  → { observation_id, status: "recorded" }      # never touches canonical knowledge
```

### 5.7 Release manifest

```yaml
schema_version: "1"
version: "1.0.0"
tag: "v1.0.0"
source_commit: "…"
artifact_digest: "sha256:…"
index_digest: "sha256:…"                    # knowledge.sqlite
scores_snapshot_digest: "sha256:…"          # D24
sbom_ref: "…"                               # D29
attestation_ref: null                       # when the platform supports it
contracts: { asset: "1", project_profile: "1", telemetry: "1", evidence: "1", control: "1", simulation: "1", agent_contract: "1" }
```

### 5.8 Installation manifest (`.ieos/installation.json`)

```json
{ "schema_version": "1", "release": "1.0.0", "artifact_digest": "sha256:…", "bootstrap_template_hash": "sha256:…", "installed_at": "…", "installation_id": "inst_…" }
```

---

## 6. Working conventions for the coding agent

### 6.1 Kickoff instruction (paste into the first session of the new repository)

```text
You are building Improved-Engineering-OS. Read ARCHITECTURE.md (constitution) and BUILD-GUIDE.md fully.
Rules:
1. Work stage by stage in the order of BUILD-GUIDE.md Section 4. Do not start deliverables of a later
   stage before the current stage's report exists in qualification/reports/, except tests and contracts.
2. Section 2.0 decisions are accepted unless the owner changed the row. Record each in docs/adr/.
3. Every deliverable is a listed path. Ask before creating any directory not in Section 3.
4. Never write into knowledge/ from runtime code. Never store or read sb_secret_/service_role anywhere.
5. Unknown is UNKNOWN. Do not infer success. Do not change success criteria after a failure; revise the
   manifest and keep the old failure.
6. Before adding a dependency: check current docs (Context7), pin exactly, note it in the PR body.
7. Every PR: fitness green, tests green on the CI matrix, README/runbook updated in the same PR.
8. Stop and report when: a fitness rule must be relaxed, a stage gate cannot be met without changing the
   architecture, a real target project is needed, or a credential/plan decision is required.
Start with Stage 0.
```

### 6.2 Branch, commit and PR flow

- `main` is release-only. One branch per stage slice: `stage-NN/<topic>`.
- Commits: Conventional Commits (`feat(resolver): …`, `test(harness): …`) plus a trailer `Evidence: <test command or report path>`. Enforced by CI lint, not by a blocking local hook (the new system does not police workflow; it does verify).
- PR body sections: `What`, `Why (ADR/stage)`, `Evidence` (commands and results), `Contracts touched`, `Debt watch` (anything deliberately deferred, with the Section 7 item it maps to).
- Merge only when fitness, matrix CI and the stage-relevant simulation job are green and the owner approved.

### 6.3 Definition of Done per PR

- Tests for new behavior, including at least one negative case.
- Fitness F1–F10 green.
- Contracts regenerated; `contracts/schemas/` has no uncommitted diff.
- README and runbooks reflect any new command or behavior.
- No placeholder markers, no commented-out code, no `latest` anywhere in runtime paths.

### 6.4 Never list

- Never bypass a failing simulation by editing its criteria in the same PR.
- Never copy code from the old Engineering-OS `scripts/` into `packages/` (reference only; see Appendix A).
- Never hard-code an agent, model, provider, or project name in `packages/core`.
- Never add a UI, a daemon, embeddings, or a marketplace before the stage that justifies it.
- Never skip the four-platform matrix for "quick" changes to launcher or telemetry.

---

## 7. Open parameters register

Numbers here are provisional until the named stage produces a baseline. Each becomes a versioned entry in the relevant `contracts/*-policy.yaml` or `docs/budgets.md` with the reason for every change.

| # | Parameter | Provisional value | Decided at | From what data |
|---|---|---|---|---|
| 1 | Raw telemetry retention / cold storage | keep all until Stage 13 | Stage 13 | measured growth per run |
| 2 | Evidence Plane RPO / RTO | RPO 24h (daily backup), RTO 1 working day | Stage 17 restore drill | drill timing |
| 3 | Asset Score prior, weights, decay | uniform prior, no decay | Stage 10 | evidence distribution from Stages 8–9 |
| 4 | Minimum independent evidence for Champion | 3 independence groups | Stage 10 | Champion challenge runs |
| 5 | Champion replacement margin | not set | Stage 10 | same |
| 6 | Freshness TTLs per class | stable 180d, normal 60d, volatile 7d, live_required 0 | Stage 11 | verification hit/miss log |
| 7 | Auto-mergeable promotion categories | none | Stage 10+ | promotion history |
| 8 | Resolve latency / context budget | ≤ 1.5 s, ≤ 6 KB per resolve (provisional target for Stage 4 manifest) | Stage 8 | trial measurements |
| 9 | Agent trial budget per simulation | set per manifest; harness aborts at 2× | Stage 8 | trial cost |
| 10 | Trials and stopping rules per eval class | deterministic: 1; stochastic: 5 minimum | Stage 8 | observed variance |
| 11 | Release bake duration / ring thresholds | not set | Stage 17 | canary history |
| 12 | Reproducibility-critical Evidence retention | indefinite | Stage 13 | storage cost |
| 13 | Scale thresholds | 100k / 10k / 1M as stress margin only | Stage 13 | measured usage |
| 14 | Owner Defaults scope | none | after Stage 16 | repeated per-project config |
| 15 | Supabase plan | Pro or self-hosted (D30) | Stage 5 | owner decision |

---

## Appendix A — Import map from the current Engineering-OS repository

Computed on the current checkout of `yotamfried-ux/Engineering-OS`; the importer recomputes counts at run time and must not trust these numbers.

| Source path | Approx. size | Import as | Notes |
|---|---|---|---|
| `patterns/<domain>/**/*.md` + `patterns/registry.yaml` | 88 registry entries, 28 pattern README documents across 21 domains | `pattern` assets; registry `status/score/used_in` become provenance notes, never scores | All entries are `candidate`/`null` in the registry; import them as `candidate` with `evidence_policy` open. Group by `problem.id`. |
| `templates/<type>/` | 27 template directories | `template` assets | `templates/hooks`, `templates/settings`, `templates/commands`, `templates/bypass-control-plane` are old-runtime artifacts: exclude or import as `lesson` references only. |
| `external-systems/<service>/` | 49 service directories | `provider` assets (+ `integration` where the README documents a connector) | `external-systems/connectors/` maps to `integration`. |
| `external-skills/<skill>/` | 10 skills | `skill` assets, `risk.execution_authority: executable` | Mandatory-activation rules in their SIP files are governance, not knowledge: strip. |
| `docs/architecture-guides/`, `docs/frameworks/`, `docs/api-design/`, `docs/ui-ux/`, `docs/troubleshooting/` | part of 125 docs files | `pattern` or `fact` assets by content | Troubleshooting entries map well to `lesson`. |
| `docs/official-docs/`, `docs/reference-repositories/`, `docs/api-references/` | — | `fact` / `reference_repo` assets with `freshness.class: volatile` | Live verification applies (Stage 11). |
| `lessons-learned/bugs/*.md` | 19 lessons | `lesson` assets | Several are directly relevant to the new build (telemetry handoff, evidence keyed on mechanism, unit-vs-wiring); tag them `applies_to: ieos`. |
| `lessons-learned/postmortems/*.md`, `prevention-strategies/*.md` | 2 + 1 | `lesson` | The experiment-1 postmortem documents *why* the old system chose hook policing; import as history, not as a rule. |
| `failed-solutions/*.md` | 1 | `failed_solution` | Must never be returned by `resolve` (Stage 2 fixture). |
| `architecture-decisions/ADR-*.md` | 2 | `fact` (decision records) | Provenance only. |
| `core/capability-registry.yaml` | — | seed for `contracts/capabilities.yaml` (D28) | Keep ids; drop enforcement fields. |
| `core/quality-gates.md`, `core/debugging-policy.md`, `core/learning-loop.md` | — | source material for Stage 9 Controls and Stage 6 derivers | Re-express as conditional Controls; do not import as workflow. |
| `evals/engineering-os/*.jsonl` | 1 file | seed cases for `simulations/fixtures/` | Adversarial bank candidates. |
| `docs/operations/*.md`, `docs/research/*.md` | 27 + 2 | **exclude** (old-runtime runbooks) except `project8-first-real-run-findings.md` → `lesson` | |
| `scripts/**`, `.claude/**`, `.github/**`, `telemetry-archive/`, `.checkpoints/`, `graphify-out/`, `experiments/` | — | **exclude** | Old implementation; reference reading only (D16). Specific privacy/allowlist and atomic-write lessons are already captured as lessons above. |
| `CLAUDE.md`, `CLAUDE.template.md`, `core/workflow.md`, `core/task-router.md`, `core/hooks-policy.md`, `core/precedence.md`, `core/coderabbit-policy.md`, `core/skill-orchestration-policy.md` | — | **exclude** as rules; import one `lesson` summarizing the governance-overhead retrospective | This is the "old governance" the report explicitly does not inherit. |

Importer output requirements: inventory before/after, mapping table (`legacy_id → asset id`), duplicate groups with `content_hash`, exclusions with reasons, and a list of files needing manual classification (expected to be small; each manual decision is logged).

## Appendix B — External facts: verification status

| Claim in the report | Status in this review | Source |
|---|---|---|
| MCP `2026-07-28` moved to a stateless core, removed the initialization handshake, requires a discovery RPC | Verified (Context7) | https://modelcontextprotocol.io/specification/2026-07-28/changelog |
| Protocol-level sessions removed from Streamable HTTP; explicit handles for cross-call state; SSE resumability removed | Verified (Context7) | same changelog |
| Caching utility alongside change notifications | Verified (Context7) | https://modelcontextprotocol.io/specification/2026-07-28/server/utilities/caching |
| HTTP+SSE transport deprecated | Verified (Context7) | https://modelcontextprotocol.io/specification/2026-07-28/deprecated |
| Supabase publishable/secret keys replace anon/service_role; legacy keys deprecated by end of 2026; secret key bypasses RLS | Verified (Context7) | https://supabase.com/docs/guides/getting-started/migrating-to-new-api-keys |
| Database backups exclude Storage objects | Verified (Context7) | https://supabase.com/docs/guides/platform/backups |
| Free plan pauses after 7 idle days, no downloadable backups; Pro has daily backups | Verified (Context7), added by this review | https://supabase.com/docs/guides/deployment/going-into-prod |
| GitHub Immutable Releases lock tag and assets; attestations must be verified | Not re-verified in this session | agent must fetch GitHub docs before Stage 1 release workflow |
| MCP Registry is in preview; security scanning delegated | Not re-verified in this session | agent must fetch before Stage 11 |
| OpenAI Evals platform read-only 31 Oct 2026, shutdown 30 Nov 2026 | Not re-verified in this session | informational only; no dependency planned |
| Anthropic deferred tool loading; remote MCP trust warning | Not re-verified in this session | informational; consistent with D13 |
| SWE-Bench Pro audit percentages | Not re-verified in this session | informational; motivates grader controls |
| NIST SSDF framing | Not re-verified in this session | informational |

## Appendix C — Glossary additions

| Term | Definition |
|---|---|
| Installation | One machine or container image running an EOS release; identified by `installation_id`. |
| Session kind | `local_persistent`, `remote_ephemeral`, or `ci`; selects the telemetry flush strategy. |
| Handoff bundle | JSONL file of unacknowledged events committed to the working branch by an ephemeral session and imported by CI. |
| Score snapshot | Release-time export of Asset Scores and Champion state used when the Evidence Plane is unreachable. |
| Staleness scope | Path globs and max age that bound when a piece of Evidence stops being valid. |
| Fitness rule | An executable architectural invariant (F1–F10) that runs on every PR. |
| Stage report | Harness-generated Markdown in `qualification/reports/` that closes a stage; the only artifact that may claim a gate passed. |
