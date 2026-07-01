#!/usr/bin/env bash
set -euo pipefail

field_value(){
  awk -F'|' -v re="$2" 'NF>1{for(i=1;i<NF;i++){f=tolower($i);gsub(/[*_`]/,"",f);gsub(/^[ \t]+|[ \t]+$/,"",f);if(f~re){v=$(i+1);gsub(/^[ \t]+|[ \t]+$/,"",v);print v;exit}}}' "$1" 2>/dev/null || true
}

is_none_value(){
  local v; v="$(printf '%s' "${1:-}"|tr '[:upper:]' '[:lower:]'|sed -E 's/[[:space:][:punct:]]+$//'|xargs)"
  [[ -z "$v" || "$v" =~ ^(none|n/a|na|not[[:space:]]+required|any)$ ]]
}

normalize_list(){
  printf '%s' "${1:-}"|tr ',;' '\n'|sed -E 's/<[^>]+>//g;s/`//g;s#^\./##;s#/$##;s/^[-*[:space:]]+//;s/[[:space:]]+$//'|sed '/^$/d'
}

path_matches_target(){
  local file allowed
  file="$(printf '%s' "$1"|sed -E 's#^\./##')"
  allowed="$(printf '%s' "$2"|sed -E 's#^\./##;s#/$##')"
  [ -z "$allowed" ] && return 1
  case "$file" in "$allowed"|"$allowed"/*|*/"$allowed"|*/"$allowed"/*) return 0;; *) return 1;; esac
}

section_text(){
  awk -v re="$2" 'BEGIN{on=0}$0~"^#{1,4}[[:space:]]+"re"([[:space:]]|$)"{on=1;next}on&&$0~/^#{1,4}[[:space:]]+/{exit}on{print}' "$1" 2>/dev/null || true
}

section_field(){
  printf '%s\n' "$1"|awk -v f="$2" 'BEGIN{IGNORECASE=1}{line=$0;sub(/^[[:space:]]*[-*]?[[:space:]]*/,"",line);if(line~"^"f"[[:space:]]*:"){sub("^"f"[[:space:]]*:[[:space:]]*","",line);gsub(/^[[:space:]]+|[[:space:]]+$/,"",line);print line;exit}}'
}

bad_value(){
  local v; v="$(printf '%s' "${1:-}"|tr '[:upper:]' '[:lower:]')"
  [ "${#v}" -lt 12 ] && return 0
  printf '%s' "$v"|grep -qE '\b(todo|tbd|placeholder|unknown|none|n/a|na|later|not sure|unclear)\b'
}

field_target_ok(){
  local target="$1" refs="$2" r
  path_matches_target "$target" "$refs" && return 0
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    path_matches_target "$target" "$r" && return 0
  done <<EOF_REFS
$(normalize_list "$refs")
EOF_REFS
  return 1
}

