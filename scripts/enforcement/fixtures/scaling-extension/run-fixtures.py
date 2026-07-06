#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import io
import shutil
import sys
import tempfile
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path

ROOT = Path(sys.argv[1]).resolve()
CHECK = ROOT / "scripts/enforcement/check-scaling-extension.py"
CASES = ROOT / "scripts/enforcement/fixtures/scaling-extension/cases.tsv"

spec = importlib.util.spec_from_file_location("scaling_gate", CHECK)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

required_cases = {
    "positive-complete-project-type",
    "template-without-manifest-row",
    "project-type-without-roadmap",
    "roadmap-without-official-sources",
    "docs-source-without-freshness-consult-rule",
    "reference-repo-without-license-freshness",
    "code-example-without-run-validation",
    "pattern-skill-without-inventory",
    "connector-workflow-without-evidence-rule",
    "waiver-without-scope-reason-audit-link",
    "game-development-without-playable-performance",
}
actual_cases = {line.split("\t", 1)[0] for line in CASES.read_text().splitlines() if line and not line.startswith("#")}
missing = sorted(required_cases - actual_cases)
if missing:
    raise SystemExit("missing fixture catalog cases: " + ", ".join(missing))

TMP = Path(tempfile.mkdtemp())


def fixture(name: str) -> Path:
    dest = TMP / name
    for rel in ["scripts", "docs", "templates", "patterns", "external-skills"]:
        src = ROOT / rel
        if src.exists():
            shutil.copytree(src, dest / rel)
    return dest


def gate(repo: Path) -> tuple[int, str]:
    out, err = io.StringIO(), io.StringIO()
    with redirect_stdout(out), redirect_stderr(err):
        code = module.Gate(repo).run()
    return code, out.getvalue() + err.getvalue()


def ok(name: str, repo: Path) -> None:
    code, output = gate(repo)
    if code != 0:
        raise SystemExit(f"fail: {name}\n{output}")
    print(f"ok: {name}")


def bad(name: str, repo: Path, needle: str) -> None:
    code, output = gate(repo)
    if code == 0 or needle not in output:
        raise SystemExit(f"wrong result: {name}\nexpected: {needle}\nactual:\n{output}")
    print(f"ok: {name}")


def replace_line(path: Path, prefix: str, edit) -> None:
    rows = []
    for line in path.read_text().splitlines():
        if line.startswith(prefix):
            parts = line.split("\t")
            edit(parts)
            line = "\t".join(parts)
        rows.append(line)
    path.write_text("\n".join(rows) + "\n")

try:
    repo = fixture("positive")
    ok("positive-complete-project-type", repo)

    repo = fixture("template-without-manifest-row")
    (repo / "templates/new-unmapped-template").mkdir(parents=True)
    bad("template-without-manifest-row", repo, "template inventory coverage failed")

    repo = fixture("project-type-without-roadmap")
    with (repo / "scripts/enforcement/result-loop-requirements.tsv").open("a") as f:
        f.write("new-project\tplanned\tdocs/operations/result-loop-contract-plan.md\tscripts/enforcement/result-loop-requirements.tsv\trequired\trequired\trequired\trequired\trequired\trequired\trequired\trequired\trequired\trequired\trequired\trequired\trequired\tnot_exempt\tdocs/operations/result-loop-contract-audit-checklist.md#scaling-gate-implementation\tdocs/operations/known-gaps.tsv#new-project\n")
    bad("project-type-without-roadmap", repo, "has no project-type-roadmaps.tsv row")

    repo = fixture("roadmap-without-official-sources")
    p = repo / "scripts/enforcement/documentation-sources.tsv"
    p.write_text("\n".join(line for line in p.read_text().splitlines() if not line.startswith("game-development-docs\t")) + "\n")
    bad("roadmap-without-official-sources", repo, "game-development has no documentation-sources.tsv row")

    repo = fixture("docs-source-without-freshness-consult-rule")
    replace_line(repo / "scripts/enforcement/documentation-sources.tsv", "web-application-docs\t", lambda parts: (parts.__setitem__(6, "NONE"), parts.__setitem__(8, "NONE")))
    bad("docs-source-without-freshness-consult-rule", repo, "missing freshness_note")

    repo = fixture("reference-repo-without-license-freshness")
    with (repo / "scripts/enforcement/reference-repositories.tsv").open("a") as f:
        f.write("bad-reference\tactive\tweb-application\thttps://github.com/example/example\tofficial_sample\tstarter reference\tNONE\tNONE\tvalidated\tNONE\tdocs/operations/scaling-extension-procedure.md\tnot_exempt\tdocs/operations/result-loop-contract-audit-checklist.md#scaling-gate-implementation\tdocs/operations/known-gaps.tsv#bad-reference\n")
    bad("reference-repo-without-license-freshness", repo, "missing license_usage_note")

    repo = fixture("code-example-without-run-validation")
    with (repo / "scripts/enforcement/code-example-requirements.tsv").open("a") as f:
        f.write("bad-example\tactive\tweb-application\tweb-application\tREADME.md\tNONE\tNONE\tfixture\tfixture source\tvalidation required\tnot_exempt\tdocs/operations/result-loop-contract-audit-checklist.md#scaling-gate-implementation\tdocs/operations/known-gaps.tsv#bad-example\n")
    bad("code-example-without-run-validation", repo, "missing run_path")

    repo = fixture("pattern-skill-without-inventory")
    p = repo / "scripts/enforcement/pattern-requirements.tsv"
    p.write_text("\n".join(line for line in p.read_text().splitlines() if not line.startswith("web-application-patterns\t")) + "\n")
    bad("pattern-skill-without-inventory", repo, "has no active pattern-requirements.tsv row")

    repo = fixture("connector-workflow-without-evidence-rule")
    replace_line(repo / "scripts/enforcement/connector-workflow-requirements.tsv", "github-source-of-truth\t", lambda parts: parts.__setitem__(6, "NONE"))
    bad("connector-workflow-without-evidence-rule", repo, "missing required_evidence")

    repo = fixture("waiver-without-scope-reason-audit-link")
    replace_line(repo / "scripts/enforcement/waiver-requirements.tsv", "notion-plan-fallback-waiver\t", lambda parts: (parts.__setitem__(3, "NONE"), parts.__setitem__(4, "NONE"), parts.__setitem__(7, "NONE")))
    bad("waiver-without-scope-reason-audit-link", repo, "missing reason")

    repo = fixture("game-development-without-playable-performance")
    replace_line(repo / "scripts/enforcement/project-type-roadmaps.tsv", "game-development\t", lambda parts: parts.__setitem__(6, "screenshots/videos; telemetry export"))
    bad("game-development-without-playable-performance", repo, "game-development roadmap missing playable surface")
finally:
    shutil.rmtree(TMP, ignore_errors=True)
