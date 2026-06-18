from __future__ import annotations

from typing import TYPE_CHECKING

from .base import BaseAnalyzer, Finding

if TYPE_CHECKING:
    pass

_SOURCE_PATTERNS = [
    "*.py", "src/**/*.py", "app/**/*.py", "lib/**/*.py",
    "*.ts", "*.tsx", "src/**/*.ts", "src/**/*.tsx",
    "*.js", "*.jsx", "src/**/*.js", "src/**/*.jsx",
]
_TEST_PATTERNS = [
    "test_*.py", "*_test.py", "tests/**/*.py",
    "*.test.ts", "*.spec.ts", "*.test.js", "*.spec.js",
    "__tests__/**/*.ts", "__tests__/**/*.js",
    "spec/**/*.py", "spec/**/*.ts", "spec/**/*.js",
]


class CodeQualityAnalyzer(BaseAnalyzer):
    aspect = "code_quality"
    aspect_instructions = (
        "Analyze code quality and identify: "
        "(1) source modules with NO corresponding test file (highest priority — assign CRITICAL if core module), "
        "(2) functions or methods longer than 50 lines that likely have high cyclomatic complexity, "
        "(3) missing error handling — bare `except:`, unhandled promise rejections, unchecked return values, "
        "(4) obvious code duplication — identical or near-identical blocks repeated >2 times, "
        "(5) dead code — functions, variables, or imports that are defined but never referenced. "
        "Severity guide: CRITICAL = untested critical path; HIGH = major complexity/missing error handling; "
        "MEDIUM = duplication or moderate complexity; LOW = style and minor issues."
    )

    async def analyze(self, repo: str) -> list[Finding]:
        source_files = await self.github.get_files_matching(repo, _SOURCE_PATTERNS, max_files=25)
        test_files = await self.github.get_files_matching(repo, _TEST_PATTERNS, max_files=15)

        if not source_files and not test_files:
            return [Finding(
                severity="MEDIUM",
                aspect=self.aspect,
                title="No recognizable source files found",
                location="",
                description="No Python/TypeScript/JavaScript source files were detected.",
                recommendation="Verify the repository contains supported languages.",
            )]

        coverage_note = (
            f"Test files found: {len(test_files)}\n"
            f"Source files found: {len(source_files)}\n"
            f"Test-to-source ratio: {len(test_files)}/{len(source_files)}"
        )
        files = {
            **source_files,
            **{f"[TEST] {k}": v for k, v in test_files.items()},
            "_meta/coverage_summary.txt": coverage_note,
        }
        return await self._call_nemotron(files)
