#!/usr/bin/env python3
"""
code_reviewer.py — Comprehensive AI-powered code review agent

Scans a repository in 4 phases:
  1. Context    — understand project from docs/config
  2. Structure  — map file tree, identify each file's role
  3. Deep review — review every file line-by-line with full context
  4. Report     — produce prioritized markdown report

Usage:
  python3 code_reviewer.py --repo /path/to/project
  python3 code_reviewer.py --repo /path/to/project --output ./reports --model nvidia/llama-3.3-nemotron-super-49b-v1
  python3 code_reviewer.py --repo /path/to/project --resume  # continue interrupted scan

Requirements:
  pip install requests pyyaml

Environment:
  NVIDIA_API_KEY or Nemotron_api_key  — Nvidia NIM API key
"""

import os
import re
import sys
import json
import time
import argparse
import textwrap
from pathlib import Path
from datetime import datetime

try:
    import requests
except ImportError:
    print("ERROR: 'requests' not installed. Run: pip install requests", file=sys.stderr)
    sys.exit(1)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

NVIDIA_API_BASE = "https://integrate.api.nvidia.com/v1"
DEFAULT_MODEL = "nvidia/llama-3.3-nemotron-super-49b-v1"
FAST_MODEL = "nvidia/llama-3.1-nemotron-nano-8b-v1"  # for structure phase

CODE_EXTENSIONS = {
    ".py", ".js", ".ts", ".tsx", ".jsx", ".go", ".rs", ".java",
    ".rb", ".c", ".h", ".cpp", ".hpp", ".cc", ".cs", ".kt", ".swift",
    ".php", ".scala", ".lua", ".sh", ".bash", ".zsh",
    ".sql", ".graphql", ".gql",
    ".yaml", ".yml", ".toml", ".env.example",
}

DOC_FILENAMES = {
    "README.md", "README.txt", "README.rst", "CLAUDE.md",
    "ARCHITECTURE.md", "DESIGN.md", "OVERVIEW.md",
    "package.json", "pyproject.toml", "Cargo.toml", "go.mod",
    "requirements.txt", "Pipfile", ".env.example", "docker-compose.yml",
    "Dockerfile",
}

SKIP_DIRS = {
    "node_modules", ".git", "__pycache__", ".next", "dist", "build",
    ".venv", "venv", "env", "vendor", ".idea", ".vscode", "coverage",
    "graphify-out", ".cache", ".turbo", ".expo", "out", ".output",
    "storybook-static", "public",
}

SKIP_EXTENSIONS = {
    ".lock", ".log", ".png", ".jpg", ".jpeg", ".gif", ".ico", ".svg",
    ".woff", ".woff2", ".ttf", ".eot", ".mp4", ".mp3", ".zip", ".tar",
    ".gz", ".pdf", ".min.js", ".min.css", ".map",
}

MAX_FILE_LINES = 1500   # chunk files larger than this
CHUNK_OVERLAP = 50      # overlap between chunks (lines)
MAX_CONTEXT_CHARS = 3000  # truncate project context if too long
MAX_RETRY = 4
RATE_LIMIT_DELAY = 2    # seconds between API calls


# ---------------------------------------------------------------------------
# API
# ---------------------------------------------------------------------------

def get_api_key() -> str:
    """Return the Nvidia NIM API key from env (NVIDIA_API_KEY or Nemotron_api_key)."""
    key = os.environ.get("NVIDIA_API_KEY") or os.environ.get("Nemotron_api_key")
    if not key:
        print("ERROR: Set NVIDIA_API_KEY or Nemotron_api_key env var.", file=sys.stderr)
        sys.exit(1)
    return key


