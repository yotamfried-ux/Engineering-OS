# Machine Learning Template

## Overview
Use this template for systems that train, evaluate, and serve ML models — from classical sklearn pipelines to deep learning with PyTorch or JAX. Covers the full lifecycle: data preparation, training, experiment tracking, evaluation, and production inference serving.

## Recommended Architecture Options

| Option | Pros | Cons |
|---|---|---|
| Notebook → script → training job (linear) | Simple, fast for small projects | No reproducibility at scale; manual tracking |
| MLflow + custom training scripts | Full experiment tracking, model registry | Self-hosted infra required |
| Weights & Biases + cloud training (GCP Vertex / AWS SageMaker) | Managed compute, excellent experiment UI | Cost and vendor dependency |
| Hugging Face ecosystem (Trainer + Hub + Spaces) | Best for LLM fine-tuning and NLP; free model hosting | Less flexible for custom architectures |

## Recommended Frameworks & Platforms

- **Language:** Python 3.12+
- **Core ML:** PyTorch 2.x (primary), scikit-learn (classical/preprocessing)
- **Training acceleration:** PyTorch Lightning or Hugging Face Accelerate (multi-GPU)
- **Data loading:** PyTorch DataLoader, Hugging Face Datasets, or WebDataset (large-scale)
- **Experiment tracking:** Weights & Biases (W&B) or MLflow
- **Model registry:** W&B Artifacts, MLflow Model Registry, or Hugging Face Hub
- **Hyperparameter tuning:** Optuna or Ray Tune
- **Serving:** FastAPI + ONNX Runtime (latency-sensitive), or TorchServe, or Hugging Face Inference Endpoints
- **Feature store:** Feast (self-hosted) or Tecton (managed)
- **Compute:** Modal, Lambda Labs, or cloud spot instances (GCP/AWS)

## Required Components

- Reproducible training script with deterministic seeding
- Configuration management (Hydra or simple YAML + dataclasses)
- Dataset versioning (DVC or W&B Artifacts)
- Experiment tracking: log hyperparams, metrics, and artifacts every run
- Model evaluation suite with held-out test set (never tune on it)
- Model versioning and promotion gate (dev → staging → production)
- Inference wrapper with pre/post processing co-located with model code
- Model performance monitoring in production (data drift, accuracy degradation)

## Security Checklist

- [ ] Training data access controlled — no PII in feature vectors without anonymization
- [ ] Model artifacts stored in private registry, not public cloud storage
- [ ] Inference API requires authentication (API key or JWT)
- [ ] Dependency pinning: `requirements.txt` or `pyproject.toml` with exact versions
- [ ] CUDA/GPU drivers and base images pinned to specific versions for reproducibility
- [ ] Model file checksums validated before loading in production
- [ ] Adversarial input handling: inference endpoint rejects malformed or oversized inputs

## Testing Checklist

- [ ] Unit tests for data preprocessing and feature engineering functions
- [ ] Integration test: full training loop runs to completion on a small data subset
- [ ] Model behavior tests: known inputs produce expected outputs within tolerance
- [ ] Performance regression test: new model meets or exceeds baseline metrics before promotion
- [ ] Latency benchmark: inference p95 latency within SLA under load
- [ ] Data schema validation: training data contract checked at pipeline entry

## Deployment Checklist

- [ ] Model artifact checksummed and stored in versioned registry before deploy
- [ ] Inference service containerized (Docker) with pinned base image
- [ ] Environment variables and secrets set via secrets manager (not baked into image)
- [ ] Health check and model-ready endpoint implemented
- [ ] Canary or shadow deployment before full rollout
- [ ] Monitoring: input distribution, output distribution, latency, and error rate tracked
- [ ] Rollback procedure: previous model version can be swapped in under 5 minutes

## Starter Templates

| Option | Description | Recommended |
|---|---|---|
| [huggingface/transformers/examples](https://github.com/huggingface/transformers/tree/main/examples) | Official HuggingFace examples for fine-tuning, training, inference | ✅ Best pick |
| [pytorch/examples](https://github.com/pytorch/examples) | Official PyTorch examples for vision, NLP, generative models | |
| [mlflow/mlflow/examples](https://github.com/mlflow/mlflow/tree/master/examples) | MLflow experiment tracking + model registry examples | |

**Best Pick:** [huggingface/transformers/examples](https://github.com/huggingface/transformers/tree/main/examples) — official, covers all major ML tasks (classification, NER, summarization, translation, fine-tuning), actively maintained

## Reference Repositories

- [Lightning-AI/pytorch-lightning](https://github.com/Lightning-AI/pytorch-lightning) — training loop best practices, multi-GPU
- [huggingface/transformers](https://github.com/huggingface/transformers) — fine-tuning and inference patterns for LLMs
- [optuna/optuna](https://github.com/optuna/optuna) — hyperparameter optimization examples

## Official Documentation

- [PyTorch Docs](https://pytorch.org/docs/stable/index.html) — core API, DataLoader, distributed training
- [HuggingFace Docs](https://huggingface.co/docs/transformers) — transformers library documentation
- [Hugging Face Docs](https://huggingface.co/docs) — Transformers, Datasets, Trainer, Hub
- [MLflow Docs](https://mlflow.org/docs/latest/index.html) — experiment tracking and model registry
- [Weights & Biases Docs](https://docs.wandb.ai) — experiment tracking, sweeps, artifacts
- [ONNX Runtime Docs](https://onnxruntime.ai/docs/) — model optimization and inference
- [Optuna Docs](https://optuna.readthedocs.io) — hyperparameter tuning API
