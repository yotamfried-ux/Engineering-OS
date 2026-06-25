# Official Patterns Adoption Audit

This document converts the Deep Research report into a conservative adoption plan for Engineering OS.

The purpose is to adopt only official, proven surfaces that directly address failures already observed in the ClientPulse experiment. This file is an audit document only. It does not change runtime behavior.

## Observed failures

| Observed failure | Correction needed |
|---|---|
| `core/task-router.md` was not read | Routing must be required before implementation. |
| `core/workflow.md` was not followed | Workflow evidence must exist before implementation. |
| Spec/source-of-truth was skipped | Source-of-truth checks must be explicit. |
| Context7 or official docs were skipped when relevant | Official-doc checks must be required for external libraries/APIs. |
| Plan was written after the work | Plan must exist before implementation. |
| Plan checkboxes were completed too early | Planned work and completed evidence must be separate. |
| Skills/connectors were not used | Required capabilities must be computed, not guessed by the model. |
| Evidence was too weak | Evidence should record operation-level facts where possible. |
| Rules existed as text only | Runtime lifecycle hooks must enforce critical workflow boundaries. |

## Source decisions

| Source | Owner | Decision | Reason |
|---|---|---|---|
| Claude Code Hooks docs | Anthropic | Adopt now | Official lifecycle surface for prompt, tool, and completion gates. |
| Claude Code Settings docs | Anthropic | Adopt later | Useful for managed rollout after local behavior is proven. |
| Claude Code Skills docs | Anthropic | Adopt partial | Official packaging format for skills, not a complete governance layer. |
| `anthropics/skills` | Anthropic | Adopt partial | Use the `SKILL.md` pattern for a small number of project skills. |
| Claude Code MCP docs | Anthropic | Adopt now | Official project-scoped connector configuration model. |
| `github/github-mcp-server` | GitHub | Adopt now | Official GitHub connector; start narrow and read-oriented. |
| MCP specification | MCP project | Adopt as design basis | Defines tools, resources, and prompts clearly. |
| `modelcontextprotocol/python-sdk` | MCP project | Adopt only if needed | Useful only if we later build a thin internal MCP wrapper. |
| `modelcontextprotocol/servers` | MCP project | Reject as production runtime | Treat as reference examples, not drop-in production code. |
| `openai/evals` | OpenAI | Adopt now as test model | Convert the previous manual experiment into regression cases. |
| `openai/openai-agents-python` | OpenAI | Adapt selectively | Useful design references for routing, approvals, and tool filtering. |
| `openai/openai-guardrails-python` | OpenAI | Reject for current problem | Does not directly govern Claude Code built-in tools/MCP execution. |

## Adopt now

1. Claude Code lifecycle hooks as the runtime surface.
2. A minimal Engineering OS capability registry.
3. A narrowed official GitHub MCP connector profile.
4. OpenAI Evals-style regression corpus for workflow bypass cases.

## Adopt later

1. Managed settings rollout.
2. Strict plugin/customization mode only after local hooks and tests are stable.
3. Additional MCP connectors only when a concrete project failure requires them.

## Reject now

1. Migrating the project runtime to OpenAI Agents.
2. Using OpenAI Guardrails as the primary Claude Code/MCP enforcement layer.
3. Treating MCP reference servers as production runtime code.
4. Importing many skills before proving that a small skill set solves the current failures.
5. Adding broad connector access without a concrete failure-to-source mapping.

## Replacement candidates

| Existing area | Direction | Official pattern |
|---|---|---|
| Text-only workflow rules | Wrap with runtime checks | Claude Code hooks |
| Existing evidence scripts | Replace gradually | Official hook JSON decision formats plus shared validators |
| Custom skill docs | Replace gradually | Official `SKILL.md` format |
| Connector prose | Wrap | MCP profiles and operation-level evidence |
| Manual ClientPulse experiment | Replace | Eval-style regression corpus |
| Local settings trust | Harden later | Managed settings |

## Minimal PR sequence

1. Audit and registry skeleton — current PR.
2. Official hook decision format.
3. Regression eval corpus.
4. Narrow GitHub MCP profile.
5. Managed settings rollout.

## Definition of Done for this PR

- [ ] Recommendations map to observed failures.
- [ ] Official sources are marked as adopt now, adopt later, adapt, or reject.
- [ ] Rejected sources have explicit reasons.
- [ ] Capability registry is marked as skeleton/non-runtime.
- [ ] No runtime behavior changes are introduced.
- [ ] GitHub Actions and CodeRabbit pass before merge.
- [ ] Yotam explicitly approves before merge.
