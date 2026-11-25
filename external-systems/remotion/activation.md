# Remotion framework — executable React project installation

Official docs: https://www.remotion.dev/docs/ and https://www.remotion.dev/docs/agents/
Reel: https://www.instagram.com/reel/DgCYbIeAt69/

```bash
python3 /path/to/Engineering-OS/tools/eos_capabilities.py ensure --tool remotion-project --project /path/to/React-project
python3 /path/to/Engineering-OS/tools/eos_capabilities.py status --profile reels-react-video --project /path/to/React-project --json
```

Requires an existing project with `package.json`, Node/npm and network. Installs `remotion` and `@remotion/cli` with `--ignore-scripts --save-exact`, then verifies both declarations and actual installed packages. Separate media/browser/render dependencies and license considerations apply. Test a reproducible local render with known input; *not* production-ready based on package presence alone.
