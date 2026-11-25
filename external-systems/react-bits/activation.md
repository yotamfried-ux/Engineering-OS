# React Bits — executable project component installer

**Canonical source:** https://github.com/DavidHDev/react-bits
**Component registry:** https://reactbits.dev/
**Status:** bundled CLI usable from Engineering-OS; each actual UI component is installed only when explicitly selected for a React project.

The complete React Bits catalog is not a single installable npm library: individual components have distinct dependencies, CSS and project needs. This helper wraps the canonical jsrepo registry without pretending every component is already in every project.

```bash
# Check the library capability exists
python3 tools/eos_capabilities.py ensure --tool react-bits

# Preview a real component install, without project changes
python3 tools/reactbits_component.py SplitText --project /path/to/your-react-project --dry-run

# Explicitly install the component in that one project
python3 tools/reactbits_component.py SplitText --project /path/to/your-react-project

# Options
python3 tools/reactbits_component.py --examples
```

Requires Node.js, npm/npx, an existing project with package.json, working network. The CLI rejects unsafe component names and validates the project directory. Project installation modifies dependencies and files, so test using a feature branch and verify accessibility, mobile and RTL. Status `READY` for the bundled CLI does not prove component installation or successful rendering.

**Discovery:** https://www.instagram.com/reel/De90ttNOJbo/; additionally https://www.instagram.com/reel/DgJC0A4SF7B/ appears to reference React Bits, based on Instagram metadata.
