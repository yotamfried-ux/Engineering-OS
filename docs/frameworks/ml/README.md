# ML Frameworks & Platforms

## Overview
Consult this guide when starting a machine learning project or selecting tools for an ML pipeline. Key dimensions: problem type (deep learning vs tabular/structured), stage (research/prototyping vs production), team size, and infrastructure constraints.

**Decision heuristic by problem type:**
- Deep learning (NLP, vision, generative) → PyTorch (research) or TensorFlow/Keras (production serving at scale)
- Tabular/structured data, classification/regression → XGBoost or LightGBM (then validate with Scikit-Learn baselines)
- General ML preprocessing + classical algorithms → Scikit-Learn
- Experiment tracking + model registry → MLflow
- Large-scale ML pipeline orchestration on Kubernetes → Kubeflow

**Layering:** These tools compose. A typical stack: Scikit-Learn (preprocessing) + XGBoost (model) + MLflow (tracking) + Kubeflow (orchestration).

## Frameworks

### PyTorch
**Type:** Deep learning framework  
**Language:** Python (C++ backend)  
**Best For:** Research, NLP, computer vision, generative AI, fine-tuning large models  
**Official Docs:** https://pytorch.org/docs/  
**GitHub:** https://github.com/pytorch/pytorch  
**Key Strengths:**
- Dynamic computation graph (define-by-run) makes debugging and experimentation natural
- Dominant in academic research and increasingly in production (Meta, OpenAI, Hugging Face ecosystem)
- First-class support for distributed training via DDP (DistributedDataParallel) and FSDP (Fully Sharded Data Parallel)
- Vast ecosystem: Hugging Face Transformers, Lightning, TorchVision, TorchAudio
- TorchScript and ONNX export for deployment outside Python
**Watch Out For:**
- Production serving requires additional tooling (TorchServe, Triton, or ONNX Runtime) — no built-in high-performance server
- FSDP/DDP configuration has a steep learning curve for multi-node setups
- Memory management (especially with large models) requires explicit attention

---

