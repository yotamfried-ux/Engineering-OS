# Machine Learning Patterns
> See [pattern-lifecycle.md](../../core/pattern-lifecycle.md) for scoring.

## Overview

Patterns for building reproducible, production-grade ML pipelines. Use these when training models, serving predictions, or managing the lifecycle of model artifacts. They address the most common sources of silent failure in ML systems: data leakage, feature drift between training and serving, unversioned model artifacts, and risky rollouts that affect users before validation is complete.

---

## Pattern: Train/Val/Test Split

**Problem:** Without a controlled, reproducible split, data leakage from the test set inflates evaluation metrics and the model underperforms in production.

**Solution:** Use stratified splitting with a fixed random seed to create three non-overlapping partitions (train / validation / test). The test set is held out until final evaluation — never used for hyperparameter tuning.

**Implementation Notes:**
- Always stratify on the label column so class distributions are preserved in every split.
- Fix the seed at the project level (`RANDOM_SEED = 42`) and store it in config, not hard-coded inline.
- Temporal data requires time-based splitting, not random splitting — future data must never appear in the training window.
- Log split sizes and class distributions so experiments are comparable across runs.

**Example:**
```python
from sklearn.model_selection import train_test_split
import pandas as pd

RANDOM_SEED = 42

def make_splits(
    df: pd.DataFrame,
    label_col: str,
    val_size: float = 0.10,
    test_size: float = 0.10,
) -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    train_val, test = train_test_split(
        df, test_size=test_size, stratify=df[label_col], random_state=RANDOM_SEED
    )
    val_ratio = val_size / (1.0 - test_size)
    train, val = train_test_split(
        train_val, test_size=val_ratio, stratify=train_val[label_col], random_state=RANDOM_SEED
    )
    for name, split in [("train", train), ("val", val), ("test", test)]:
        print(f"{name}: {len(split)} rows | label dist: {split[label_col].value_counts(normalize=True).to_dict()}")
    return train, val, test
```

**Common Mistakes:**
- Fitting the scaler/encoder on the full dataset before splitting — leaks test statistics into training.
- Re-running the split with a different seed mid-project — makes experiments incomparable.
- Using the test set to pick the best model — it must be used once, at the very end.

**Security Considerations:**
- Ensure the test set does not contain PII that is later exposed in evaluation reports.
- Store split indices or seeds in version control so the exact split is reproducible by anyone on the team.

**Testing:**
Assert that `len(train) + len(val) + len(test) == len(df)`. Assert there is no row overlap between splits (`pd.merge` on the index should return an empty frame). Assert class proportions in each split match the full dataset within a small tolerance.

**Score:** TBD (see pattern-lifecycle.md)

---

## Pattern: Feature Store

**Problem:** Features are recomputed independently by the training pipeline and the serving API, causing subtle parity bugs where the model receives different values in production than it was trained on.

**Solution:** Centralize all feature computation in a single store with two access modes: offline (batch, for training) and online (low-latency, for serving). Point-in-time correctness ensures training features use only data that was available at the label timestamp.

**Implementation Notes:**
- Compute features once and persist them; never recompute differently in training vs. serving.
- For point-in-time correctness, join features to labels using `AS OF` semantics — retrieve the feature value as it existed at `event_timestamp`, not the current value.
- Version feature definitions; changing a feature computation without bumping the version will silently break models trained on the old definition.
- Monitor feature distributions in production; alert on drift relative to training-time statistics.

**Example:**
```python
from feast import FeatureStore, Entity, FeatureView, Field
from feast.types import Float32, Int64

# --- Feature definition (registered once) ---
driver_stats_view = FeatureView(
    name="driver_hourly_stats",
    entities=["driver_id"],
    schema=[
        Field(name="trip_completed_count", dtype=Int64),
        Field(name="avg_rating", dtype=Float32),
    ],
    online=True,
    source=driver_stats_source,  # batch source (BigQuery / Parquet)
)

# --- Training (offline, point-in-time correct) ---
store = FeatureStore(repo_path=".")
training_df = store.get_historical_features(
    entity_df=label_df,           # must contain driver_id + event_timestamp
    features=["driver_hourly_stats:trip_completed_count", "driver_hourly_stats:avg_rating"],
).to_df()

# --- Serving (online, low-latency) ---
feature_vector = store.get_online_features(
    features=["driver_hourly_stats:trip_completed_count", "driver_hourly_stats:avg_rating"],
    entity_rows=[{"driver_id": 1001}],
).to_dict()
```

**Common Mistakes:**
- Computing the same feature with different logic in training vs. the serving API.
- Joining on the latest feature value instead of the value at event time — introduces future leakage.
- Not versioning feature views — a silent recompute breaks all models trained on the old version.

**Security Considerations:**
- Apply row-level access control to the feature store; not every model or team should read every feature.
- Audit which features are used in which models, especially features derived from sensitive attributes.

