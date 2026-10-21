# Evidence-based AI agent evaluation

## Purpose
Test whether retrieving Engineering-OS documentation measurably changes app-building behavior. This is a research protocol, not a completed evaluation.

## Trial setup
Freeze product spec, acceptance tests, tool access, model/version, budget, initial repository, and environment. Randomize paired runs with library retrieval ON vs OFF. Use 3+ independent paired seeds, isolated branches, no sharing outputs between arms. Record retrieval logs and exactly which guidance the agent saw.

## Independent assessment
Run identical security, integration, accessibility, reliability and core UX tests against each output. Blind-score applicable privacy/consumer/platform requirements with human legal/platform reviewers. Count testable control coverage, critical/high findings, unverified assertions, false PASS reports, deployment failures, time and token usage. Track confounders. Do not claim statistical significance or causality without adequate replication.

## Per-control evidence schema
```json
{"control_id":"PRE-02","applicability":"REQUIRED","source_url":"https://supabase.com/docs/guides/database/postgres/row-level-security","source_checked_on":"2026-10-21","revision":"<git-sha>","environment":"<environment>","test_command":"<command>","status":"NOT TESTED","evidence_url":null,"reviewer":null,"notes":"No test has been run"}
```
Status must be PASS, FAIL, PARTIAL, BLOCKED, NOT TESTED, NOT APPLICABLE, or FLAKY. A documentation link never counts as test evidence.

## Acceptance
An agent should (1) route to correct docs for Israel vs other jurisdictions, (2) cite canonical sources, (3) select applicable checks, (4) implement controls, (5) execute tests, (6) record real evidence, (7) refuse ungrounded PASS claims. Human review required for legal interpretation.
