# n8n Night Qualification System — Design

## Goal
Build a cloud-first, no-code-oriented autonomous qualification system in n8n that can take a user-selected GitHub repository, validate the current product end-to-end overnight, repair defects that prevent qualification, re-run evidence-producing tests, stop reliably, and produce a final morning report. It must not autonomously add product features.

## Cost constraint
The only planned recurring paid service is the existing n8n subscription. LLM execution must be provider-agnostic and default to qualified zero-incremental-cost remote inference. A model/framework being open-source does not by itself satisfy this requirement; n8n Cloud needs a reachable inference endpoint. Paid model APIs are excluded from the default route.

## Initial delivery boundary
The first shippable stage is the deterministic control plane in n8n plus the already-qualified GitHub App integration. It does not depend on an LLM. It must accept a dynamic repository input, create a run record, inspect repository/CI state, create bounded work items, preserve evidence/logs, enforce budgets and termination rules, and produce a deterministic qualification summary. One active repository/run is sufficient initially, but schemas and workers must carry repo/run identifiers so later concurrency does not require redesign.

## Architecture
Use a deterministic workflow DAG wherever possible and reserve LLM agents for tasks that genuinely require interpretation. This follows the Engineering-OS multi-agent guidance: orchestrator + specialists + shared state/router + validator + observability, while avoiding LLM orchestration where a deterministic DAG works equally well.

Flow:

`Run Request -> Run Init -> Repository/CI Inspect -> Task Router -> Parallel Specialists -> Evidence Validator -> Repair Gate -> Re-verify -> Convergence Gate -> Final Report`

The Night Boss is a control-plane orchestrator, not an unconstrained coding agent. Specialist workers receive a narrow task envelope and return structured evidence.

## Run contract
Every run carries at least:
- `run_id`
- `repo_owner`
- `repo_name`
- `base_ref`
- `target_sha`
- `started_at`
- `deadline_at`
- `mode` (`qualification` initially)
- `status`
- `execution_budget`
- `repair_budget`
- `required_checks`
- `active_tasks`
- `findings`
- `evidence`
- `final_outcome`

Every worker task carries `run_id`, repository identity, target SHA, task type, scope, attempt number, evidence requirements and deadline.

## Initial workers
1. **CI/Test worker** — inspect existing workflows/checks, trigger approved tests, read status/log evidence, classify deterministic failures.
2. **E2E/App QA worker** — route web journeys to Playwright and mobile journeys to Maestro first; escalate deeper native/device control to Appium/Mobile Next only when required by the target and host availability.
3. **API/Backend worker** — execute project-native integration/contract/API checks and collect reproducible evidence.
4. **Security worker** — use project-native security checks plus Strix as additional adversarial evidence on authorized targets. Strix never replaces SAST/SCA/secret/config/auth/business-logic coverage.
5. **Failure Investigator** — interpret failed evidence, identify a bounded repair hypothesis and request only the context required.
6. **Repair worker** — make minimal defect fixes on an isolated branch; never add a feature; every change must be followed by the reproducing check and relevant regression checks.
7. **Verifier/Convergence worker** — deterministic final gate over required checks, open tasks, blockers, repair evidence and target SHA.

## Engineering-OS reuse
Prefer existing Engineering-OS assets over new implementations:
- multi-agent architecture guidance for orchestration boundaries;
- `patterns/testing/FAST-PATH` for lowest-sufficient-layer test routing;
- Playwright/Maestro/Appium/Mobile Next capability wrappers for application journeys;
- Strix wrapper for adversarial security evidence;
- Graphify for token-efficient repository navigation when available and fresh;
- RTK for compact shell/tool output where applicable;
- agentmemory / Codebase Memory MCP candidates for cross-run coding memory after privacy, freshness and retrieval-quality qualification;
- Superpowers-style debugging/TDD/verification discipline as reusable knowledge, not repository-level instructions that override the host agent.

Memory is not required for the deterministic first stage. Run state/evidence must remain explicit and auditable even after a memory layer is added.

## LLM layer
The control plane exposes a provider-neutral `reason(task_envelope) -> structured_result` boundary. Model selection is per worker role and may change without changing orchestration. Before enabling a provider/model it must pass:
1. reachable from n8n Cloud;
2. zero incremental recurring API cost under the selected route;
3. sufficient tool/structured-output capability for that worker;
4. representative quality qualification;
5. rate/usage limits compatible with the 00:00–08:00 workload;
6. fallback behavior that cannot silently switch to paid inference.

