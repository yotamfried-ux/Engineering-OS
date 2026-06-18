from __future__ import annotations

import re
from collections import defaultdict

from .base import BaseAnalyzer, Finding

_SOURCE_PATTERNS = [
    "*.py", "src/**/*.py", "app/**/*.py", "lib/**/*.py",
    "*.ts", "src/**/*.ts",
    "*.js", "src/**/*.js",
]
_PY_IMPORT = re.compile(r'^(?:from|import)\s+([\w.]+)', re.MULTILINE)
_JS_IMPORT = re.compile(r'(?:import|require)\s*[\(\'"]([^\'")]+)[\'")]')


def _extract_imports(content: str, path: str) -> list[str]:
    if path.endswith(".py"):
        return [m.group(1) for m in _PY_IMPORT.finditer(content)]
    if path.endswith((".ts", ".tsx", ".js", ".jsx")):
        return [m.group(1) for m in _JS_IMPORT.finditer(content)]
    return []


def _find_two_cycles(graph: dict[str, list[str]]) -> list[tuple[str, str]]:
    seen: set[tuple[str, str]] = set()
    out: list[tuple[str, str]] = []
    for node_a, deps in graph.items():
        for node_b in deps:
            if node_b in graph and node_a in graph[node_b]:
                pair = (min(node_a, node_b), max(node_a, node_b))
                if pair not in seen:
                    seen.add(pair)
                    out.append(pair)
    return out


class ArchitectureAnalyzer(BaseAnalyzer):
    aspect = "architecture"
    aspect_instructions = (
        "Analyze code architecture and structural quality: "
        "(1) God objects or modules — single files doing too many unrelated things (>400 lines), "
        "(2) tight coupling — a module that imports from many other modules, making it fragile, "
        "(3) mixed concerns — business logic directly embedded in route handlers, DB models, or UI components, "
        "(4) incorrect usage patterns — calling private/internal methods from outside the module, "
        "(5) missing abstraction layers — direct DB calls scattered across the codebase instead of a repository layer. "
        "CRITICAL: architecture that blocks horizontal scaling or prevents testing. "
        "HIGH: major design violations. MEDIUM: moderate structural issues. LOW: naming/convention."
    )

    async def analyze(self, repo: str) -> list[Finding]:
        source_files = await self.github.get_files_matching(repo, _SOURCE_PATTERNS, max_files=30)

        if not source_files:
            return []

        static: list[Finding] = []
        import_graph: dict[str, list[str]] = defaultdict(list)

        for path, content in source_files.items():
            line_count = content.count("\n")
            if line_count > 400:
                static.append(Finding(
                    severity="HIGH",
                    aspect=self.aspect,
                    title=f"Large file — {line_count} lines",
                    location=path,
                    description=f"{path} has {line_count} lines and likely violates single-responsibility.",
                    recommendation="Decompose into smaller modules, each with one clear purpose.",
                ))
            for imp in _extract_imports(content, path):
                import_graph[path].append(imp)

        for node_a, node_b in _find_two_cycles(import_graph):
            static.append(Finding(
                severity="HIGH",
                aspect=self.aspect,
                title="Circular dependency detected",
                location=f"{node_a} ↔ {node_b}",
                description=f"Circular import detected between {node_a} and {node_b}.",
                recommendation="Break the cycle via a shared interface module or dependency injection.",
            ))

        nemotron_findings = await self._call_nemotron(source_files)
        return static + nemotron_findings
