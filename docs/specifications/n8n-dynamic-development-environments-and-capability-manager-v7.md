# Engineering OS / n8n — Dynamic Development Environments & Autonomous Capability Manager (V7)

**Status:** PROPOSED IMPLEMENTATION SPECIFICATION — not an implementation, deployment, or qualification claim.
**Scope:** The separate, live n8n Engineering OS / Project Factory runtime, not the Engineering-OS knowledge-library application.
**Baseline:** Engineering_OS_n8n_Autonomous_Project_Build_Spec_2026-11-16.md (v1.0), with subsequent Pilot 002 Attempt 5–6 external audits (November 2026).
**Decision:** Retain n8n as authoritative orchestrator, PostgreSQL as durable state/evidence substrate, authenticated Tool Gateway as execution boundary and independent verifier as acceptance authority.
**Integration:** Engineering-OS remains the knowledge/catalog and tool-installation reference; Improved-Engineering-OS, OpenHands/software-agent-sdk and AutoProjectBuilder are reuse candidates subject to independent validation.
**Release status:** No production change, no attempt 7 authorization, no automatic merge of implementation.

## 1. Goal and non-goals

Build a general-purpose, adaptive coding-agent platform: agents understand product requirements, choose suitable languages and frameworks, provision reproducible development environments, install project-scoped dependencies, edit and test real applications, use browsers and external tools, recover from failures, and deliver independently verified artifacts. Language selection must be based on requirements, not on what is easiest for the current model or already installed.

Non-goals: installing every language or framework globally on the n8n host; granting unrestricted host shell, root, or Docker socket access; allowing agents to mutate production or promote their own capabilities without independent verification; replacing n8n with another orchestrator; treating passing unit tests as proof of a complete product.

## 2. Verified motivation: Pilot 002 Attempt 6

- Experiment: pilot-002-attempt-6-1795171612; run pb-pilot-002-att6-1795171612; Orchestrator execution 42897.
- 15 task contracts, 67 tool executions (53 successful), 3 independently qualified tasks, 100 observability events.
- Essential files shop_db.py, shop_service.py and app.py were absent while the workflow reached COMPLETED and unrelated tests passed (21/21).
- The Orchestrator's PRODUCT_CONTRACT explicitly prescribed Python 3 standard library; G4 tasks hardcoded .py artifact names before independent architecture selection.
- The Tool Runner exposed Python-specific syntax and unittest tools, not a generally usable sandbox terminal, package/build managers or browser tools.
- Some agents attempted writes outside allowed task scope, spent steps searching, or produced no tools. Fail-closed path enforcement was effective; planning, task dependency, tool completeness and stage gates were not.

**Design response:** remove hardcoded technology from the generic control plane, but retain strict policy enforcement. Do not retroactively alter experiment artifacts.

## 3. Architecture and trust boundaries

Flow:

Requirements → Requirement Analyzer → Stack Options & Evidence → Independent Architecture Review → Dynamic Task DAG → Environment Manager → Secure Sandbox Runner / Tool Gateway → Build, Tests & Browser → Independent Verifier → Evidence Ledger / Audit MCP → Draft Delivery.

The n8n manager owns run orchestration, stage transitions, budgets, lease fencing and checkpoint/recovery. It never executes unrestricted host commands. A dedicated Environment Manager manages lifecycle state. A secure runner executes commands in isolated environments. The PostgreSQL evidence plane stores immutable, attributable receipts, test outcomes, artifact hashes and verifier verdicts. The independent verifier has read-only access to candidate artifacts and confidential acceptance materials but no authority to edit product code.

Separate identities and credentials for: controller, orchestrator, agent runner, sandbox provisioning service, package installation, independent verifier, audit reader and release operator. Never share production credentials with development containers. Do not expose the host Docker socket or privileged containers directly to agent-controlled code.

## 4. Technology-neutral planning and stack selection

Select language, framework, database and platform only after eliciting functional and nonfunctional requirements, existing repository constraints, deployment target, maintainability, performance, available libraries, total cost, security and testability.