Deterministic evidence, not an LLM assertion, decides release/qualification status.

## GitHub policy
The GitHub App is the repository execution identity. Its read, branch/write, PR and Actions control capabilities have been live-qualified before implementation of this system.

Repairs use isolated branches/PRs. No worker pushes directly to `main`. The target SHA is pinned for a qualification cycle; if the base changes materially, the run is marked stale or a new cycle is created rather than silently certifying a different revision.

## Continuous execution and triggers
Use event-driven continuation where n8n/GitHub can provide it. Avoid tight polling loops. Long-running CI is represented as waiting work and resumed by a completion event or bounded low-frequency fallback check. The system may fan out independent workers but must serialize conflicting writes to the same repository area/branch.

## Execution budget
The design must conserve the n8n execution quota. One orchestration execution should perform multiple deterministic steps when safe rather than spawning one workflow execution per trivial operation. Workers are invoked only for independent meaningful units of work. Repeated identical failures are deduplicated by fingerprint.

Initial safety limits are configuration, not hard-coded architecture: maximum repair attempts per finding, maximum total repairs, maximum worker fan-out, and deadline. Exhausting a limit produces `blocked`, not an infinite loop.

## Repair policy
Allowed autonomous changes are minimal fixes needed to restore documented/current expected behavior or make existing validation executable. Forbidden autonomous changes include new features, product-scope expansion, speculative refactors unrelated to the failure, bypassing/removing tests to obtain green status, weakening security controls, or changing acceptance criteria to make a failure disappear.

A repair is accepted only when the original reproducer passes and relevant regression evidence remains green.

## Termination and qualification gate
A run may end `qualified` only when all of the following are mechanically true for the pinned target state:
- every required check is complete and passing;
- no required GitHub check is failed, queued or running;
- every finding is `verified_fixed`, `false_positive` with evidence, or an explicitly permitted non-blocking observation;
- no blocking finding remains;
- no worker/task remains active;
- all accepted repairs have reproducer + regression evidence;
- no forbidden feature work occurred;
- the run has not become stale relative to the revision being reported.

A run ends `blocked` when a required capability/credential/environment is unavailable, a repair budget/deadline is exhausted, or a defect cannot be safely repaired. `blocked` must never be presented as `qualified`.

At 08:00, or the configured deadline, the system stops starting new repair cycles, waits only for bounded in-flight evidence where policy permits, then emits the report. Deadline does not convert failures to success.

## Observability
Every meaningful action emits a compact structured event containing timestamp, run/task ID, worker, action, target, attempt, status, evidence reference and error/finding fingerprint. n8n execution logs remain available, but the final report must not require reading raw n8n logs to understand what happened.

The morning report includes:
- repository + exact SHA qualified;
- final outcome (`qualified`, `failed`, `blocked`, `stale`);
- checks/simulations executed and evidence;
- defects found;
- repairs attempted/accepted/rejected;
- open blockers;
- CI/action links where available;
- execution/repair budget consumption;
- recommended next human action.

## Initial n8n workflows
The first stage should create a small set of workflows rather than one workflow per agent:
1. `Night Qualification - Start Run` — validates input and initializes run state.
2. `Night Qualification - Control Loop` — deterministic inspection, routing, budget/deadline/convergence logic.
3. `Night Qualification - GitHub Worker` — reusable GitHub read/Actions/branch/PR operations behind an operation allowlist.
4. `Night Qualification - Finalize Run` — computes outcome and report from structured state/evidence.
5. `Night Qualification - Simulation Harness` — injects known pass/fail/blocked/stale scenarios without modifying production repositories.

Specialist AI workers are added behind stable task contracts after the control plane is qualified.

## First-stage acceptance tests
Before adding LLM agents, simulations must prove:
- valid dynamic repo input initializes a pinned run;
- invalid/uninstalled repo fails safely;
- known-green repository state reaches `qualified` without repair;
- failed check creates a bounded work item rather than a false PASS;
- duplicate failure does not create unbounded duplicate tasks;
- repair/attempt budget exhaustion ends `blocked`;
- deadline ends safely and produces a report;
- queued/running required CI prevents `qualified`;
- target revision drift produces `stale`;
- GitHub write operations are allowlisted and cannot write directly to `main`;
- final report can be reconstructed from structured events without raw execution-log interpretation.

## Non-goals for first stage
- multiple simultaneous repositories;
- autonomous feature development;
- paid LLM APIs;
- direct-to-main repair writes;
- replacing project-native tests with agent judgment;
- deploying every Engineering-OS capability before it is needed and qualified.
