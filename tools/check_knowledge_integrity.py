#!/usr/bin/env python3
from __future__ import annotations
import json, re, sys
from pathlib import Path
from urllib.parse import unquote
ROOT=Path(__file__).resolve().parents[1]
MD=sorted(ROOT.rglob("*.md"))
REQUIRED=["capability-registry/ROUTING-MAP.md","capability-registry/SOURCE-POLICY.md","capability-registry/EXECUTION-FAST-PATH.md","capability-registry/EXECUTION-FAST-PATH.json","capability-registry/EXECUTION-TRACE.json","patterns/testing/FAST-PATH.md","patterns/testing/FAST-PATH.json","patterns/testing/project-qualification.md","patterns/testing/AUTHORITATIVE-SOURCES.md","patterns/security/README.md","docs/troubleshooting/README.md"]
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
# Keep the ordinary test-writing entry point deliberately small and valid.
fast_md=ROOT/"patterns/testing/FAST-PATH.md"
fast_json=ROOT/"patterns/testing/FAST-PATH.json"
if fast_md.exists() and fast_md.stat().st_size > 7000:
    errors.append(f"testing fast path: FAST-PATH.md is too large ({fast_md.stat().st_size} bytes; max 7000)")
if fast_json.exists() and fast_json.stat().st_size > 4000:
    errors.append(f"testing fast path: FAST-PATH.json is too large ({fast_json.stat().st_size} bytes; max 4000)")
if fast_json.exists():
    try:
        fast_data=json.loads(fast_json.read_text("utf-8"))
    except Exception as exc:
        errors.append(f"testing fast path: invalid JSON: {exc}")
    else:
        routes=fast_data.get("routes")
        if not isinstance(routes,dict) or not routes:
            errors.append("testing fast path: routes must be a non-empty object")
        else:
            for name,route in routes.items():
                raw=route.get("first_stop") if isinstance(route,dict) else None
                if not isinstance(raw,str) or not raw:
                    errors.append(f"testing fast path: route {name} has no first_stop")
                    continue
                dest,_,frag=raw.partition("#")
                target=(ROOT/dest).resolve()
                try: target.relative_to(ROOT.resolve())
                except ValueError:
                    errors.append(f"testing fast path: route {name} escapes repository: {raw}"); continue
                if not target.exists():
                    errors.append(f"testing fast path: route {name} missing target: {raw}"); continue
                if frag and target.suffix.lower()==".md" and slug(frag) not in anchors(target):
                    errors.append(f"testing fast path: route {name} missing anchor: {raw}")
if "patterns/testing/FAST-PATH.json" not in (ROOT/"capability-registry/ROUTING-MAP.md").read_text("utf-8"):
    errors.append("testing fast path: ROUTING-MAP.md must expose FAST-PATH.json")

# Keep the agent/execution entry point deliberately small and resolvable.
exec_md=ROOT/"capability-registry/EXECUTION-FAST-PATH.md"
exec_json=ROOT/"capability-registry/EXECUTION-FAST-PATH.json"
if exec_md.exists() and exec_md.stat().st_size > 7000:
    errors.append(f"execution fast path: Markdown too large ({exec_md.stat().st_size} bytes; max 7000)")
if exec_json.exists() and exec_json.stat().st_size > 5000:
    errors.append(f"execution fast path: JSON too large ({exec_json.stat().st_size} bytes; max 5000)")
if exec_json.exists():
    try:
        exec_data=json.loads(exec_json.read_text("utf-8"))
    except Exception as exc:
        errors.append(f"execution fast path: invalid JSON: {exc}")
    else:
        priority=exec_data.get("priority")
        if priority != ["none","local","included","paid","unknown"]:
            errors.append("execution fast path: cost priority must remain none/local/included/paid/unknown")
        routes=exec_data.get("routes")
        if not isinstance(routes,dict) or not routes:
            errors.append("execution fast path: routes must be a non-empty object")
        else:
            for name,route in routes.items():
                raw=route.get("first_stop") if isinstance(route,dict) else None
                if not isinstance(raw,str) or not raw:
                    errors.append(f"execution fast path: route {name} has no first_stop")
                    continue
                dest,_,frag=raw.partition("#")
                target=(ROOT/dest).resolve()
                try: target.relative_to(ROOT.resolve())
                except ValueError:
                    errors.append(f"execution fast path: route {name} escapes repository: {raw}"); continue
                if not target.exists():
                    errors.append(f"execution fast path: route {name} missing target: {raw}"); continue
                if frag and target.suffix.lower()==".md" and slug(frag) not in anchors(target):
                    errors.append(f"execution fast path: route {name} missing anchor: {raw}")
if "EXECUTION-FAST-PATH.json" not in (ROOT/"capability-registry/ROUTING-MAP.md").read_text("utf-8"):
    errors.append("execution fast path: ROUTING-MAP.md must expose EXECUTION-FAST-PATH.json")
trace_json=ROOT/"capability-registry/EXECUTION-TRACE.json"
if trace_json.exists() and trace_json.stat().st_size > 3000:
    errors.append(f"execution trace: JSON too large ({trace_json.stat().st_size} bytes; max 3000)")
if trace_json.exists():
    try:
        trace_data=json.loads(trace_json.read_text("utf-8"))
    except Exception as exc:
        errors.append(f"execution trace: invalid JSON: {exc}")
    else:
        required={"task","entry_point","route_key","trigger","candidates","selected","cost_class","parallelizable","delegated","reason","verification"}
        record=trace_data.get("record")
        if not isinstance(record,dict) or set(record) != required:
            errors.append("execution trace: record schema fields drifted")

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
