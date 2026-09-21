# Knowledge Integrity Automation

This gate protects the repository as a **knowledge library**. It does not revive the old Engineering-OS runtime.

## Mechanical checks

The checker fails when:
- a required top-level routing/evidence entry point disappears;
- a relative Markdown link or local heading anchor is broken;
- a routing-map first-stop target cannot be resolved;
- an active knowledge document points in code-form to a removed runtime path;
- an obvious share/access-token query parameter is committed.

The GitHub Actions workflow runs the checker on pull requests, pushes to `main`, and manual dispatch.

## Deliberate boundaries

The gate does **not** claim that external URLs, third-party repositories, package versions, vendor policies or install instructions are current. Those require network/vendor verification under `capability-registry/SOURCE-POLICY.md`.

Historical evidence is allowed to mention removed runtime paths inside lessons, failed solutions, imported Stage 3 knowledge and audit/evaluation records.

## Local run

```bash
python tools/check_knowledge_integrity.py
```

A green run proves only the repository-local invariants above.
