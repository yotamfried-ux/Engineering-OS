from __future__ import annotations

from .base import BaseAnalyzer, Finding


class CICDAnalyzer(BaseAnalyzer):
    aspect = "cicd"
    aspect_instructions = (
        "Evaluate CI/CD pipeline quality: "
        "(1) no test execution step in any workflow, "
        "(2) no linting or formatting step, "
        "(3) no security scanning step (e.g. Snyk, trivy, bandit), "
        "(4) secrets or tokens hardcoded in workflow YAML instead of using ${{ secrets.NAME }}, "
        "(5) action versions pinned to a mutable tag like @v3 or @main instead of a SHA, "
        "(6) no deployment or release automation for a production project, "
        "(7) workflow runs with excessive permissions (permissions: write-all). "
        "CRITICAL: secrets hardcoded in workflow file. HIGH: no tests in CI. MEDIUM: no security scan."
    )

    async def analyze(self, repo: str) -> list[Finding]:
        workflows = await self.github.get_workflows(repo)

        if not workflows:
            return [Finding(
                severity="HIGH",
                aspect=self.aspect,
                title="No CI/CD pipeline found",
                location=".github/workflows/",
                description="Repository has no GitHub Actions workflow files.",
                recommendation=(
                    "Add a GitHub Actions workflow at .github/workflows/ci.yml with "
                    "lint, test, and security-scan steps."
                ),
            )]

        return await self._call_nemotron(workflows)
