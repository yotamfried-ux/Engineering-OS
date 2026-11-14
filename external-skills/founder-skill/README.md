# Founder Skill — simulated buyer research and business planning (catalog only)

**Canonical source:** https://github.com/Jakeschincariol/founder-skill
**License:** MIT, verified in upstream LICENSE (2026-11-14).
**Status:** DISCOVERED / NOT INSTALLED / NOT QUALIFIED.
**Source tier:** upstream primary for implementation and behavior; independent peer-reviewed research for limits of synthetic respondents.

## Purpose and routing

Use when a founder wants to **generate hypotheses** about customer objections, positioning, price sensitivity, or operational feasibility before a real-world validation test. This is not a real customer panel or demand forecast.

The upstream has **11 Claude Code skills**: `founder-board`, `founder-competitors`, `founder-consumer`, `founder-pricing`, `founder-offer`, `founder-cfo`, `founder-marketing`, `founder-brand`, `founder-ops`, `founder-launch`, `founder-plan`. It also describes four Python standard-library helpers for consumer-panel setup/tally, pricing, unit economics and business-plan compilation.

### Distinctive mechanism

`founder-consumer` creates buyer persona cards from a user-reviewed target profile, presents the same pitch to each simulated persona, and aggregates objections and price answers. The default is **100 separate sub-agent calls** (10 waves of 10); a `--quick` option uses 20. Inputs/outputs include `founder/customer.json`, `founder/pitch.md`, and `founder/panel/`. The helper `panel.py` deals cards and tallies responses; the language-model subagents generate responses. Do not describe the 100 as surveyed humans.

### Overlap and selection

- `external-skills/minimalist-entrepreneur/README.md` (candidate in PR #308 as of 2026-11-14): early sales, founder outreach, initial pricing and basic validation. Prefer it for **first paying customer acquisition**.
- This candidate is specifically useful for **structured synthetic persona stress testing**, scenario objections, and numerical scenario modeling. It is **not** a replacement for real interviews, experiments, conversion data or competitor source checks.
- `docs/product-experience/analytics-experimentation-growth.md` remains the first stop for measurement and experimental design.
- Do not duplicate or install overlapping skills without a scoped evaluation.

### Evidence and reliability

- The upstream itself warns simulated buyer buy rates are not real conversion predictions; its `founder-consumer/SKILL.md` advises human validation via waitlists, pre-sales or priced landing pages.
- Synthetic-persona responses can be biased and prompt-sensitive; require independent empirical validation before interpreting any forecast. This limitation is a methodological caution, not a claimed numerical benchmark.
- Treat persona objections as **brainstorming hypotheses**; do not use synthetic responses as testimonials, forecast demand or claim statistically representative sampling.
- Never invent market statistics, competitors, buyer identities, sales, actual price quotes or financial results. Financial calculations require auditable user-supplied inputs.

### Scope, privacy, cost and installation

The upstream describes local Python scripts with no network use and a Claude Code plugin. This does not imply the whole workflow is offline: model/subagent execution can incur tokens, time, provider costs and data processing. Avoid putting real identifiable customer data into prompts without appropriate consent/privacy review. No automated external outreach or payments are part of this catalog.

Upstream documented installation (for future audited use, **do not run automatically**):
```
/plugin marketplace add Jakeschincariol/founder-skill
/plugin install founder-skill@founder-skill
```

### Qualification still required

Read and review **all 11 SKILL.md files and four helper scripts**, confirm no unexpected I/O, assess permissions and host compatibility, run upstream tests, test reproducibility and cost with a small `--quick` scenario, and compare with existing founder skills. Only then promote to a standard four-file `external-skills/` integration contract and install profile if justified.

**Actually inspected (2026-11-14):** canonical README, `skills/founder-consumer/SKILL.md`, LICENSE. Existence and documentation confirmed; no runtime execution or security audit performed.

### Canonical references

- https://github.com/Jakeschincariol/founder-skill
- https://github.com/Jakeschincariol/founder-skill/blob/main/README.md
- https://github.com/Jakeschincariol/founder-skill/blob/main/skills/founder-consumer/SKILL.md
- https://github.com/Jakeschincariol/founder-skill/blob/main/LICENSE