def call_api(messages: list, model: str, api_key: str, temperature: float = 0.1,
             max_tokens: int = 4096) -> str:
    """Call Nvidia NIM API with exponential backoff on rate limits."""
    url = f"{NVIDIA_API_BASE}/chat/completions"
    payload = {
        "model": model,
        "messages": messages,
        "temperature": temperature,
        "max_tokens": max_tokens,
    }
    delay = RATE_LIMIT_DELAY
    for attempt in range(MAX_RETRY):
        try:
            resp = requests.post(
                url,
                headers={"Authorization": f"Bearer {api_key}",
                         "Content-Type": "application/json"},
                json=payload,
                timeout=120,
            )
            if resp.status_code == 429:
                wait = delay * (2 ** attempt)
                print(f"  ⏳ Rate limit — waiting {wait}s...", flush=True)
                time.sleep(wait)
                continue
            resp.raise_for_status()
            return resp.json()["choices"][0]["message"]["content"]
        except requests.exceptions.ConnectionError as e:
            print(f"  ❌ Connection error: {e}", file=sys.stderr)
            print("  → Is integrate.api.nvidia.com reachable? Check network egress settings.",
                  file=sys.stderr)
            if attempt == MAX_RETRY - 1:
                raise
            time.sleep(delay * (2 ** attempt))
        except Exception as e:
            if attempt == MAX_RETRY - 1:
                raise
            time.sleep(delay * (2 ** attempt))
    raise RuntimeError("API call failed after all retries")


def extract_json(text: str) -> list:
    """Extract JSON array from LLM response (handles markdown code fences).

    Returns [] for both empty results and parse failures; logs to stderr on parse
    failure so callers can distinguish no-issues-found from malformed LLM output.
    """
    patterns = [
        r"```json\s*(\[.*\])\s*```",
        r"```\s*(\[.*\])\s*```",
        r"(\[.*\])",
    ]
    found_candidate = False
    for pattern in patterns:
        m = re.search(pattern, text, re.DOTALL)
        if m:
            found_candidate = True
            try:
                return json.loads(m.group(1))
            except json.JSONDecodeError:
                continue
    # Try the whole response
    try:
        return json.loads(text.strip())
    except json.JSONDecodeError:
        if found_candidate:
            print("  ⚠️  JSON parse failed (LLM returned malformed array)", file=sys.stderr)
        return []


# ---------------------------------------------------------------------------
# Phase 1: Context
# ---------------------------------------------------------------------------

def load_project_context(repo: Path) -> str:
    """Read key docs and config files to build project context."""
    parts = []

    # Look for doc files in root and docs/
    search_dirs = [repo, repo / "docs", repo / "documentation", repo / "doc"]
    for d in search_dirs:
        if not d.exists():
            continue
        for f in d.iterdir():
            if f.is_file() and f.name in DOC_FILENAMES:
                try:
                    content = f.read_text(errors="replace")
                    # Truncate large files
                    if len(content) > 4000:
                        content = content[:4000] + "\n... [truncated]"
                    parts.append(f"=== {f.name} ===\n{content}")
                except Exception:
                    pass

    # Also check for .env.example anywhere in root
    for name in [".env.example", ".env.sample", ".env.template"]:
        f = repo / name
        if f.exists():
            try:
                parts.append(f"=== {name} ===\n{f.read_text(errors='replace')[:1000]}")
            except Exception:
                pass

    raw = "\n\n".join(parts)
    if len(raw) > MAX_CONTEXT_CHARS * 3:
        raw = raw[: MAX_CONTEXT_CHARS * 3] + "\n... [context truncated]"
    return raw


def summarize_context(raw_context: str, api_key: str, model: str) -> str:
    """Ask LLM to produce a 300-word project summary for use in later prompts."""
    if not raw_context.strip():
        return "No documentation found. Infer project purpose from code structure."

    messages = [
        {
            "role": "system",
            "content": (
                "You are a senior engineer. Read the project files below and produce "
                "a concise technical summary (max 300 words) covering: "
                "1) What this project does, 2) Tech stack, 3) Key modules/services, "
                "4) Any stated architectural patterns or constraints."
            ),
        },
        {"role": "user", "content": raw_context},
    ]
    return call_api(messages, model, api_key, temperature=0, max_tokens=600)


