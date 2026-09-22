# Policy — CLI-Anything

- **type:** tool-generation, cli, agent-interface, automation
- **level:** L1 when a GUI-heavy or non-agent-native application is blocking reliable automation; otherwise L0
- **default install:** no
- **scope:** generates application-specific CLI harnesses; it does not orchestrate Engineering-OS

## Rules

1. Prefer an application's existing official CLI/API when it already provides adequate structured control.
2. Use CLI-Anything when generating a tested CLI materially improves determinism, composability, or token efficiency.
3. Treat generated code as application code that requires review and verification.
4. Never claim full application coverage from generation alone.
5. Distinguish unit/structural validation from real-backend end-to-end qualification.
6. Follow current upstream HARNESS and host installation instructions rather than freezing implementation details here.
7. Do not turn CLI-Anything into a permanent Engineering-OS resolver, daemon, database, telemetry layer, or orchestration runtime.

## Conflicts and precedence

Application-native official interfaces take precedence when they are sufficient. CLI-Anything is an adapter-generation option when they are not. Security and deployment policies of the target project continue to apply to any generated harness.