For each decision store a TechnologyDecision record:
- requirement IDs; existing-repository language and framework; candidate stacks and documented tradeoffs;
- evidence and freshness; security, licensing, version/support and deployment compatibility;
- selected stack and rationale; why alternatives were rejected; uncertainty;
- reviewer identity, independent review outcome and policy approval.

When requirements change, re-evaluate the decision; do not force unnecessary migrations. For an existing repository, respect its existing architecture by default. Python, TypeScript, Go, Rust, Java or any other suitable choice is valid if justified. Do not optimize an evaluation by artificially maximizing language count.

Generate all artifact contracts after stack selection. No default .py filenames, Python-only test commands or SQLite assumptions may exist in generic G3/G4 templates.

## 5. Dynamic task graph and fail-closed product gates

Every task contract must contain: requirement IDs, owning agent, prerequisites, artifact glob/path constraints, allowed write paths, selected toolchain and image digest, build/test commands, acceptance tests, budget, retry limits, provenance and verification policy.

Dependencies use states READY, MISSING, FAILED, BLOCKED and RECOVERED. A dependent task must wait for required independently validated prerequisites. A blocked write to an unowned path must trigger replanning or an explicit task-owner dependency; it must never silently grant broader permissions.

A task producing no required artifacts and no tool calls is FAILED or BLOCKED, not successful. Repeated searches without new evidence must be stopped. Repair policy is classified by error: missing artifact, permission denial, dependency failure, syntax/build/test/runtime/browser error, environment mismatch and architectural mismatch.

Distinguish WORKFLOW_EXECUTION_FINISHED from PRODUCT_ACCEPTANCE_PASSED. Full success requires all mandatory product requirements, required artifacts, successful builds, meaningful tests, applicable browser flows, hidden acceptance and independent verification for the *same frozen candidate*. If essential parts are absent, return PRODUCT_PARTIAL or PRODUCT_FAILED even if the n8n workflow exits successfully.

## 6. Environment Manager lifecycle and manifest

A project receives its own short-lived environment, not a shared global toolchain.

Required operations:
- create, provision, start, inspect, execute, cancel, checkpoint metadata, restore/reattach, stop, garbage collect and destroy;
- list supported toolchains, determine compatible pinned versions, create/verify image, load approved cache, and report capability availability;
- record each transition with run_id, environment_id, worker/lease ID, sandbox policy ID and digest.

EnvironmentManifest must include: run ID, task scope, runtime family/version, OS/architecture, base image digest, build instructions, package manager and lockfile digest, network profile, CPU/RAM/disk/process quotas, timeout, user mapping, working directory, writable mounts, cache policy, secret policy, executable capabilities and cleanup TTL.

Provisioned build environments must be independently reproducible. Pin base image digests and dependency versions. Prevent cross-run filesystem, network, process and credential access. Prefer rootless execution and stronger isolation when appropriate; rootless alone does not establish complete containment.

Persistent n8n/PostgreSQL/Caddy services stay separate from untrusted build and test workloads. Heavy AI/media toolchains and browsers may require a separate worker host/VM; measure actual server capacity before provisioning.

## 7. Initial toolchain families

Pre-qualify minimal trusted base images or dedicated workers for:
- Web: Node.js LTS, JavaScript/TypeScript, npm/pnpm, React/Next.js/Vite/Tailwind installed at project scope, ESLint, TypeScript, Vitest/Jest and Playwright.
- Python/data/AI: pinned Python, uv/pip, pytest, Ruff, NumPy/Pandas/scikit-learn/OpenCV; ML frameworks or GPU support only on compatible workers and as required.
- Backend and databases: Node/Python/Go/Rust/Java/.NET where justified; PostgreSQL, SQLite, MySQL and Redis development/test instances and migration/SQL clients.
- Media: FFmpeg/FFprobe, validated image/video workflows, input size and compute quotas.
- Systems: Go, Rust/Cargo, C/C++ toolchains; typechecking, build, test and profiling tools.
- Optional on demand: PHP/Ruby, Dart/Flutter, Android SDK, Luau/Roblox-related CLI and GDScript, with explicit host/platform restrictions.

