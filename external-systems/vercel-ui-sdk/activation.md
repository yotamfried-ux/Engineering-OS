# Vercel UI SDK — real project dependency activation

Canonical source: https://github.com/vercel-labs/ui
Documentation: https://ui-sdk.dev/docs

The separately registered `ui-sdk-agent` installs the Claude Code behavior skill; **that is not the same as installing the React library**.

In a React project directory:

```bash
# Explicit project-scoped npm install, no lifecycle scripts
python3 /path/to/Engineering-OS/tools/eos_capabilities.py ensure --tool ui-sdk-react --project /path/to/react-project

# Confirm packages are present in node_modules and package.json
python3 /path/to/Engineering-OS/tools/eos_capabilities.py status --profile reels-react --project /path/to/react-project --json
```

**Requires:** Node/npm, React-compatible project and network. The installer uses `npm install --ignore-scripts --save-exact @ui-sdk/core @ui-sdk/react` in the selected project's working directory. React package versions are recorded in the target `package.json` and lockfile; it does not touch other applications or global dependencies.

**Verification:** status checks both dependency declarations and installed `node_modules` package manifests. This establishes local package availability, not browser accessibility, framework compatibility or production correctness. Verify keyboard navigation, focus transitions, screen readers, mobile responsiveness, reduced motion, RTL, and full user journeys. UI SDK is in beta.

**Source Reel:** https://www.instagram.com/reel/DfuKScLAOK-/
