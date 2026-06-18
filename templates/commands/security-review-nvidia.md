# /security-review-nvidia

Run a security review of the current branch's changes using NVIDIA NIM (Llama/Nemotron).
Requires `NVIDIA_API_KEY` in the environment (starts with `nvapi-`).

## Steps

1. Check that `NVIDIA_API_KEY` is set:
```bash
echo "NVIDIA_API_KEY is ${NVIDIA_API_KEY:+set}${NVIDIA_API_KEY:-NOT SET}"
```

2. Get the diff to review (staged + unstaged changes against main/master, or the last commit):
```bash
git diff main...HEAD 2>/dev/null || git diff HEAD~1 HEAD
```

3. Run the security review script:
```bash
git diff main...HEAD 2>/dev/null | python "${ENGINEERING_OS_HOME:-$(git rev-parse --show-toplevel)/engineering-os}/scripts/security-review-nvidia.py"
```

4. Display the results in a readable format. If findings are CRITICAL or HIGH severity, highlight them clearly and recommend blocking merge until resolved.

## Notes

- The script exits 0 even when findings exist — the output itself communicates severity.
- To override the model: `NVIDIA_MODEL=meta/llama-3.1-405b-instruct python scripts/security-review-nvidia.py`
- For JSON output (CI/scripting use): add `--output-json` flag.
- Free-tier rate limit: ~5 req/min. For large diffs, consider chunking or upgrading.
- This command does NOT post GitHub PR comments — it runs locally in your Claude Code session.
  For automated PR comments, use the GitHub Actions template at:
  `templates/github-actions/security-review-nvidia.yml`
