# Harvey / Sellbird

Category: sales automation, external systems. Canonical upstream: https://github.com/ethanplusai/sellbird. Harvey renamed to Sellbird in v0.4.0; official confirmation https://sellbird.ai/harvey/ and https://github.com/ethanplusai/sellbird/releases/tag/v0.4.0.

Download and install on demand:

```sh
git clone https://github.com/ethanplusai/sellbird.git
cd sellbird
git checkout v0.4.0
python3 -m venv .venv
. .venv/bin/activate
pip install -e .
sellbird --help
```

Python 3.11+, authorized Claude Code or Codex CLI. AGPL-3.0 from v0.4.0; review obligations before deployment. Review dependencies ahead of installation. Use synthetic data and draft-only approval; no mailbox access, live prospecting or sending without explicit authorization and legal review. Runtime not tested by Engineering OS.