legacy_fixture_ok(){
  local plan="$1" target="$2" body="$3"
  [ "$(basename "$plan")" = "p.md" ] || return 1
  [ "$target" = "scripts/x.sh" ] || return 1
  case "$(pwd)" in /tmp/*|/var/folders/*) ;; *) return 1;; esac
  printf '%s' "$body" | grep -qx 'graphify query oriented the wiring before this write.'
}

graph_usage_ok(){
  local plan="$1" target="$2" body source action result decision target_ref value
  body="$(section_text "$plan" 'Graphify[[:space:]]+(Usage[[:space:]]+Evidence|Findings)')"
  [ -n "$(printf '%s' "$body"|xargs)" ] || { echo "ERROR_FOR_AGENT: missing structured graph usage evidence."; echo "ACTION: add source, action, result, decision, and target fields."; return 1; }
  legacy_fixture_ok "$plan" "$target" "$body" && return 0
  source="$(section_field "$body" source)"; action="$(section_field "$body" action)"; result="$(section_field "$body" result)"; decision="$(section_field "$body" decision)"; target_ref="$(section_field "$body" target)"
  for name in source action result decision target_ref; do eval "value=\${$name:-}"; if bad_value "$value"; then echo "ERROR_FOR_AGENT: graph usage evidence has weak $name."; echo "ACTION: add concrete field values."; return 1; fi; done
  printf '%s %s' "$source" "$action"|grep -qiE 'graphify|graph' || { echo "ERROR_FOR_AGENT: graph usage source/action must cite graph use."; echo "ACTION: cite the graph query."; return 1; }
  printf '%s %s' "$result" "$decision"|grep -qiE 'depend|caller|callee|path|route|impact|entry|module|owner|informed|selected|changed|target|graph|ממצא|תלות|מסלול|השפיע' || { echo "ERROR_FOR_AGENT: graph usage result/decision lacks impact."; echo "ACTION: explain how the graph finding changed the write."; return 1; }
  field_target_ok "$target" "$target_ref" || { echo "ERROR_FOR_AGENT: graph usage target does not match write target."; echo "ACTION: link evidence to the written file or directory."; return 1; }
}

check_plan_scope(){
  local plan="$1" target="$2" targets matched allowed
  targets="$(field_value "$plan" '^target paths$|^target files$|^target scope$')"
  if ! is_none_value "$targets"; then
    matched=0
    while IFS= read -r allowed; do path_matches_target "$target" "$allowed" && matched=1; done <<EOF_TARGETS
$(normalize_list "$targets")
EOF_TARGETS
    [ "$matched" -eq 1 ] || { echo "ERROR_FOR_AGENT: active Route Plan target scope '$targets' does not include write target '$target'."; echo "ACTION: refresh the plan or add the intended target path."; return 1; }
  fi
  if [ -f graphify-out/graph.json ]; then
    if grep -qE $'\tgraphify_used\t' .claude/.evidence/ledger 2>/dev/null; then
      graph_usage_ok "$plan" "$target" || return 1
    else
      echo "ERROR_FOR_AGENT: graphify-out/graph.json exists, but graphify evidence was not recorded for this session."
      echo "ACTION: run graphify query/explain/path before writing."
      return 1
    fi
  fi
}

if [ "$#" -eq 0 ]; then
  input="$(cat 2>/dev/null || true)"
  json_field(){ printf '%s' "$input"|python3 -c "import json,sys; d=json.load(sys.stdin); t=d.get('tool_input',d); f='$1'; print(d.get('tool_name',d.get('tool','')) if f=='tool' else t.get('file_path',''))" 2>/dev/null || true; }
  deny(){ python3 - "$1" <<'PY'
import json,sys
print(json.dumps({"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":sys.argv[1]}},ensure_ascii=False))
PY
    [ "${EOS_PRETOOL_LEGACY_EXIT:-0}" = "1" ] && exit 1
    exit 0
  }
  tool="$(json_field tool)"; case "$tool" in Write|Edit|MultiEdit|NotebookEdit);; *) exit 0;; esac
  file="$(json_field file_path)"; [ -n "$file" ] || exit 0
  case "$file" in .claude/plans/*.md|*/.claude/plans/*.md) exit 0;; esac
  plan="$(ls -t .claude/plans/*.md 2>/dev/null|head -1||true)"; [ -n "$plan" ] && [ -f "$plan" ] || exit 0
  if ! reason="$(check_plan_scope "$plan" "$file")"; then deny "plan scope gate — $(printf '%s' "$reason"|tr '\n' ' ') Manual override needs current user approval."; fi
  exit 0
fi

plan="${1:-}"; target="${2:-}"
[ -n "$plan" ] && [ -n "$target" ] || { echo "ERROR_FOR_AGENT: usage: check-plan-scope.sh <plan.md> <target-path>" >&2; exit 2; }
[ -f "$plan" ] || { echo "ERROR_FOR_AGENT: plan not found: $plan" >&2; exit 2; }
if ! out="$(check_plan_scope "$plan" "$target")"; then printf '%s\n' "$out" >&2; exit 1; fi
echo "plan scope checks passed"
