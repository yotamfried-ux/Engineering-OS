# Supervision — Computer Vision Toolkit

## Identity

- Repository: `roboflow/supervision`
- Package: `supervision`
- Homepage/docs: `https://supervision.roboflow.com/latest/`
- License: MIT
- Language/runtime: Python `>=3.10`
- Layer: `external-systems/` reference, not an `external-skills/` workflow skill

## What it is

`supervision` is a Python toolkit for computer vision application work: model-agnostic detections, annotators, dataset loading/splitting/merging, visualization, and utility building blocks around CV models.

Use it as an application dependency when a target project needs practical CV utilities around detection, segmentation, classification, video annotation, tracking/counting, dataset conversion, or review overlays.

## Why it belongs here

This is not a Claude workflow skill. It does not define how Claude plans, reviews, compresses context, or runs development workflows. It is a third-party application library that target apps may import, so it belongs in `external-systems/`.

## When to select

Select `supervision` when the task involves one or more of:

- converting model outputs into a shared detections representation;
- drawing boxes, masks, labels, polygons, traces, or other CV annotations;
- building visual review outputs for images or videos;
- working with detection datasets in COCO, YOLO, or Pascal VOC style formats;
- counting, zones, tracking, or frame-level video analytics;
- connecting outputs from model libraries such as Ultralytics, Transformers, MMDetection, Roboflow Inference, or RF-DETR into a consistent application layer.

## When not to select

Do not select `supervision` when:

- the project has no computer-vision/image/video analytics requirement;
- the task only needs model inference and no post-processing, annotation, dataset, or visualization utilities;
- the runtime cannot support Python `>=3.10`;
- dependency size, OpenCV availability, or deployment image constraints make `opencv-python`, `matplotlib`, or `scipy` unsuitable;
- the requirement is a managed hosted inference API rather than a local utility library.

## Installation decision

Default stance: **do not install by default**.

Install only inside target projects that explicitly need CV utilities.

```bash
pip install supervision
```

For app projects, pin the version in the target project's dependency file after checking the current PyPI/release state. Do not vendor the upstream repository into Engineering OS.

## Minimum compatibility facts verified from upstream

- Python requirement: `>=3.10`.
- Current upstream development version in `develop` branch: `0.30.0.dev`.
- License: MIT.
- Core dependencies include `numpy`, `opencv-python`, `pillow`, `matplotlib`, `pyyaml`, `requests`, `scipy`, `tqdm`, and `defusedxml`.
- Optional extras include geotiff support through `rasterio` and metrics support through `pandas`.

## Common usage pattern

```python
import cv2
import supervision as sv

image = cv2.imread("path/to/image.jpg")
detections = sv.Detections(...)

box_annotator = sv.BoxAnnotator()
annotated = box_annotator.annotate(scene=image.copy(), detections=detections)
```

For model-specific conversion, prefer the official `sv.Detections` adapters when they exist instead of writing custom conversion logic.

## Engineering OS usage rule

When a task may need `supervision`, the Route Plan should record:

```md
| External systems/connectors | supervision |
```

and explain the concrete CV need under `Evidence to check` or `Source of Truth Checks`.

Before writing target-project code with `supervision`, verify:

1. Python runtime is `>=3.10`.
2. Deployment environment supports OpenCV dependencies.
3. The selected model output can be represented as `sv.Detections` or an equivalent supported object.
4. Tests cover at least one representative detection/annotation conversion.

## Project relevance

This library is especially relevant for video and drone/sports workflows where we need to annotate frames, inspect model detections, generate review overlays, compare detection quality, count objects/zones, or standardize model outputs before editing/highlight selection.

## Source verification

Verified from:

- `roboflow/supervision` repository metadata.
- `roboflow/supervision` `README.md` on `develop`.
- `roboflow/supervision` `pyproject.toml` on `develop`.