**Testing:**
Write an integration test that materializes a known feature value, then fetches it via the online store and asserts it matches. Write a point-in-time test that verifies the offline store returns the historically correct value, not the current one.

**Score:** TBD (see pattern-lifecycle.md)

---

## Pattern: Model Registry

**Problem:** Teams lose track of which model artifact is deployed where, making rollbacks slow and incident root-cause analysis difficult.

**Solution:** Register every trained model as a versioned artifact in a central registry with explicit stage transitions: `None → Staging → Production`. Deployments pull from the registry by stage, never by file path.

**Implementation Notes:**
- Store metadata alongside the artifact: training dataset version, git commit, hyperparameters, and evaluation metrics.
- Gate the `Staging → Production` transition on a minimum performance threshold and a manual approval step.
- Never overwrite an existing model version — always create a new version. Rollback is then a stage transition, not a re-deploy.
- Tag models with the experiment that produced them so the full lineage is traceable.

**Example:**
```python
import mlflow
from mlflow.tracking import MlflowClient

MODEL_NAME = "churn_classifier"
PRODUCTION_F1_THRESHOLD = 0.82

def register_and_promote(run_id: str, val_f1: float) -> None:
    client = MlflowClient()

    # Register the artifact from a completed run
    model_uri = f"runs:/{run_id}/model"
    mv = mlflow.register_model(model_uri, MODEL_NAME)
    version = mv.version

    client.set_model_version_tag(MODEL_NAME, version, "val_f1", str(val_f1))

    # Promote to Staging automatically; Production requires human approval
    client.transition_model_version_stage(MODEL_NAME, version, stage="Staging")
    print(f"Model v{version} → Staging (val_f1={val_f1:.3f})")

    if val_f1 >= PRODUCTION_F1_THRESHOLD:
        print(f"val_f1 meets threshold — awaiting manual approval for Production.")
    else:
        print(f"val_f1 below {PRODUCTION_F1_THRESHOLD} — not promoting to Production.")

def load_production_model():
    return mlflow.pyfunc.load_model(f"models:/{MODEL_NAME}/Production")
```

**Common Mistakes:**
- Promoting directly to Production without a Staging validation step.
- Loading models from a file path in serving code — bypasses the registry and breaks rollback.
- Not recording evaluation metrics in the registry — makes it impossible to compare versions later.

**Security Considerations:**
- Restrict who can transition models to Production; use role-based access in the registry.
- Scan model artifacts for embedded secrets or data (some serialization formats can embed training samples).

**Testing:**
Write a test that registers a model, asserts it appears in Staging, then asserts that loading by stage returns the correct version. Test that a model below the threshold is blocked from promotion.

**Score:** TBD (see pattern-lifecycle.md)

---

## Pattern: Shadow Mode Deployment

**Problem:** Rolling out a new model directly to users risks a silent accuracy regression that only manifests on real production traffic, not on held-out test data.

**Solution:** Run the new model in parallel alongside the current production model. The production model's prediction is served to the user; the shadow model's prediction is logged but not returned. Compare metrics offline before promoting.

**Implementation Notes:**
- Shadow inference must not block the production response — run it asynchronously or fire-and-forget.
- Log shadow predictions with enough context (input features, production prediction, shadow prediction, ground truth when available) to compute offline metrics.
- Define promotion criteria before running shadow mode, not after observing results.
- Cap shadow traffic at 100% only when the shadow model is stable; start at a sample if inference cost is high.

**Example:**
```python
import asyncio
import logging

logger = logging.getLogger(__name__)

async def predict_with_shadow(features: dict) -> dict:
    """Return production prediction; log shadow prediction asynchronously."""
    prod_result = await production_model.predict(features)

    # Fire-and-forget: shadow must not delay the response
    asyncio.create_task(_log_shadow(features, prod_result["label"]))

    return prod_result

async def _log_shadow(features: dict, prod_label: str) -> None:
    try:
        shadow_result = await shadow_model.predict(features)
        logger.info(
            "shadow_prediction",
            extra={
                "prod_label": prod_label,
                "shadow_label": shadow_result["label"],
                "shadow_confidence": shadow_result["confidence"],
                "features_hash": hash(str(features)),
            },
        )
    except Exception as exc:  # shadow failure must never surface to users
        logger.warning("shadow_model_error", extra={"error": str(exc)})
```

**Common Mistakes:**
- Allowing shadow model errors to propagate to the user — shadow failures must be swallowed.
- Running shadow inference synchronously — adds latency to every production request.
- Evaluating shadow metrics on a biased sample (e.g., only successful requests).

**Security Considerations:**
- Shadow logs contain full input features — apply the same data-retention and access controls as production logs.
- Do not include raw PII in shadow log payloads; hash or tokenize identifiers.

**Testing:**
Write a test that asserts the production prediction is returned even when the shadow model raises an exception. Assert that shadow logs are emitted for every request. Assert that shadow inference does not increase p99 latency beyond an acceptable threshold.

**Score:** TBD (see pattern-lifecycle.md)
