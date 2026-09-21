# Gitleaks

**Source:** `gitleaks/gitleaks`.

## Use
Focused secret detection in repository content and Git history.

## Evidence
Record version, scan mode/range, repository revision/history depth, configuration/allowlist and findings.

A working-tree-only scan does not prove Git history is clean. A detected real secret requires revocation/rotation; deleting it from the latest file is insufficient.