### TensorFlow / Keras
**Type:** Deep learning framework + high-level API  
**Language:** Python (C++ backend)  
**Best For:** Production serving at scale, mobile/edge deployment (TFLite), teams that need an opinionated end-to-end stack  
**Official Docs:** https://www.tensorflow.org/api_docs  
**GitHub:** https://github.com/tensorflow/tensorflow  
**Key Strengths:**
- TF Serving provides a battle-tested, high-throughput model server out of the box
- Keras (https://keras.io/) offers a clean, high-level API for rapid model building and is now the recommended interface
- TFLite and TF.js enable deployment to mobile, embedded, and browser targets
- TensorBoard is a mature, integrated visualization tool for training metrics
- Strong Google Cloud / Vertex AI integration for large-scale training jobs
**Watch Out For:**
- Has ceded research mindshare to PyTorch; fewer cutting-edge model implementations appear first in TF
- Keras 3 (multi-backend) is a significant API shift from Keras 2/TF 2.x — check which version your dependencies target
- Eager vs. graph mode tracing (`@tf.function`) can introduce subtle bugs if not understood

---

### XGBoost
**Type:** Gradient boosting library  
**Language:** Python, R, Julia, Scala, Java (C++ core)  
**Best For:** Tabular data, classification, regression, ranking; Kaggle-style competitions; when training speed and accuracy on structured data matter  
**Official Docs:** https://xgboost.readthedocs.io/  
**GitHub:** https://github.com/dmlc/xgboost  
**Key Strengths:**
- Extremely strong out-of-the-box performance on tabular data; often beats deep learning on structured datasets
- Supports GPU acceleration (`device="cuda"`) for fast training on large datasets
- Native handling of missing values — no imputation required
- Scikit-Learn compatible API (`XGBClassifier`, `XGBRegressor`) for easy pipeline integration
- Distributed training via Dask, Spark, or Ray
**Watch Out For:**
- Hyperparameter tuning (learning rate, depth, subsample) is required to get peak performance; defaults are not always optimal
- Less interpretable than linear models; use SHAP for explainability
- For very high-cardinality categoricals, LightGBM's native categorical handling may outperform

---

### LightGBM
**Type:** Gradient boosting library  
**Language:** Python, R, C++  
**Best For:** Large tabular datasets where training speed is critical; high-cardinality categorical features; memory-constrained environments  
**Official Docs:** https://lightgbm.readthedocs.io/  
**GitHub:** https://github.com/microsoft/LightGBM  
**Key Strengths:**
- Leaf-wise tree growth (vs. depth-wise in XGBoost) yields faster convergence and often better accuracy on large datasets
- Native categorical feature support without one-hot encoding
- Significantly faster training than XGBoost on many benchmarks, especially with large row counts
- Low memory footprint; handles datasets that don't fit in RAM via data binning
- Distributed training via MPI, Socket, or integration with Dask/Spark
**Watch Out For:**
- Leaf-wise growth can overfit on small datasets; use `num_leaves` and `min_data_in_leaf` carefully
- Less community material than XGBoost; some edge cases are less documented
- GPU support exists but is less mature than XGBoost's GPU path

---

### Scikit-Learn
**Type:** Classical ML library  
**Language:** Python  
**Best For:** Baselines, data preprocessing pipelines, classical algorithms (SVM, logistic regression, random forests, k-means), model evaluation  
**Official Docs:** https://scikit-learn.org/stable/  
**GitHub:** https://github.com/scikit-learn/scikit-learn  
**Key Strengths:**
- Unified `fit` / `predict` / `transform` API across all estimators makes swapping algorithms trivial
- `Pipeline` and `ColumnTransformer` enable reproducible, leak-free preprocessing
- Comprehensive suite of model evaluation utilities (cross-validation, metrics, calibration)
- Excellent documentation with user guide examples for every algorithm
- Integrates seamlessly with XGBoost, LightGBM, and MLflow via the sklearn-compatible API
**Watch Out For:**
- Single-node only — does not scale beyond available RAM/CPU; use Dask-ML or Spark MLlib for distributed workloads
- No native GPU support for training
- Not suitable for deep learning; use as a complement to PyTorch/TensorFlow, not a replacement

---

### MLflow
**Type:** ML experiment tracking, model registry, and deployment platform  
**Language:** Python (server and client), REST API  
**Best For:** Logging parameters, metrics, and artifacts across experiments; model versioning and registry; serving models via MLflow Models  
**Official Docs:** https://mlflow.org/docs/latest/  
**GitHub:** https://github.com/mlflow/mlflow  
**Key Strengths:**
- Framework-agnostic: works with PyTorch, TensorFlow, Scikit-Learn, XGBoost, LightGBM, and custom models
- Model Registry provides versioned model storage with stage transitions (Staging → Production)
- `mlflow.autolog()` automatically captures parameters and metrics for supported frameworks with one line
- MLflow Models packaging enables deployment to REST endpoints, Databricks, SageMaker, Azure ML, and Kubernetes
- Open-source with self-hostable tracking server; also available as a managed service on Databricks
**Watch Out For:**
- Not a pipeline orchestrator — does not manage compute, scheduling, or multi-step DAGs (use Kubeflow or Prefect for that)
- UI is functional but minimal; large experiment volumes benefit from a dedicated DB backend (PostgreSQL) and artifact store (S3/GCS)
- Access control in the open-source version is limited; enterprise features require Databricks

---

### Kubeflow
**Type:** ML pipeline orchestration platform on Kubernetes  
**Language:** Python (SDK), YAML (pipeline definitions)  
**Best For:** Multi-step ML workflows at scale; teams already on Kubernetes; end-to-end MLOps pipelines (data prep → training → evaluation → deployment)  
**Official Docs:** https://www.kubeflow.org/docs/  
**GitHub:** https://github.com/kubeflow/kubeflow  
**Key Strengths:**
- Runs on any Kubernetes cluster (on-prem, GKE, EKS, AKS) — no cloud vendor lock-in
- Kubeflow Pipelines enables DAG-based pipeline definitions in Python with caching, artifact lineage, and a visual UI
- Built-in components for distributed training (PyTorch Operator, TensorFlow Job, MPI Operator)
- Integrates with KServe (formerly KFServing) for scalable, standardized model serving on K8s
- Katib provides automated hyperparameter tuning and neural architecture search
**Watch Out For:**
- High operational complexity — requires Kubernetes expertise to install, maintain, and debug
- Significant infrastructure overhead; overkill for small teams or single-node workloads (consider MLflow + simple scripts instead)
- Cold-start latency for pipeline steps due to container spin-up; not suitable for latency-sensitive interactive workflows

---

## Framework Layer Reference

| Layer | Tool | Primary Role |
|---|---|---|
| Data preprocessing | Scikit-Learn | Transformers, pipelines, validation |
| Classical ML | Scikit-Learn, XGBoost, LightGBM | Training, inference |
| Deep Learning | PyTorch, TensorFlow/Keras | Neural nets, fine-tuning |
| Experiment tracking | MLflow | Params, metrics, artifacts, model registry |
| Pipeline orchestration | Kubeflow | Multi-step ML workflows on K8s |

## Research vs Production Readiness

| Framework | Research | Production Serving | Scalable Training |
|---|---|---|---|
| PyTorch | ✓✓ | partial (TorchServe) | ✓ (DDP, FSDP) |
| TensorFlow/Keras | ✓ | ✓✓ (TF Serving) | ✓ |
| XGBoost | ✓ | ✓ | ✓ (distributed) |
| LightGBM | ✓ | ✓ | ✓ (distributed) |
| Scikit-Learn | ✓ | ✓ (simple) | ✗ (single-node) |
| MLflow | N/A | ✓ (MLflow Models) | N/A |
| Kubeflow | ✗ | ✓ | ✓✓ |

## Official Starter Templates

| Framework | Starter Repository | Stars |
|---|---|---|
| PyTorch | [pytorch/examples](https://github.com/pytorch/examples) | 23k+ |
| HuggingFace | [huggingface/transformers/examples](https://github.com/huggingface/transformers/tree/main/examples) | 140k+ |
| MLflow | [mlflow/mlflow/examples](https://github.com/mlflow/mlflow/tree/master/examples) | 20k+ |
| Scikit-Learn | [scikit-learn/scikit-learn/examples](https://github.com/scikit-learn/scikit-learn/tree/main/examples) | 60k+ |
