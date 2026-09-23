# Activation — Laya-CoreML

## Upstream

- Canonical repository: `mizorewww/laya-coreml`
- Package: `laya-coreml`
- Supported target stated upstream: Apple Silicon, macOS 15+, Python 3.11–3.13.

## Install

For inference:

```bash
pip install laya-coreml
```

For the upstream Snake demo:

```bash
pip install 'laya-coreml[demo]'
hf download aac6fef/laya-multilingual-coreml-ane --local-dir models/snake
laya-coreml-snake --model ./models/snake
```

Follow the current upstream README/release documentation when selecting or pinning model artifacts.

## Verify

On a supported target host, load the chosen model and run a representative `predict` call. Confirm that the result contains the expected typed answer and probabilities.

For source-level upstream verification, use the upstream CI commands rather than inventing an Engineering-OS test sequence. Its current portable CI installs the project development extras and runs:

```bash
ruff check .
ruff format --check .
pytest -q
python -m build
python -m twine check --strict dist/*
```

Hardware-specific Core ML/ANE behavior and published performance claims require a supported Apple Silicon host and the upstream benchmark procedure; portable CI alone does not prove them.

## Secrets and network

No universal inference credential is required after model artifacts are local. Initial package/model retrieval requires network access and may require Hugging Face access according to the selected artifact and host policy. Never commit access tokens.

## Removal

Uninstall the Python package with the environment's package manager. Remove downloaded model caches/artifacts separately only when they are no longer required by other projects.
