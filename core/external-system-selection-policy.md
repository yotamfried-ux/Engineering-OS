# external-system-selection-policy.md

Engineering OS uses this policy to make external-system selection repeatable.

## Rule

If a task matches a domain in `core/domain-external-system-map.yaml`, the Route Plan must either select the listed external system or record a focused waiver.

For Computer Vision tasks, consult `supervision` when the task involves detection, tracking, annotation, segmentation, video analytics, frame review overlays, YOLO, Roboflow, sports video, or drone footage.

## Route Plan evidence

Accepted:

```md
| External systems/connectors | supervision |
```

Also accepted:

```md
## External System Selection Waiver

- `supervision` — not required because <reason>.
```

The purpose is to prevent future work from forgetting useful external systems after they are added to the inventory.
