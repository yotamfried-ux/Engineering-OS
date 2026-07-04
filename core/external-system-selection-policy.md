# external-system-selection-policy.md

Engineering OS uses this policy to make external-system selection repeatable.

The first enforced domain is Computer Vision.

Current enforcement lives in `scripts/enforcement/validate-capability-evidence.sh`.

A matching Route Plan must select `supervision` in External systems/connectors, or include an External System Selection Waiver that names `supervision` and gives a reason.

This prevents future work from forgetting useful external systems after they are added to the inventory.
