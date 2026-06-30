#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FILE="${1:-$ROOT/docs/operations/template-pattern-ratings.tsv}"
python3 - "$ROOT" "$FILE" <<'PY'
import pathlib, sys
root=pathlib.Path(sys.argv[1]); file=pathlib.Path(sys.argv[2])
errors=[]; seen=set(); rows=0
if not file.exists():
    print(f"template pattern ratings failed: missing {file}", file=sys.stderr); sys.exit(1)
def exists(p):
    if p.upper() in {"NONE","N/A"}: return True
    pp=pathlib.Path(p)
    return (pp if pp.is_absolute() else root/pp).exists()
for lineno,line in enumerate(file.read_text().splitlines(),1):
    if not line.strip() or line.startswith('#'): continue
    parts=line.split('\t')
    if len(parts)!=14:
        errors.append(f"line {lineno}: expected 14 tab fields, got {len(parts)}"); continue
    asset,typ,path,status,score,confidence,used,success,failure,last_used,use_when,avoid_when,evidence,notes=parts
    rows += 1
    if asset in seen: errors.append(f"{asset}: duplicate asset_id")
    seen.add(asset)
    if any(not x for x in parts): errors.append(f"{asset}: empty field")
    if typ not in {'template','pattern'}: errors.append(f"{asset}: invalid type")
    if status not in {'active','candidate','deprecated','waived'}: errors.append(f"{asset}: invalid status")
    if confidence not in {'low','medium','high'}: errors.append(f"{asset}: invalid confidence")
    if score not in {'1','2','3','4','5'}: errors.append(f"{asset}: invalid score")
    if not all(x.isdigit() for x in [used,success,failure]): errors.append(f"{asset}: counts must be integers")
    elif int(success)+int(failure)>int(used): errors.append(f"{asset}: counts inconsistent")
    if len(last_used)!=10 or last_used[4]!='-' or last_used[7]!='-': errors.append(f"{asset}: invalid last_used")
    if not exists(path): errors.append(f"{asset}: path not found")
    if not exists(evidence): errors.append(f"{asset}: evidence not found")
    if len(use_when)<25 or len(avoid_when)<25: errors.append(f"{asset}: guidance too short")
if rows < int(__import__('os').environ.get('EOS_TEMPLATE_PATTERN_RATINGS_MIN_ROWS','1')):
    errors.append(f"expected more rating rows, found {rows}")
if errors:
    print('\n'.join('template pattern ratings failed: '+e for e in errors), file=sys.stderr)
    sys.exit(1)
print(f"template pattern ratings checks passed ({rows} assets)")
PY
