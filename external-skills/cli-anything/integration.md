# Integration — CLI-Anything

## Purpose

Use CLI-Anything when an agent needs deterministic, structured control of software that primarily exposes a GUI or otherwise lacks an agent-friendly interface. It generates an application-specific CLI harness rather than acting as a permanent Engineering-OS runtime.

## Upstream interface

The canonical upstream exposes a generation/refinement/testing/validation workflow. In Claude Code the plugin provides commands for creating a CLI harness, refining it, testing it, and validating it against the upstream HARNESS methodology. Generated harnesses are Python packages with application-specific CLI commands and structured output.

## When to use

Use it when:

- the target software has a codebase or usable programmatic backend but poor agent ergonomics;
- GUI clicking would be brittle or token-expensive;
- repeatable structured commands and JSON output would materially improve automation;
- an application-specific CLI can be tested against real operations.

Do not use it merely to wrap an API or CLI that is already clean and agent-friendly.

## Workflow

1. Inspect the target application's codebase and existing interfaces.
2. Invoke CLI-Anything using the current upstream host instructions.
3. Review the generated command surface and state model.
4. Run the upstream-generated tests.
5. Validate against HARNESS.md.
6. Exercise representative real application operations before relying on the harness for production work.
7. Refine gaps instead of assuming the first generation pass has complete feature coverage.

## Composition

CLI-Anything complements planning/review skills: those skills decide what work should be done; CLI-Anything can create a deterministic interface through which an agent performs application-specific work. Generated harnesses belong with the target project/application, not inside Engineering-OS as a central runtime.
