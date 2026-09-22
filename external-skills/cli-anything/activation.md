# Activation — CLI-Anything

## Upstream

- Canonical repository: `HKUDS/CLI-Anything`
- Use the current upstream README and `cli-anything-plugin/HARNESS.md` as the source of truth.

## Prerequisites

- Python 3.10+
- A supported coding agent.
- The target application's source tree or repository.
- The target application itself when the generated harness needs it for end-to-end verification.

## Install

### Claude Code marketplace

```text
/plugin marketplace add HKUDS/CLI-Anything
/plugin install cli-anything
```

### Manual source checkout

```bash
git clone https://github.com/HKUDS/CLI-Anything.git
```

Follow the host-specific installation instructions in upstream rather than copying stale commands from this wrapper.

## Verify

CLI-Anything is a generator, so presence of the repository/plugin alone is not sufficient qualification.

1. Confirm the plugin/commands are discoverable in the selected host.
2. Generate or use an upstream-provided harness.
3. Use the upstream `test` command/workflow for that harness.
4. Use the upstream `validate` command/workflow against HARNESS.md.
5. Confirm the generated CLI exposes `--help` and structured output.
6. For a target application, execute representative end-to-end operations against the real backend when its prerequisites are available.

Do not report a target application as live-qualified when only unit tests or documentation checks ran. Host/application-dependent E2E verification must be reported separately.

## Secrets

No universal secret is required by CLI-Anything itself. A generated harness may require credentials for the target software/service; follow that harness's upstream documentation and never commit secret values.

## Removal

Remove the installed host plugin/commands using the host's documented plugin mechanism, and delete any generated harness only if it is not part of the target project's intended source.