React is a project-level library, HTML/CSS are authoring formats, and SQL is used with a database/client: none needs a fictitious standalone runtime installation. Roblox Studio and Xcode/iOS native builds require compatible supported external environments; do not claim Linux can provide these natively.

Do not globally install every framework or pre-download huge model weights. Expose capability on demand; prioritize currently used projects, capacity and cost.

## 8. Secure tool gateway and terminal contract

Provide technology-neutral, sandbox-scoped actions (names may follow existing API):
- environment.create, inspect, start, exec, stop, destroy, verify_toolchain;
- workspace.read, patch, search, diff, verify_artifacts;
- project.detect_stack, install, build, test, lint, typecheck, start_server;
- browser.navigate, interact, capture_evidence, run_tests;
- git.diff, commit and draft PR (only with delegated permission).

Each invocation must bind authenticated agent ID, role, run ID, task ID, environment ID, allowed command class, working directory, arguments digest, resource budget and idempotency key. Return structured stdout/stderr, exit, duration, files changed, image/runtime digest, policy decision, reason and receipt ID. Redact secrets.

Block arbitrary host execution, privilege escalation, Docker socket, forbidden paths, hidden-suite access and external network destinations not explicitly approved. Constrain downloads and installation scripts. Preserve immutable failure receipts, not just successes.

## 9. Autonomous project dependency installation

Permit authorized agents to add, update and install project-scoped dependencies within their sandbox and policy; forbid automatic host-wide package manager changes.

Pipeline: propose → source/identity/reputation check → compatible/version/license check → vulnerability scan → install under network and resource policy → update manifests/lockfile → build and tests → provenance → acceptance. Pin versions and support reproducible caches; control postinstall scripts, native extensions, transitive dependencies and registry mirrors. Security is more than CVE lookup: packages can execute malicious code during install.

Project-scoped installation may run without interactive user approval only when bounded by an explicit approved policy. Privileged installers, new registries, untrusted executable scripts, shared environment promotion and infrastructure changes require a separate authorization route.

The agent must not switch to Python merely because the chosen package is absent; prefer authorized provisioning or report an explicit blocker.

## 10. Autonomous Capability Registry

Create a durable registry for languages, runtimes, tools, package managers, build/test integrations, browser drivers, reusable skills and qualified worker images.

Capability record:
- capability_id, category, supported target, version and upstream source;
- runtime/OS/architecture prerequisites, image digest, dependency/lockfile provenance;
- supported actions, access scopes, allowed roles, resource/network constraints;
- security/license review, negative tests, compatibility evidence;
- qualification status, verifier ID, last validation timestamp, revocation status and evidence references.

Lifecycle: DISCOVERED → RESEARCHED → CANDIDATE → SANDBOX_TESTED → SECURITY_REVIEWED → QUALIFIED → AVAILABLE. Revocation/deprecation are explicit and reversible as policy permits.

A tool's presence in this knowledge repository or in the registry does NOT establish that it is installed, secure or usable. Qualification is tied to exact versions and environments. Agents may propose additions and test candidates in a sandbox, but they cannot grant their own global qualification or promote code to production.

Reuse Engineering-OS capability registry and eos_capabilities.py where useful, but adapt their host/project distinctions to sandbox-scoped execution rather than granting host installation rights.

## 11. Browser, build, test and independent acceptance

The validator must auto-detect framework and choose appropriate, recorded checks:
- web: package install, typecheck/lint, production build, HTTP health, browser navigation, forms, responsive/RTL and error-state journeys, accessibility smoke and screenshots;
- backend: compile/start, contract and integration tests, database setup/migrations, auth and error paths;
- data/AI: deterministic input/output checks, evaluation metrics, reproducibility and resource constraints;
- systems: compilation, concurrency tests and benchmark against stated workload.

