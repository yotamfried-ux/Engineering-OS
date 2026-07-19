# Claude Behavioral Evaluation Harness

This directory defines a behavioral evaluation for Claude using neutral work requests and artifact-based scoring.

The goal is to check whether a separate Claude run uses Engineering OS correctly when it receives a normal project task. The task packet itself must not explain the scoring rules or tell Claude which Engineering OS files, skills, connectors, templates, or policies to use. The evaluated model should see an ordinary work request plus the repository.

## What this harness tests

The evaluator checks artifacts created by the model after a task run. It does not trust the model's self-report.

For each task, the oracle can require evidence such as:

- a Route Plan exists;
- task class is appropriate;
- domain tags are appropriate;
- required skills are selected;
- required templates, patterns, architecture guides, connectors, or waivers are recorded;
- missing user decisions are surfaced instead of guessed;
- answered/deferred decisions are not repeatedly reopened;
- unsafe or impossible claims are absent.

The `max_occurrences` and `exact_occurrences` checks use the value format
`<count>||<normalized text>`. They are intended for interaction artifacts where
final self-report cannot prove how many times a behavior occurred.

## What this harness does not do

This PR does not run Claude by itself. A separate operator must run Claude in a clean session against each task packet and save the resulting artifacts under a run directory.

This distinction is intentional: deterministic CI can validate the scorer and fixtures, but a real behavioral result requires a separate Claude execution.

## Operator protocol

1. Start from a fresh checkout of the repository.
2. Install or expose the Engineering OS files exactly as a normal target project would use them.
3. Start a clean Claude session.
4. Provide only the contents of one file from `task-packets/` as the work request. Do not include this README, the oracle, or the evaluator in the evaluated model's prompt.
5. Let the model work normally.
6. Save artifacts under:

```text
experiments/claude-behavioral-eval/runs/<run-id>/<task-id>/
```

Required artifact:

```text
route-plan.md
```

Optional artifacts (or required by a task-specific oracle):

```text
changed-files.txt
notes.md
run-trace.md
interaction-log.md
```

`interaction-log.md` should contain normalized metadata events, not raw private
conversation text. For user-decision tasks, use stable lines such as:

```text
ask_user_question:<decision-id>
decision_state:<decision-id>:answered|deferred|blocked|superseded
```

7. Score the run:

```bash
python3 experiments/claude-behavioral-eval/evaluate.py \
  --oracle experiments/claude-behavioral-eval/oracle.tsv \
  --run-dir experiments/claude-behavioral-eval/runs/<run-id>
```

## Result interpretation

- PASS means the artifacts satisfy the oracle.
- FAIL means Claude skipped or misclassified a required Engineering OS decision.
- A FAIL is a system gap unless the oracle is wrong. Fix the system or the oracle, then repeat with a fresh Claude session.

## Important control rule

Do not reveal the oracle, scorer, or evaluation purpose to the evaluated Claude session. The task packet should remain a normal work request.
