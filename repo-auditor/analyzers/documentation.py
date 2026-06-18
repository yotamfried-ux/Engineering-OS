from __future__ import annotations

from .base import BaseAnalyzer, Finding

_DOC_PATTERNS = [
    "README.md", "README.rst", "README.txt", "README",
    "CONTRIBUTING.md", "CONTRIBUTING.rst",
    "CHANGELOG.md", "CHANGELOG", "HISTORY.md",
    "docs/**/*.md", "docs/**/*.rst",
]
_SOURCE_PATTERNS = [
    "*.py", "src/**/*.py",
    "*.ts", "src/**/*.ts",
    "*.js", "src/**/*.js",
]


class DocumentationAnalyzer(BaseAnalyzer):
    aspect = "documentation"
    aspect_instructions = (
        "Evaluate documentation completeness and quality: "
        "(1) README missing critical sections: installation instructions, usage examples, API reference, contributing guide, license, "
        "(2) public functions, classes, or API endpoints that have no docstring or JSDoc comment, "
        "(3) documentation that is outdated — version mismatches, deprecated APIs referenced, broken examples, "
        "(4) no CONTRIBUTING.md when the repo appears to be a library or framework, "
        "(5) no CHANGELOG when the repo has multiple releases. "
        "Severity guide: CRITICAL = completely missing README; HIGH = README missing installation or usage; "
        "MEDIUM = undocumented public API; LOW = style/formatting issues."
    )

    async def analyze(self, repo: str) -> list[Finding]:
        doc_files = await self.github.get_files_matching(repo, _DOC_PATTERNS, max_files=10)
        source_files = await self.github.get_files_matching(repo, _SOURCE_PATTERNS, max_files=10)

        if not doc_files:
            return [Finding(
                severity="CRITICAL",
                aspect=self.aspect,
                title="No documentation files found",
                location="",
                description="Repository has no README or documentation files.",
                recommendation="Create a README.md with at minimum: project description, installation, usage, and license.",
            )]

        files = {
            **doc_files,
            **{f"[SOURCE] {k}": v for k, v in list(source_files.items())[:8]},
        }
        return await self._call_nemotron(files)