# ---------------------------------------------------------------------------
# Phase 2: Structure
# ---------------------------------------------------------------------------

def collect_files(repo: Path) -> list[Path]:
    """Walk repo and collect all reviewable code files."""
    files = []
    for path in sorted(repo.rglob("*")):
        rel_parts = path.parts[len(repo.parts):]
        # Only check directory segments (not filename) for dotfile/skip-dir filtering
        # so files like .env.example are not wrongly excluded by their leading dot.
        dir_parts = rel_parts[:-1]
        if any(p in SKIP_DIRS or p.startswith(".") for p in dir_parts):
            continue
        if not path.is_file():
            continue
        full_ext = "".join(path.suffixes).lower()
        if path.suffix.lower() in SKIP_EXTENSIONS or full_ext in SKIP_EXTENSIONS:
            continue
        if path.suffix.lower() not in CODE_EXTENSIONS and path.name not in DOC_FILENAMES:
            continue
        # Skip files under 50 bytes
        try:
            if path.stat().st_size < 50:
                continue
        except Exception:
            continue
        files.append(path)
    return files


def build_file_tree(files: list[Path], repo: Path) -> str:
    """Generate a compact file tree string."""
    lines = []
    for f in files:
        rel = f.relative_to(repo)
        lines.append(str(rel))
    return "\n".join(lines)


def identify_file_roles(files: list[Path], repo: Path, project_summary: str,
                        api_key: str, model: str) -> dict[str, str]:
    """Ask LLM to identify the role/purpose of each file in one batch call."""
    file_tree = build_file_tree(files, repo)
    messages = [
        {
            "role": "system",
            "content": (
                "You are a senior engineer analyzing a codebase. "
                "Given the project summary and file list, identify the purpose of each file. "
                "Return a JSON object mapping relative file path → one-sentence role description. "
                "Be specific: not 'utility functions' but 'JWT token validation helpers used by auth middleware'."
            ),
        },
        {
            "role": "user",
            "content": (
                f"PROJECT SUMMARY:\n{project_summary}\n\n"
                f"FILES:\n{file_tree}\n\n"
                "Return JSON: {{\"path/to/file.ts\": \"one-sentence role\", ...}}"
            ),
        },
    ]
    raw = call_api(messages, model, api_key, temperature=0, max_tokens=4096)
    # Extract JSON object
    m = re.search(r"\{.*\}", raw, re.DOTALL)
    if m:
        try:
            return json.loads(m.group(0))
        except json.JSONDecodeError:
            pass
    return {}


# ---------------------------------------------------------------------------
# Phase 3: Deep Review
# ---------------------------------------------------------------------------

REVIEW_SYSTEM_PROMPT = """\
You are an expert code reviewer with a focus on catching bugs that AI-generated code \
commonly introduces. Your job is to find REAL problems — not style preferences, not \
theoretical concerns, but actual bugs, security holes, architectural mistakes, and \
silent failures that would prevent this project from working correctly end-to-end.

Categories:
  SYNTAX         — invalid syntax, import errors, typos in identifiers
  LOGIC_BUG      — wrong logic, off-by-one, wrong condition, silent wrong result
  SILENT_FAILURE — code that runs but produces wrong/missing output with no error
  SECURITY       — injection, auth bypass, secrets exposure, unvalidated input, CORS
  ARCHITECTURE   — wrong layer, tight coupling, SRP violation, wrong pattern for context
  PERFORMANCE    — N+1 queries, blocking I/O in hot path, memory leak, unnecessary re-renders
  ERROR_HANDLING — swallowed exceptions, missing error path, crash on null/undefined
  AI_SMELL       — plausible-looking but wrong AI-generated implementation
  INCOMPLETE     — TODO/placeholder left in place, half-implemented feature, dead import

Severity:
  CRITICAL — production failure, data loss, security breach
  HIGH     — breaks a key feature, silent data corruption, serious security risk
  MEDIUM   — wrong behavior in edge cases, poor error messages, performance hit
  LOW      — minor bug, confusing code, dead code

Return ONLY a JSON array. If no issues found, return [].
Each item: {
  "line": <int or null>,
  "severity": "CRITICAL|HIGH|MEDIUM|LOW",
  "category": "<one of the categories above>",
  "description": "<specific, actionable — what exactly is wrong>",
  "why": "<why this causes a problem>",
  "fix": "<concrete fix suggestion>"
}
"""

