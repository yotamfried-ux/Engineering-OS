# Claude Behavioral Evaluation Harness

This directory defines a behavioral evaluation for Claude using neutral work requests and artifact-based scoring.

The goal is to check whether a separate Claude run uses Engineering OS correctly when it receives a normal project task. The task packet itself must not explain the scoring rules or tell Claude which Engineering OS files, skills, connectors, templates, policies, artifact names, or decision IDs to use. The evaluated model should see an ordinary work request plus the repository.

## What this harness tests

The evaluator checks run artifacts and operator-observed interaction evidence. It does not trust the model's final self-report or a model-authored interaction summary.

For each task, the oracle can require evidence such as:

- a Route Plan exists;
- task class is appropriate;
- domain tags are appropriate;
- required skills are selected;
- required templates, patterns, architecture guides, connectors, or waivers are recorded;
- missing user decisions are surfaced instead of guessed;
- answered/deferred/blocked decisions are not repeatedly reopened;
- cross-repository handoffs use either a complete destination-readable ready path or a complete blocked-transfer path;
- unsafe or impossible claims are absent.

The `max_occurrences` and `exact_occurrences` checks use the value format
`<count>||<normalized text>`. They are intended for operator-captured interaction
artifacts where final self-report cannot prove how many times a behavior occurred.

The `required_all_any` check expresses complete alternative evidence groups. Separate
alternatives with `||` and required terms inside each alternative with `&&`:

```text
status: deferred&&handoff_persistence: ready&&handoff_ref:||status: blocked&&handoff_persistence: blocked&&handoff_block:
```

The rule passes only when every term from at least one complete alternative is present.
Empty alternatives or terms fail closed.

## What this harness does not do

This PR does not run Claude by itself. A separate operator must run Claude in a clean session against each task packet and save the resulting artifacts under a run directory.

This distinction is intentional: deterministic CI can validate the scorer and fixtures, but a real behavioral result requires a separate Claude execution.

## Operator protocol

1. Start from a fresh checkout of the repository.
2. Install or expose the Engineering OS files exactly as a normal target project would use them.
3. Start a clean Claude session with transcript/tool-event capture enabled on the host surface when available.
4. Provide only the contents of one file from `task-packets/` as the work request. Do not include this README, the oracle, the evaluator, required artifact names, or expected decision IDs in the evaluated model's prompt.
5. Let the model work normally. Do not ask it to create evaluation evidence.
6. Save artifacts under:

```text
experiments/claude-behavioral-eval/runs/<run-id>/<task-id>/
```

Model-produced work artifact:

```text
route-plan.md
```

Other model-produced work artifacts may include:

```text
changed-files.txt
notes.md
run-trace.md
```

The operator or harness — never the evaluated model — creates `interaction-log.md`
from the actual conversation/tool trace after the run. It must begin with:

```text
source: operator-observed-trace
```

Then add normalized metadata events only, never raw private conversation text:

```text
ask_user_question:<decision-id>
decision_state:<decision-id>:answered|deferred|blocked|superseded
```

Use the stable decision ID recorded in the model's work artifact or map the observed
question to the corresponding decision after the run. Count every actual
`AskUserQuestion` event, including repeated prompts the model omitted from its own
summary. Preserve the source trace privately according to the environment's data
policy; the scored log contains only the normalized metadata above.

For a ready cross-repository handoff, the operator must verify that `handoff_ref`
resolves and is readable from the destination context. Approved types are destination
issue, destination PR, committed destination file, and a shared tracker verified in both
sessions. A text-shaped URL that does not resolve is a failed run even if the local
string checks pass.

When the environment has no authenticated destination or shared-tracker access, the
policy-compliant result is `status: blocked`, `handoff_persistence: blocked`, and a
safe copyable `handoff_block`. The operator must not penalize this outcome or replace it
with an invented URL; the destination transfer remains future work while the user
choice stays closed.

7. Score the run:

```bash
python3 experiments/claude-behavioral-eval/evaluate.py \
  --oracle experiments/claude-behavioral-eval/oracle.tsv \
  --run-dir experiments/claude-behavioral-eval/runs/<run-id>
```

## Result interpretation

- PASS means the artifacts satisfy the oracle and any operator-only validation named above.
- FAIL means Claude skipped or misclassified a required Engineering OS decision, repeated a closed decision, or produced an invalid handoff.
- A FAIL is a system gap unless the oracle or operator mapping is wrong. Fix the system or the oracle, then repeat with a fresh Claude session.

## Important control rule

Do not reveal the oracle, scorer, evaluation purpose, artifact schema, or expected IDs to the evaluated Claude session. The task packet must remain a normal work request.