Zero tests cannot be a passing test suite. Syntax/static checks are distinct from executed unit/integration/E2E tests. Tests written by an agent cannot replace independent functional and hidden acceptance. Verify all required artifacts and source SHA at the final candidate revision, and reject stale candidate-test mismatches.

Give the independent verifier minimal read/list/execute-as-needed rights to a sealed candidate snapshot; no product writes and no leak of hidden tests into agent-visible environments. Validate ACLs at preflight, including the failure encountered by eos_verifier_p2 in Attempt 6.

## 12. Autonomy, governance and rollout

- n8n stays the single authoritative orchestrator.
- Agents may install approved project dependencies and operate only their assigned containers.
- Any global runtime upgrade, policy change, security exception, production or host change requires a separate authorized maintenance flow; no silent self-improvement deployment.
- Controller can launch, monitor and emergency-stop, but cannot fix product code after experiment start.
- No auto-merge, no production deploy, no real payment processing, no cross-run memory leakage.
- State and evidence must survive restart with exactly-once/at-least-once semantics documented and checked.

Implementation staging:
1. Baseline inventory, resource/cost constraints and reuse review.
2. Architecture/stack selection and dynamic artifact/task contracts.
3. Rootless or strongly isolated worker, secure command gateway and toolchain manifests.
4. Initial Web/Python/Go/Rust environments; approved package installation.
5. Browser testing, framework-aware quality gates and independent verifier ACL.
6. Capability registry, sandbox candidate qualification and controlled promotion.
7. Non-regression, negative security and held-out multi-project qualification.
8. Freeze versions, hand off to external auditor; do not launch Attempt 7 automatically.

## 13. Qualification matrix and mandatory evidence

Independent, isolated experiments:
- Q1: real React/TypeScript browser application with backend and database, build and Playwright journey.
- Q2: Python/data/ML reproducible pipeline, suitable language justified.
- Q3: performance/concurrency service in a justified language (e.g. Go or Rust) with benchmark.
- Q4: webhook/automation workflow with retries, idempotency and observable recovery.
- Q5: feature in an unfamiliar existing repository using its own language and conventions.
- Q6: missing project dependency discovered, checked, installed, pinned and used autonomously.
- Q7: newly discovered capability passes sandbox qualification; unauthorized global promotion denied.
- Q8: negative security tests (host filesystem, Docker socket, root, external network, secrets, hidden tests, cross-run mounts, resource overrun).
- Q9: incomplete product with green unit tests cannot achieve PRODUCT_ACCEPTANCE_PASSED.
- Q10: restart, worker loss, lease fencing, cleanup and budget enforcement without duplicate writes.

For each scenario capture run_id, requirement IDs, selected stack and rationale, task graph, environment/image IDs, exact build/test commands, package-lock digest, authenticated tool receipts, final artifact hashes, actual test/browser results, verifier verdicts, resource costs, controller actions and reconciliation discrepancies.

Use paired hidden cases to check that different requirements lead to genuinely different choices, not forced language variety. Explicitly mark PASS / FAIL / PARTIAL / BLOCKED / NOT TESTED. REL/AUD regressions must remain green with recorded per-case evidence. A successful sandbox install does not prove that the full platform can ship arbitrary software.

## 14. Documentation and delivery contracts

The full implementation work belongs in reviewable branches and separately authorized deployment procedures. This document is only the **target specification**.

Required implementation artifacts (once built):
- baseline inventory and resource capacity report;
- technology-selection schema and policy;
- environment manifest schema and lifecycle controller;
- isolated runner and command-permission policy;
- toolchain support and installation matrix;
- capability registry schema and qualification gates;
- package-install supply-chain checks and reproducibility evidence;
- project-aware build/test and browser receipts;
- dependency-aware planning and product-gate changes;
- independent verifier ACL and hidden-acceptance tests;
- complete Q1–Q10 experiment results, REL/AUD non-regression, final manifest, rollback procedure and external auditor handoff.

**Ready for Attempt 7 only after an independent auditor verifies mandatory gates on the actual n8n/worker deployment, not from this document or an agent summary.**