def chunk_file(lines: list[str]) -> list[tuple[int, list[str]]]:
    """Split file into chunks of MAX_FILE_LINES with overlap. Returns (start_line, lines) tuples."""
    if len(lines) <= MAX_FILE_LINES:
        return [(1, lines)]
    chunks = []
    i = 0
    while i < len(lines):
        chunk = lines[i: i + MAX_FILE_LINES]
        chunks.append((i + 1, chunk))
        i += MAX_FILE_LINES - CHUNK_OVERLAP
    return chunks


def review_file(filepath: Path, repo: Path, project_summary: str,
                file_role: str, api_key: str, model: str) -> list[dict]:
    """Review a single file. Returns list of issue dicts."""
    try:
        content = filepath.read_text(errors="replace")
    except Exception as e:
        return [{"line": None, "severity": "LOW", "category": "SYNTAX",
                 "description": f"Could not read file: {e}", "why": "", "fix": ""}]

    lines = content.splitlines()
    rel_path = str(filepath.relative_to(repo))
    ext = filepath.suffix.lower().lstrip(".")
    if ext in ("ts", "tsx"):
        lang = "typescript"
    elif ext in ("js", "jsx"):
        lang = "javascript"
    elif ext == "py":
        lang = "python"
    else:
        lang = ext or "text"

    all_issues = []
    chunks = chunk_file(lines)
    for (start_line, chunk_lines) in chunks:
        code_block = "\n".join(
            f"{start_line + i:4d}: {line}"
            for i, line in enumerate(chunk_lines)
        )
        chunk_label = (
            f"lines {start_line}–{start_line + len(chunk_lines) - 1}"
            if len(chunks) > 1
            else "full file"
        )

        messages = [
            {"role": "system", "content": REVIEW_SYSTEM_PROMPT},
            {
                "role": "user",
                "content": (
                    f"PROJECT CONTEXT:\n{project_summary}\n\n"
                    f"FILE: {rel_path} ({chunk_label})\n"
                    f"PURPOSE: {file_role or 'unknown'}\n"
                    f"LANGUAGE: {lang}\n\n"
                    f"CODE:\n```{lang}\n{code_block}\n```\n\n"
                    "Find ALL real issues. Return JSON array only."
                ),
            },
        ]
        try:
            raw = call_api(messages, model, api_key, temperature=0.1, max_tokens=4096)
            issues = extract_json(raw)
            for issue in issues:
                issue["file"] = rel_path
                # Adjust line numbers for chunks
                if issue.get("line") and len(chunks) > 1:
                    # line numbers in the code block are already absolute
                    pass
            all_issues.extend(issues)
            time.sleep(RATE_LIMIT_DELAY)
        except Exception as e:
            all_issues.append({
                "file": rel_path,
                "line": None,
                "severity": "LOW",
                "category": "SYNTAX",
                "description": f"Review failed: {e}",
                "why": "",
                "fix": "",
            })

    return all_issues


# ---------------------------------------------------------------------------
# Phase 4: Report
# ---------------------------------------------------------------------------

SEVERITY_ORDER = {"CRITICAL": 0, "HIGH": 1, "MEDIUM": 2, "LOW": 3}
SEVERITY_EMOJI = {"CRITICAL": "🔴", "HIGH": "🟠", "MEDIUM": "🟡", "LOW": "🔵"}


