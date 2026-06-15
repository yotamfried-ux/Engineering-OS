# CLI Tool Template

## Overview
Use this template for command-line interface tools distributed to developers, operators, or power users. Suited for developer tooling, automation scripts, build utilities, and cloud management CLIs. The core concerns are a clear argument/flag contract, helpful error messages that guide the user toward a fix, persistent configuration management, and distribution channels that match how your audience installs software (npm, Homebrew, GitHub Releases binary).

## Recommended Architecture Options
- **Single binary (Go / Rust)** — No runtime dependency; fast startup; easy cross-platform distribution via GitHub Releases; best for tools that need to be installed on diverse machines without Node/Python.
- **Node.js with npm publish** — Fastest to build if the team knows JS; requires Node installed; excellent for dev tooling in JS/TS projects (`npx` invocations, `package.json` scripts).
- **Python with PyPI / pipx** — Rich ecosystem for data/ML tooling; requires Python; `pipx` provides isolated install; good for scripts that call Python libraries.

## Recommended Frameworks & Platforms
| Layer | Options |
|---|---|
| Argument parsing (Node) | Commander.js, Yargs, CAC, Clipanion |
| Argument parsing (Go) | Cobra, urfave/cli |
| Argument parsing (Rust) | clap |
| Interactive prompts | Inquirer.js, @clack/prompts, Enquirer (Node); promptui (Go); dialoguer (Rust) |
| Terminal output | chalk / kleur (colors), ora (spinner), cli-table3 (tables) — Node |
| Config file | cosmiconfig (Node), Viper (Go), confy (Rust) |
| Logging | debug (Node), zap/slog (Go), tracing (Rust) |
| Packaging (Node) | pkg, nexe, ncc + binary wrapper |
| Distribution | npm publish, Homebrew tap, GitHub Releases (cross-compile matrix), Chocolatey |
| Update notification | update-notifier (Node), GitHub Releases API poll |

## Required Components
- Root command with `--version` flag printing semantic version and build commit
- `--help` on every command and subcommand; examples section in help text
- Subcommand structure: `<tool> <noun> <verb>` pattern (e.g., `mytool project create`)
- Config file loading: looks in `./mytool.config.{js,json,yaml}`, `~/.config/mytool/config.json`; merged with environment variables and CLI flags (flag > env > config > default)
- Environment variable support: every flag has a `MYTOOL_` prefixed env var equivalent
- Structured error messages: user-facing message + suggested fix; `--debug` flag enables stack trace
- Exit codes: 0 = success, 1 = user error (bad input), 2 = runtime error (API failure), 3 = internal error
- `--json` output flag: machine-readable output for scripting and CI pipelines
- `--no-color` / `NO_COLOR` env var: disables ANSI codes for CI environments
- Interactive mode vs. non-interactive: detect TTY; fall back to error (not hang) in non-interactive contexts when prompts are needed
- Update notifier: check latest release on startup (async, non-blocking); notify once per day max

## Security Checklist
- [ ] Never log or print API keys, tokens, or passwords — mask them as `****` in debug output
- [ ] Config files with credentials have `0600` permissions set on creation
- [ ] Credentials stored in OS keychain (keytar) or secret manager, not plain text config
- [ ] No secrets in command history: sensitive values read from env vars or prompts, not positional args
- [ ] Shell completion scripts do not expose sensitive flag names to autocomplete history
- [ ] Downloaded binaries / plugins verified against checksum before execution
- [ ] HTTP requests use TLS only; `InsecureSkipVerify` forbidden even in dev mode

## Testing Checklist
- [ ] Unit tests for all flag parsing edge cases (missing required flags, invalid types, conflicts)
- [ ] Integration tests invoke the compiled binary and assert stdout/stderr and exit code
- [ ] `--json` output is valid JSON and passes schema validation for every command
- [ ] Config file: priority order tested (flag overrides env overrides config overrides default)
- [ ] Non-interactive mode: commands that require prompts error clearly when stdin is not a TTY
- [ ] `--help` tested: all commands and flags described; no undocumented flags in help text
- [ ] Cross-platform: CI matrix tests on ubuntu, macos, windows
- [ ] Update notifier: does not block or slow the command when the network is unavailable

## Deployment Checklist
- [ ] Semantic version tag (`vX.Y.Z`) triggers CI release workflow
- [ ] Cross-platform binaries built via CI matrix (linux/amd64, linux/arm64, darwin/amd64, darwin/arm64, windows/amd64)
- [ ] Checksums file (`checksums.txt`) and GPG signature published alongside binaries in GitHub Release
- [ ] npm package published with `files` field scoped to only the binary and type definitions
- [ ] Homebrew formula updated in tap repository on every release
- [ ] `CHANGELOG.md` or GitHub Release notes describe breaking changes prominently
- [ ] Shell completion scripts generated for bash, zsh, fish and documented in README
- [ ] Goreleaser / release-it configured in CI to automate the above steps

## Starter Templates

| Option | Description | Recommended |
|---|---|---|
| [oclif/oclif](https://github.com/oclif/oclif) | Salesforce's open CLI framework: TypeScript, plugin system, command parsing | ✅ Best pick |
| [tj/commander.js](https://github.com/tj/commander.js) | Commander.js: minimal Node.js CLI library | |
| [google/zx](https://github.com/google/zx) | Google's library for writing shell scripts in JavaScript/TypeScript | |

**Best Pick:** [oclif/oclif](https://github.com/oclif/oclif) — Used by Heroku CLI and Salesforce CLI; enterprise-grade, TypeScript-native, plugin system built-in

## Reference Repositories
- [cli/cli](https://github.com/cli/cli) — GitHub's official CLI (Go + Cobra); reference for subcommand structure, auth flow, and interactive prompts
- [vercel/vercel](https://github.com/vercel/vercel) — Large Node.js CLI; study the config loading, update notifier, and deployment flow
- [charmbracelet/bubbletea](https://github.com/charmbracelet/bubbletea) — Go TUI framework; use for rich interactive CLI experiences beyond simple prompts

## Official Documentation
- [Commander.js](https://github.com/tj/commander.js) — Node.js argument parsing with subcommands, options, help generation
- [Cobra (Go)](https://cobra.dev/) — Go CLI framework used by kubectl, Hugo, GitHub CLI
- [clap (Rust)](https://docs.rs/clap/latest/clap/) — Rust argument parser with derive macros
- [GoReleaser](https://goreleaser.com/docs/) — Cross-compile, package, and publish Go CLIs from CI
- [NO_COLOR standard](https://no-color.org/) — Convention for disabling terminal color output
- [oclif Docs](https://oclif.io/docs/introduction) — Open CLI framework documentation
