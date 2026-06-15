# Computer Vision Template

## Overview
Use this template for systems that process images or video — object detection, classification, segmentation, OCR, pose estimation, or tracking. Covers both real-time inference pipelines and batch processing workflows where visual data is the primary input.

## Recommended Architecture Options

| Option | Pros | Cons |
|---|---|---|
| Pre-trained model + fine-tuning (transfer learning) | Fast time-to-value, less data required | May underperform on highly domain-specific data |
| Custom model training from scratch | Maximum control and accuracy | Requires large labeled dataset and compute |
| API-based vision (Claude Vision, Google Vision, AWS Rekognition) | Zero infra, fast integration | Cost at scale, data leaves your environment |
| YOLO / RT-DETR real-time pipeline | High FPS on edge or GPU, well-supported | Task-specific; not general purpose |

## Recommended Frameworks & Platforms

- **Language:** Python 3.12+
- **Core framework:** PyTorch 2.x + torchvision
- **Detection/segmentation:** Ultralytics YOLOv8/v11, Detectron2, or Segment Anything (SAM)
- **Classical CV:** OpenCV 4.x (preprocessing, geometric transforms, video I/O)
- **Data augmentation:** Albumentations (fast, GPU-compatible)
- **Dataset management:** Roboflow, CVAT (annotation), or FiftyOne (visualization/curation)
- **Experiment tracking:** Weights & Biases with image logging
- **Serving:** FastAPI + OpenCV for images; NVIDIA Triton or TorchServe for high-throughput
- **Edge deployment:** ONNX + ONNX Runtime, TensorRT (NVIDIA), or CoreML (Apple)
- **Video:** FFmpeg for I/O, OpenCV VideoCapture, or GStreamer for real-time streams

## Required Components

- Image preprocessing pipeline (resize, normalize, format conversion) separate from model code
- Labeled dataset with train/val/test split and version control (DVC or Roboflow)
- Inference wrapper that accepts raw bytes or file paths and returns structured results
- Confidence threshold and NMS configuration externalized
- Visualization utilities (bounding box drawing, mask overlay) for debugging
- Batch inference path for offline processing
- Performance profiling: FPS, latency per image, GPU utilization

## Security Checklist

- [ ] Image upload endpoint validates file type (magic bytes, not just extension) and size limit
- [ ] Inference service does not persist uploaded images unless explicitly required
- [ ] Model files validated by checksum before loading
- [ ] PII in images (faces, license plates) handled per applicable privacy regulation
- [ ] API authenticated — computer vision endpoints not publicly open
- [ ] Container runs as non-root user with read-only filesystem where possible
- [ ] Input sanitized: malformed or adversarial images fail gracefully without crashing service

## Testing Checklist

- [ ] Unit tests for preprocessing and postprocessing functions (deterministic)
- [ ] Model accuracy tests against a fixed labeled test set (mAP, F1, or task-appropriate metric)
- [ ] Regression test: model score does not drop below baseline after any change
- [ ] Edge cases tested: empty image, all-black image, very large image, unsupported format
- [ ] Latency benchmark: p95 inference time under expected load
- [ ] Video pipeline test: correct frame handling, no memory leaks over long streams

## Deployment Checklist

- [ ] Model exported to ONNX or TensorRT for production serving (not raw PyTorch)
- [ ] GPU driver version and CUDA version pinned in Docker base image
- [ ] Model artifact versioned and stored in registry with checksum
- [ ] Serving container resource limits (GPU memory, CPU, RAM) configured
- [ ] Health check endpoint verifies model is loaded and returns a test inference result
- [ ] Monitoring: inference latency, error rate, and throughput tracked per endpoint
- [ ] Auto-scaling policy accounts for GPU availability, not just CPU

## Reference Repositories

- [ultralytics/ultralytics](https://github.com/ultralytics/ultralytics) — YOLOv8/v11 training, fine-tuning, and export
- [facebookresearch/detectron2](https://github.com/facebookresearch/detectron2) — production-grade detection and segmentation
- [albumentations-team/albumentations](https://github.com/albumentations-team/albumentations) — fast augmentation pipelines

## Official Documentation

- [PyTorch Vision Docs](https://pytorch.org/vision/stable/index.html) — transforms, models, datasets
- [OpenCV Docs](https://docs.opencv.org/4.x/) — image I/O, geometric ops, video
- [Ultralytics Docs](https://docs.ultralytics.com) — YOLO training, export, deployment
- [Albumentations Docs](https://albumentations.ai/docs/) — augmentation pipeline reference
- [ONNX Runtime Docs](https://onnxruntime.ai/docs/) — cross-platform inference optimization