def generate_report(all_issues: list[dict], project_summary: str,
                    repo: Path, scan_meta: dict) -> str:
    """Generate a comprehensive markdown report from aggregated issues."""
    now = datetime.now().strftime("%Y-%m-%d %H:%M")
    total = len(all_issues)
    by_severity: dict[str, list] = {"CRITICAL": [], "HIGH": [], "MEDIUM": [], "LOW": []}
    by_file: dict[str, list] = {}

    for issue in all_issues:
        sev = issue.get("severity", "LOW").upper()
        if sev not in by_severity:
            sev = "LOW"
        by_severity[sev].append(issue)
        f = issue.get("file", "unknown")
        by_file.setdefault(f, []).append(issue)

    # Sort each severity group by file then line
    for sev in by_severity:
        by_severity[sev].sort(key=lambda x: (x.get("file", ""), x.get("line") or 0))

    lines = []
    lines.append("# Code Review Report")
    lines.append("")
    lines.append(f"**Repository:** `{repo.name}`  ")
    lines.append(f"**Scanned:** {now}  ")
    lines.append(f"**Files reviewed:** {scan_meta.get('files_reviewed', '?')}  ")
    lines.append(f"**Model:** {scan_meta.get('model', '?')}  ")
    lines.append("")
    lines.append("---")
    lines.append("")

    # Executive summary
    lines.append("## Executive Summary")
    lines.append("")
    lines.append("| Severity | Count |")
    lines.append("|----------|-------|")
    for sev in ["CRITICAL", "HIGH", "MEDIUM", "LOW"]:
        count = len(by_severity[sev])
        lines.append(f"| {SEVERITY_EMOJI[sev]} {sev} | {count} |")
    lines.append(f"| **TOTAL** | **{total}** |")
    lines.append("")

    # Top issues by category
    categories: dict[str, int] = {}
    for issue in all_issues:
        cat = issue.get("category", "OTHER")
        categories[cat] = categories.get(cat, 0) + 1
    if categories:
        lines.append("### Issues by Category")
        lines.append("")
        for cat, count in sorted(categories.items(), key=lambda x: -x[1]):
            lines.append(f"- **{cat}**: {count}")
        lines.append("")

    lines.append("### Project Context")
    lines.append("")
    lines.append(f"> {project_summary[:500].replace(chr(10), ' ')}")
    lines.append("")
    lines.append("---")
    lines.append("")

    # Issues by severity
    for sev in ["CRITICAL", "HIGH", "MEDIUM", "LOW"]:
        issues = by_severity[sev]
        if not issues:
            continue
        lines.append(f"## {SEVERITY_EMOJI[sev]} {sev} Issues ({len(issues)})")
        lines.append("")
        for issue in issues:
            file_ref = issue.get("file", "?")
            line_ref = f":{issue['line']}" if issue.get("line") else ""
            cat = issue.get("category", "")
            desc = issue.get("description", "")
            why = issue.get("why", "")
            fix = issue.get("fix", "")
            lines.append(f"### `{file_ref}{line_ref}` — {cat}")
            lines.append("")
            lines.append(f"**Problem:** {desc}")
            lines.append("")
            if why:
                lines.append(f"**Why it matters:** {why}")
                lines.append("")
            if fix:
                lines.append(f"**Fix:** {fix}")
            lines.append("")
            lines.append("---")
            lines.append("")

    # Per-file summary
    lines.append("## Per-File Summary")
    lines.append("")
    lines.append("| File | CRIT | HIGH | MED | LOW | Total |")
    lines.append("|------|------|------|-----|-----|-------|")
    for filepath, file_issues in sorted(by_file.items()):
        c = sum(1 for i in file_issues if i.get("severity", "").upper() == "CRITICAL")
        h = sum(1 for i in file_issues if i.get("severity", "").upper() == "HIGH")
        m = sum(1 for i in file_issues if i.get("severity", "").upper() == "MEDIUM")
        low = sum(1 for i in file_issues if i.get("severity", "").upper() == "LOW")
        lines.append(f"| `{filepath}` | {c} | {h} | {m} | {low} | {len(file_issues)} |")

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Progress / Resume
# ---------------------------------------------------------------------------

