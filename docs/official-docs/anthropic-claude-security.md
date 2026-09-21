# Anthropic — Claude Security for Claude Code

**Official announcement:** Claude Security plugin for Claude Code, public beta (2026).

Anthropic describes a Claude Code security workflow that can scan a codebase or a set of changes, build repository context/threat models, investigate potential vulnerabilities and suggest patches for human review.

## Use when
Use as an additional AI-assisted security-review layer when the target host has the official Claude Security plugin available.

## Evidence rule
Claude Security findings are evidence inputs, not proof that software is secure. Record plugin/model/version, exact revision, scan scope, confirmed findings, rejected findings, patches and remaining untested security controls. Feed results into the same ASVS/WSTG/security evidence matrix used for CodeQL/SCA/DAST/manual testing.

## Freshness
This capability is beta and may change quickly. Re-check Anthropic's current official installation, availability, supported plans and commands before use; do not rely on screenshots or copied third-party installation commands.

**Status:** OFFICIAL BETA CAPABILITY / AVAILABILITY-DEPENDENT.
