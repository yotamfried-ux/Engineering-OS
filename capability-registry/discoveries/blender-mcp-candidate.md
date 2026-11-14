# Blender MCP — AI-driven 3D scene creation

**Status:** candidate only; NOT INSTALLED or security-qualified.
**Canonical upstream:** https://github.com/collactivelabs/blender-mcp
**Primary documentation:** upstream README and repository code.

The upstream MCP integration allows an agent to manipulate Blender scenes, objects, materials, lights, cameras and rendering, and describes external asset integrations. Relevant to Roblox/world prototyping, game assets and visualization, but a Blender scene is **not** a validated Roblox-ready asset without export, topology, texture, licensing and performance checks.

**High-risk capability:** Blender Python execution via agent instructions can run arbitrary code with the user's OS permissions. Do not connect to sensitive workstations, credentials or production assets without explicit approval, isolated execution, reviewed tools and network/asset provenance constraints. External assets may carry separate licensing requirements. No automatic installation, downloads or Blender execution.

Before adoption: verify exact version and license, MCP endpoint exposure, Python execution paths, tool permissions, model/provider cost, external API keys, Blender compatibility, asset attribution, and small isolated end-to-end scene/export test.
