# Kiln

## Purpose / trigger

Use Kiln for AI-assisted 3D asset creation, revision, and inspection when the target workflow needs a 3D artifact rather than a flat image.

Typical jobs:
- create a new 3D asset from a prompt or reference;
- revise geometry, materials, textures, or presentation;
- inspect an asset and identify visible/model-level issues;
- prepare or iterate an asset for downstream use in a game, application, rendering, or content pipeline.

## Classification

- Category: 3D asset generation / authoring
- Role: creative-production capability
- Not a testing framework
- Not a general-purpose coding agent
- Not a substitute for authoritative DCC / engine validation

## Do-not-use / overlap guidance

- For ordinary 2D image generation, use the image-generation route instead.
- For deterministic validation of a 3D file inside Blender, Unreal, Unity, a game engine, or a production renderer, use that application's own validation/tests in addition to Kiln.
- Do not infer that an asset is production-ready merely because it looks correct in a preview.

## Source of truth

Canonical upstream: Kiln project's own repository/documentation as supplied for this capability.

Source tier: community / upstream project. Verify current upstream instructions when exact installation, host support, formats, or runtime behavior matter.

## Supported surface

Mechanism depends on the upstream Kiln integration available on the target host. Treat the capability as host-dependent until the actual runtime, installation path, credentials, and supported file formats are verified.

## Read / write scope

Expected scope may include reading reference inputs and producing or revising 3D assets and related metadata. Verify the exact integration before granting filesystem, project, or remote-service write access.

## Installation / connection

Follow current upstream Kiln instructions for the target environment. Prefer an existing authorized installation over creating a duplicate setup.

## Verification path

Before relying on Kiln in a target project:

1. Verify the executable/integration is actually available on the target host.
2. Run one representative 3D asset task.
3. Confirm that the produced asset can be opened by the intended downstream application.
4. Inspect at least one representative property relevant to the task, such as geometry, materials/textures, scale/orientation, or export format.
5. For production use, validate again in the authoritative downstream DCC/engine/runtime.

## What successful verification proves

A representative successful run proves that Kiln is reachable on that host and can complete the exercised 3D workflow for the tested input/output path.

## What it does not prove

It does not by itself prove:
- correctness for every model or file format;
- clean topology, UVs, rigging, collision, LODs, scale, or engine-specific constraints;
- production readiness;
- legal/IP suitability of generated content;
- compatibility with every downstream DCC, renderer, or engine.

## Security / privacy

Treat user-provided source assets and generated outputs as potentially sensitive project material. Review the actual upstream data-handling model before sending private assets to a hosted service.

## Qualification status

**READY AS KNOWLEDGE / NOT YET LIVE-QUALIFIED ON TARGET HOST**

Presence in Engineering-OS means Kiln is discoverable and categorized correctly. It must be live-qualified on the target host before a workflow depends on it.
