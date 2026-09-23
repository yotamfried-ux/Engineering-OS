#!/usr/bin/env python3
from __future__ import annotations
import re, sys
from pathlib import Path
from urllib.parse import unquote
ROOT=Path(__file__).resolve().parents[1]
MD=sorted(ROOT.rglob("*.md"))
REQUIRED=["AGENTS.md","capability-registry/ROUTING-MAP.md","capability-registry/SOURCE-POLICY.md","patterns/testing/project-qualification.md","patterns/testing/AUTHORITATIVE-SOURCES.md","patterns/security/README.md","docs/troubleshooting/README.md"]
FORBIDDEN=("core/","scripts/","experiments/","evals/","telemetry-archive/",".claude/")
HISTORICAL=("lessons-learned/","failed-solutions/","improved-stage3/","architecture-decisions/ADR-","capability-registry/evaluations/","capability-registry/USABILITY-AUDIT","capability-registry/QUALIFICATION-REPORT","capability-registry/NORMALIZATION-AUDIT")
INSTALL_DOCS=("external-skills/","templates/")
SECRET_QUERY=re.compile(r"(?i)[?&](?:mcp_token|access_token|api[_-]?key|token|secret)=")
LINK=re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")
CODE_PATH=re.compile(r"\x60((?:core|scripts|experiments|evals|telemetry-archive|\.claude)/[^\x60]+)\x60")
def slug(s):
    s=re.sub(r"[\*_~]","",s.strip().lower())
    s=re.sub(r"[^\w\- ]","",s,flags=re.UNICODE)
    return re.sub(r"[ -]+","-",s).strip("-")
def anchors(p):
    out=set()
    for line in p.read_text("utf-8",errors="replace").splitlines():
        m=re.match(r"^#{1,6}\s+(.+?)\s*#*\s*$",line)
        if m: out.add(slug(m.group(1)))
    return out
errors=[]
for rel in REQUIRED:
    if not (ROOT/rel).exists(): errors.append(f"missing required entry point: {rel}")
for p in MD:
    rel=p.relative_to(ROOT); rs=str(rel); text=p.read_text("utf-8",errors="replace")
    # Only flag token-bearing URL query strings that contain a literal-looking value.
    for sm in re.finditer(r"(?i)[?&](?:mcp_token|access_token|api[_-]?key|token|secret)=([^&\\s)`]+)", text):
        value=sm.group(1)
        if not any(marker in value for marker in ("<", "{", "$", "YOUR_", "REDACTED", "example")):
            errors.append(f"{rel}: contains literal-looking secret/share-token query parameter")
    if rs.startswith(HISTORICAL):
        continue
    for m in LINK.finditer(text):
        raw=m.group(1).strip()
        if not raw or raw.startswith(("#","http://","https://","mailto:","tel:")): continue
        raw=raw.split()[0].strip("<>"); dest,_,frag=raw.partition("#")
        target=(p.parent/unquote(dest)).resolve()
        try: target.relative_to(ROOT.resolve())
        except ValueError:
            errors.append(f"{rel}: link escapes repository: {raw}"); continue
        if dest and not target.exists():
            errors.append(f"{rel}: dead relative link: {raw}"); continue
        if frag and target.is_file() and target.suffix.lower()==".md" and slug(unquote(frag)) not in anchors(target):
            errors.append(f"{rel}: missing anchor: {raw}")
    if not rs.startswith(INSTALL_DOCS):
        for m in CODE_PATH.finditer(text):
            path=m.group(1).rstrip(".,;:")
            if path.startswith(FORBIDDEN) and not (ROOT/path).exists():
                errors.append(f"{rel}: references removed runtime path: {path}")
# Integrated external-skill wrappers listed in the registry must have the exact contract.
skills_index=(ROOT/"external-skills/README.md").read_text("utf-8")
contract={"README.md","integration.md","policy.md","activation.md"}
in_registry=False
for line in skills_index.splitlines():
    if line.strip()=="## Skill registry": in_registry=True; continue
    if in_registry and line.startswith("## "): break
    if not in_registry or not line.startswith("|"): continue
    for name in re.findall(r"\]\(\./([^/]+)/\)", line):
        d=ROOT/"external-skills"/name
        if not d.is_dir():
            errors.append(f"external-skills registry: missing directory: {name}")
            continue
        files={p.name for p in d.iterdir() if p.is_file()}
        if files != contract:
            errors.append(f"external-skills/{name}: integrated wrapper must contain exactly {sorted(contract)}; found {sorted(files)}")
# Agent entry point must explicitly route through the canonical routing map.
agents=(ROOT/"AGENTS.md").read_text("utf-8")
if "capability-registry/ROUTING-MAP.md" not in agents:
    errors.append("AGENTS.md: does not route agents through capability-registry/ROUTING-MAP.md")
if "capability-registry/SOURCE-POLICY.md" not in agents:
    errors.append("AGENTS.md: does not expose the source/provenance policy")

# Every integrated skill must be discoverable from agent-tools or a dedicated routing-map row.
agent_tools=(ROOT/"capability-registry/agent-tools.md").read_text("utf-8")
routing=(ROOT/"capability-registry/ROUTING-MAP.md").read_text("utf-8")
for name in sorted({name for line in skills_index.splitlines() if line.startswith("|") for name in re.findall(r"\\]\\(\\./([^/]+)/\\)", line)}):
    if name == "frontend-design":
        continue
    skill_ref=f"external-skills/{name}/"
    if skill_ref not in agent_tools and skill_ref not in routing:
        errors.append(f"capability discovery: integrated skill is not routed: {name}")
for line in routing.splitlines():
    if not line.startswith("|") or "First stop" in line or line.startswith("|---"): continue
    cells=[x.strip() for x in line.strip("|").split("|")]
    if len(cells)<2: continue
    for raw in re.findall(r"\x60([^\x60]+)\x60",cells[1]):
        if not any(x.exists() for x in (ROOT/raw,ROOT/"capability-registry"/raw)):
            errors.append(f"ROUTING-MAP: unresolved first stop: {raw}")
if errors:
    print("Knowledge integrity: FAIL")
    for e in sorted(set(errors)): print(f"- {e}")
    sys.exit(1)
print(f"Knowledge integrity: PASS ({len(MD)} Markdown files checked)")