def load_progress(progress_file: Path) -> dict:
    """Load progress.json from a prior scan; return empty state if missing or corrupt."""
    defaults: dict = {"reviewed_files": [], "issues": []}
    if progress_file.exists():
        try:
            data = json.loads(progress_file.read_text())
            return {**defaults, **data}
        except Exception:
            pass
    return defaults


def save_progress(progress_file: Path, reviewed_files: list[str], issues: list[dict]) -> None:
    """Persist incremental scan progress so the run can be resumed with --resume."""
    progress_file.write_text(json.dumps({
        "reviewed_files": reviewed_files,
        "issues": issues,
        "updated_at": datetime.now().isoformat(),
    }, indent=2))


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def parse_args() -> argparse.Namespace:
    """Parse and return CLI arguments."""
    p = argparse.ArgumentParser(
        description="Comprehensive AI code review agent (Nvidia Nemotron)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=textwrap.dedent("""\
            Examples:
              python3 code_reviewer.py --repo ~/projects/myapp
              python3 code_reviewer.py --repo ~/projects/myapp --output ~/reports
              python3 code_reviewer.py --repo ~/projects/myapp --resume
              python3 code_reviewer.py --repo ~/projects/myapp --skip-structure

            Env vars:
              NVIDIA_API_KEY or Nemotron_api_key  — required
        """),
    )
    p.add_argument("--repo", required=True, help="Path to the repository to review")
    p.add_argument("--output", default="./reports", help="Output directory for reports (default: ./reports)")
    p.add_argument("--model", default=DEFAULT_MODEL, help=f"Nvidia model ID (default: {DEFAULT_MODEL})")
    p.add_argument("--fast-model", default=FAST_MODEL, help="Model for structure phase (default: faster model)")
    p.add_argument("--resume", action="store_true", help="Resume interrupted scan using progress file")
    p.add_argument("--skip-structure", action="store_true",
                   help="Skip file-role identification (faster, less context)")
    p.add_argument("--max-files", type=int, default=0,
                   help="Limit number of files reviewed (0 = no limit, for testing)")
    p.add_argument("--include-ext", nargs="*", default=[],
                   help="Extra extensions to include (e.g. .vue .svelte)")
    p.add_argument("--exclude-dir", nargs="*", default=[],
                   help="Extra directories to exclude")
    return p.parse_args()


def main() -> None:
    """Orchestrate the four-phase code review pipeline and write the final report."""
    args = parse_args()
    api_key = get_api_key()

    repo = Path(args.repo).resolve()
    if not repo.exists():
        print(f"ERROR: Repo path does not exist: {repo}", file=sys.stderr)
        sys.exit(1)

    output_dir = Path(args.output)
    output_dir.mkdir(parents=True, exist_ok=True)

    # On --resume, reuse the most recent existing report dir for this repo.
    # Otherwise always create a fresh timestamped directory.
    if args.resume:
        prior = sorted(output_dir.glob(f"{repo.name}_*"))
        report_dir = prior[-1] if prior else None
    else:
        report_dir = None

    if report_dir is None:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        report_dir = output_dir / f"{repo.name}_{timestamp}"
    else:
        timestamp = report_dir.name.split("_", 1)[1] if "_" in report_dir.name else datetime.now().strftime("%Y%m%d_%H%M%S")

    report_dir.mkdir(parents=True, exist_ok=True)
    progress_file = report_dir / "progress.json"

    # Apply extra config
    if args.include_ext:
        CODE_EXTENSIONS.update(f".{e.lstrip('.')}" for e in args.include_ext)
    if args.exclude_dir:
        SKIP_DIRS.update(args.exclude_dir)

    print(f"\n{'='*60}")
    print(f"  CODE REVIEW AGENT")
    print(f"  Repo:   {repo}")
    print(f"  Output: {report_dir}")
    print(f"  Model:  {args.model}")
    print(f"{'='*60}\n")

    # Load progress if resuming
    progress = load_progress(progress_file) if args.resume else {"reviewed_files": [], "issues": []}
    all_issues: list[dict] = progress["issues"]
    reviewed_files: list[str] = progress["reviewed_files"]

    # -----------------------------------------------------------------------
    # PHASE 1: Context
    # -----------------------------------------------------------------------
    print("📄 Phase 1/4: Building project context...", flush=True)
    raw_context = load_project_context(repo)
    if not raw_context:
        print("  ⚠️  No docs found — using file structure only")
    project_summary = summarize_context(raw_context, api_key, args.fast_model)
    print(f"  ✅ Context built ({len(project_summary)} chars)\n")

    # Save context summary alongside report
    (report_dir / "context_summary.txt").write_text(project_summary)

    # -----------------------------------------------------------------------
    # PHASE 2: Structure
    # -----------------------------------------------------------------------
    print("🗂️  Phase 2/4: Mapping file structure...", flush=True)
    all_files = collect_files(repo)
    if args.max_files:
        all_files = all_files[: args.max_files]

    print(f"  Found {len(all_files)} reviewable files")

    file_roles: dict[str, str] = {}
    if not args.skip_structure and all_files:
        try:
            file_roles = identify_file_roles(all_files, repo, project_summary,
                                             api_key, args.fast_model)
            print(f"  ✅ Identified roles for {len(file_roles)} files\n")
        except Exception as e:
            print(f"  ⚠️  Structure phase failed ({e}) — continuing without roles\n")
    else:
        print("  ⏭️  Skipped (--skip-structure)\n")

    # -----------------------------------------------------------------------
    # PHASE 3: Deep Review
    # -----------------------------------------------------------------------
    remaining = [f for f in all_files if str(f.relative_to(repo)) not in reviewed_files]
    total_files = len(all_files)
    done = len(reviewed_files)

    print(f"🔍 Phase 3/4: Reviewing {len(remaining)} files "
          f"({'resuming — ' + str(done) + ' already done' if done else 'starting'})...\n",
          flush=True)

    for i, filepath in enumerate(remaining, start=done + 1):
        rel = str(filepath.relative_to(repo))
        role = file_roles.get(rel, "")
        print(f"  [{i}/{total_files}] {rel}", end=" ", flush=True)

        issues = review_file(filepath, repo, project_summary, role, api_key, args.model)
        all_issues.extend(issues)
        reviewed_files.append(rel)

        crit = sum(1 for x in issues if x.get("severity") == "CRITICAL")
        high = sum(1 for x in issues if x.get("severity") == "HIGH")
        label = ""
        if crit:
            label += f"🔴{crit} "
        if high:
            label += f"🟠{high} "
        if not crit and not high and issues:
            label = f"({len(issues)} issues)"
        print(label or "✓", flush=True)

        # Save progress after every file
        save_progress(progress_file, reviewed_files, all_issues)

    print(f"\n  ✅ Review complete — {len(all_issues)} total issues found\n")

    # -----------------------------------------------------------------------
    # PHASE 4: Report
    # -----------------------------------------------------------------------
    print("📊 Phase 4/4: Generating report...", flush=True)
    scan_meta = {
        "model": args.model,
        "files_reviewed": len(reviewed_files),
        "timestamp": timestamp,
    }
    report_md = generate_report(all_issues, project_summary, repo, scan_meta)

    report_path = report_dir / "report.md"
    report_path.write_text(report_md)

    # Also save raw issues as JSON for programmatic use
    (report_dir / "issues.json").write_text(json.dumps(all_issues, indent=2))

    print(f"\n{'='*60}")
    print(f"  ✅ DONE")
    print(f"  Report: {report_path}")
    print(f"  Issues: {len(all_issues)} total")
    by_sev = {s: sum(1 for x in all_issues if x.get("severity") == s)
               for s in ["CRITICAL", "HIGH", "MEDIUM", "LOW"]}
    for sev, emoji in SEVERITY_EMOJI.items():
        print(f"    {emoji} {sev}: {by_sev[sev]}")
    print(f"{'='*60}\n")


if __name__ == "__main__":
    main()
