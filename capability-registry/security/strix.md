# Strix

Canonical upstream: `usestrix/strix`.

AI-assisted penetration testing for authorized local codebases, GitHub repositories and live web applications. Strix is an **on-demand specialist**, not an always-on scanner. Routine security coverage should use deterministic SAST, SCA, secret/configuration, authorization and business-logic checks first.

## Agent request contract
An agent should request Strix only when dynamic adversarial validation adds material evidence, for example after meaningful auth/permission/API changes, before a significant release, when another security tool finds a candidate that needs exploit validation, or when a vulnerability fix needs a penetration retest.

Emit a fenced or plain JSON object with this schema:

```json
{
  "security_tool": "strix",
  "action": "run",
  "target_repo": "yotamfried-ux/<repo>",
  "target_ref": "<branch-or-sha>",
  "scan_mode": "quick|standard|deep",
  "reason": "<why dynamic testing is warranted>",
  "focus": ["<area>"]
}
```

The request is a recommendation to the chat operator. It does not itself execute Strix. The chat/operator validates authorization and target scope, dispatches `.github/workflows/strix-security-runner.yml`, tracks the run, rejects false-positive execution success, and reads the machine-readable result plus artifacts.

## Result contract back to agents
Return a normalized result so the requesting agent can continue without parsing GitHub logs:

```json
{
  "security_tool": "strix",
  "status": "clean|findings|error|not_run",
  "target_repo": "yotamfried-ux/<repo>",
  "target_ref": "<branch-or-sha>",
  "target_sha": "<resolved-sha>",
  "scan_mode": "quick|standard|deep",
  "run_url": "<github-actions-run-url>",
  "findings": [],
  "execution_verified": true,
  "next_action": "continue|remediate_and_retest|manual_strix"
}
```

`execution_verified` may be true only when Strix actually performed model-backed work. `agent run failed`, provider/rate-limit failures, zero-token pseudo-runs, missing result evidence, or malformed artifacts are `status=error`, never `clean`.

If hosted free-model capacity cannot support the requested scan, return `status=not_run`/`next_action=manual_strix` rather than silently downgrading security evidence. The user can then run Strix manually when needed.

Follow current upstream prerequisites/install docs. Record version/revision, target, scan mode/depth and findings. Reproduce confirmed findings deterministically where practical. Do not run against unauthorized targets.

Do not confuse with archived `strixproject/Strix`, which is a different/older project.
