# Strix

**Canonical upstream:** `usestrix/strix`

Open-source agentic penetration-testing platform. Strix runs dynamic security investigations against authorized targets, validates findings with proof-of-concept evidence, supports CI/CD use, and publishes agent skills for coding agents.

## Use when
Use for authorized application/API/codebase penetration testing where dynamic exploit validation adds evidence beyond SAST/SCA scanners.

## What it proves
A successful finding can provide dynamic evidence that a specific weakness was exploitable in the tested revision/environment. A clean run does **not** prove the application is secure and does not replace ASVS/WSTG coverage, SAST, SCA, secrets, configuration, authorization, or manual review.

## Agent integration
Upstream documents SKILL.md-compatible workflows, including penetration testing, remediation/retest and CI security scanning. Prefer the upstream agent skill rather than inventing a local workflow.

## Safety and qualification
Only test assets the operator owns or is explicitly authorized to assess. First qualify on a disposable target, pin/record the Strix version, target/revision, configuration and result artifacts. Feed findings and untested areas into the security evidence matrix.

**Status:** READY AS KNOWLEDGE / HOST-DEPENDENT FOR EXECUTION.
