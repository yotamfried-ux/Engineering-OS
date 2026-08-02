#!/usr/bin/env bash
# evidence.sh — shared per-session evidence ledger for Engineering OS enforcers.
#
# Purpose: a hook cannot verify "Claude used tool X" directly — it can only block
# an action until PROOF that a prerequisite ran exists. PostToolUse hooks record
# evidence here; PreToolUse gate enforcers check it before allowing dependent actions.
#
# This is shared infrastructure (a library), not a per-tool enforcer. Source it:
#   . "$(dirname "$0")/lib/evidence.sh"
#
# Ledger: .claude/.evidence/ledger  (relative to project cwd; reset each session)
# Line format: <epoch>\t<key>\t<value>

# Resolve ledger path relative to the current project (cwd), not the script dir,
# so it follows the project the hooks run in.
_evidence_dir() { printf '%s' "${EOS_EVIDENCE_DIR:-.claude/.evidence}"; }
_evidence_file() { printf '%s/ledger' "$(_evidence_dir)"; }

# evidence_reset — truncate the ledger (called at SessionStart).
evidence_reset() {
  local dir; dir="$(_evidence_dir)"
  if ! mkdir -p "$dir" 2>/dev/null; then
    printf 'evidence_reset: WARNING — could not create ledger dir %s\n' "$dir" >&2
    return 1
  fi
  if ! : > "$(_evidence_file)" 2>/dev/null; then
    printf 'evidence_reset: WARNING — could not truncate ledger %s\n' "$(_evidence_file)" >&2
    return 1
  fi
}

# evidence_record <key> [value] — append an evidence line.
# Returns 1 and prints to stderr if the ledger cannot be written (silent failure was
# a systemic bug: gates would pass as if evidence existed when mkdir/write failed).
evidence_record() {
  local key="${1:-}" val="${2:-}"
  [ -z "$key" ] && return 0
  local dir; dir="$(_evidence_dir)"
  if ! mkdir -p "$dir" 2>/dev/null; then
    printf 'evidence_record: WARNING — could not create ledger dir %s (gate may pass without proof)\n' "$dir" >&2
    return 1
  fi
  if ! printf '%s\t%s\t%s\n' "$(date +%s 2>/dev/null || echo 0)" "$key" "$val" \
    >> "$(_evidence_file)" 2>/dev/null; then
    printf 'evidence_record: WARNING — could not write to ledger %s (gate may pass without proof)\n' "$(_evidence_file)" >&2
    return 1
  fi
}

# evidence_has <key> [value] — exit 0 if an evidence line matches, else 1.
# With value: matches key AND value. Without: matches key only.
evidence_has() {
  local key="${1:-}" val="${2:-}"
  local f; f="$(_evidence_file)"
  [ -f "$f" ] || return 1
  if [ -n "$val" ]; then
    grep -qF "$(printf '\t%s\t%s' "$key" "$val")" "$f"
  else
    grep -qF "$(printf '\t%s\t' "$key")" "$f"
  fi
}

# evidence_get <key> — prints the last value recorded for key (empty if none).
evidence_get() {
  local key="${1:-}"
  local f; f="$(_evidence_file)"
  [ -f "$f" ] || { printf ''; return 1; }
  grep -F "$(printf '\t%s\t' "$key")" "$f" | tail -1 | cut -f3
}

# eos_select_plan [target-hint] — select the active Route Plan deterministically.
# Precedence: (1) EOS_ACTIVE_PLAN when readable; (2) .claude/plans/active.md;
# (3) newest plan whose "Target paths" field matches the target hint;
# (4) newest plan (legacy behavior) when nothing matches or no hint is given.
# Corrective only: a session holding an older matching plan and a newer unrelated
# plan now selects the matching one; with no match, behavior is unchanged.
eos_select_plan() {
  local hint="${1:-}" candidate targets t file prefix newest=""
  if [ -n "${EOS_ACTIVE_PLAN:-}" ] && [ -f "${EOS_ACTIVE_PLAN:-}" ]; then
    printf '%s\n' "$EOS_ACTIVE_PLAN"; return 0
  fi
  if [ -f .claude/plans/active.md ]; then
    printf '%s\n' .claude/plans/active.md; return 0
  fi
  file="$(printf '%s' "$hint" | sed -E 's#^\./##')"
  for candidate in $(ls -t .claude/plans/*.md 2>/dev/null || true); do
    case "$(basename "$candidate")" in README.md|_TEMPLATE.md) continue ;; esac
    [ -n "$newest" ] || newest="$candidate"
    [ -n "$file" ] || continue
    targets="$(awk -F'|' 'NF>1{for(i=1;i<NF;i++){f=tolower($i);gsub(/[*_`]/,"",f);gsub(/^[ \t]+|[ \t]+$/,"",f);if(f ~ /^target paths?$|^target files$|^target scope$/){v=$(i+1);gsub(/^[ \t]+|[ \t]+$/,"",v);print v;exit}}}' "$candidate" 2>/dev/null)"
    [ -n "$targets" ] || continue
    targets_norm="$(printf '%s' "$targets" | tr '[:upper:]' '[:lower:]' | sed -E 's/[[:space:][:punct:]]+$//' | sed -E 's/^[[:space:]]+//')"
    case "$targets_norm" in
      none|n/a|na|not\ required|any) printf '%s\n' "$candidate"; return 0 ;;
    esac
    while IFS= read -r t; do
      [ -n "$t" ] || continue
      prefix="$(printf '%s' "$t" | sed -E 's/<[^>]+>//g; s/`//g; s#^\./##; s#/$##; s/^[-*[:space:]]+//; s/[[:space:]]+$//')"
      [ -n "$prefix" ] || continue
      case "$file" in
        "$prefix"|"$prefix"/*|*/"$prefix"|*/"$prefix"/*) printf '%s\n' "$candidate"; return 0 ;;
      esac
    done <<EOF_TARGETS
$(printf '%s' "$targets" | tr ',;' '\n')
EOF_TARGETS
  done
  [ -n "$newest" ] && printf '%s\n' "$newest"
}

# eos_connector_is_waived <plan-file> <connector> — exit 0 only when the
# connector's own entry in a documented Connector Evidence section explicitly
# records an unavailable/fallback/waiver decision. Shared by Write/Edit and Stop
# gates so a valid waiver has identical semantics throughout the task lifecycle.
eos_connector_is_waived() {
  local plan_file="${1:-}" connector="${2:-}"
  [ -f "$plan_file" ] && [ -n "$connector" ] || return 1
  python3 - "$plan_file" "$connector" <<'PY'
import re
import sys
from pathlib import Path

plan_path, connector = sys.argv[1:3]
text = Path(plan_path).read_text(encoding="utf-8", errors="replace")

def norm(value: str) -> str:
    value = re.sub(r"[`*_]", "", value or "").lower()
    return re.sub(r"[^a-z0-9]+", " ", value).strip()

def section(title: str) -> str:
    lines = text.splitlines()
    out = []
    active = False
    for line in lines:
        if re.match(r"^#{1,4}\s+" + title + r"(?:\s|$)", line, re.I):
            active = True
            continue
        if active and re.match(r"^#{1,4}\s+", line):
            break
        if active:
            out.append(line)
    return "\n".join(out)

needle = norm(connector)
marker = re.compile(r"\b(unavailable|not available|fallback|waived|waiver|not used)\b", re.I)
for body in (section(r"Connector\s+Evidence"), section(r"Connector\s+Usage\s+Evidence")):
    lines = body.splitlines()
    for index, line in enumerate(lines):
        if needle and not re.search(r"(?<![a-z0-9])" + re.escape(needle) + r"(?![a-z0-9])", norm(line)):
            continue
        block = [line]
        base_indent = len(line) - len(line.lstrip())
        for following in lines[index + 1:]:
            if not following.strip() or re.match(r"^#{1,4}\s+", following):
                break
            indent = len(following) - len(following.lstrip())
            if re.match(r"^\s*[-*]\s+\S", following) and indent <= base_indent:
                break
            if indent > base_indent:
                block.append(following)
                continue
            break
        if marker.search("\n".join(block)):
            raise SystemExit(0)
raise SystemExit(1)
PY
}

# eos_truthy <value> — canonical boolean normalization used by bypass request handling.
# This helper is intentionally defined before any master-request rejection code.
eos_truthy() {
  case "${1:-}" in
    1|true|TRUE|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

# Pinned bypass trust-boundary paths. These are derived from this library's own
# location and are never selected through ordinary environment variables.
_eos_bypass_enforcement_root() {
  local lib_dir
  lib_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)" || return 1
  printf '%s\n' "$(dirname -- "$lib_dir")"
}
_eos_bypass_policy_path() { printf '%s/bypass-policy.tsv\n' "$(_eos_bypass_enforcement_root)"; }
_eos_bypass_control_path() { printf '%s/bypass-control-plane.json\n' "$(_eos_bypass_enforcement_root)"; }
_eos_bypass_validator_path() { printf '%s/validate-bypass-approval.py\n' "$(_eos_bypass_enforcement_root)"; }

# bypass_sha256_text <text> — canonical lowercase SHA-256 for explicit context.
bypass_sha256_text() {
  command -v python3 >/dev/null 2>&1 || return 1
  printf '%s' "${1:-}" | python3 -c 'import hashlib,sys; print(hashlib.sha256(sys.stdin.buffer.read()).hexdigest())'
}

# bypass_current_repository — print owner/name from the origin remote.
bypass_current_repository() {
  local url
  command -v git >/dev/null 2>&1 || return 1
  url="$(git remote get-url origin 2>/dev/null)" || return 1
  python3 - "$url" <<'PY_REPO'
import re, sys
value = sys.argv[1].strip()
patterns = (
    r"^(?:https?://|ssh://git@)github\.com[/:]([^/]+/[^/]+?)(?:\.git)?$",
    r"^git@github\.com:([^/]+/[^/]+?)(?:\.git)?$",
)
for pattern in patterns:
    match = re.match(pattern, value)
    if match:
        print(match.group(1))
        raise SystemExit(0)
raise SystemExit(1)
PY_REPO
}

# bypass_target_commit — bind requests to the exact checked-out commit.
bypass_target_commit() {
  command -v git >/dev/null 2>&1 || return 1
  git rev-parse --verify HEAD 2>/dev/null
}

# bypass_staged_tree_fingerprint — stable digest of the staged tree identity.
bypass_staged_tree_fingerprint() {
  local tree
  command -v git >/dev/null 2>&1 || return 1
  tree="$(git write-tree 2>/dev/null)" || return 1
  bypass_sha256_text "staged-tree:${tree}"
}

# bypass_repository_tree_fingerprint — stable digest of the working repository tree.
bypass_repository_tree_fingerprint() {
  local tree
  command -v git >/dev/null 2>&1 || return 1
  tree="$(git rev-parse 'HEAD^{tree}' 2>/dev/null)" || return 1
  bypass_sha256_text "repository-tree:${tree}"
}

_bypass_reject() {
  local name="${1:-unknown}" reason="${2:-denied}"
  evidence_record "bypass_rejected" "${name}:${reason}" >/dev/null 2>&1 || true
  printf 'BYPASS DENIED: %s — %s\n' "$name" "$reason" >&2
  return 1
}

_bypass_forbidden_path_override_present() {
  local name
  for name in \
    EOS_BYPASS_VALIDATOR_PATH EOS_BYPASS_POLICY_PATH EOS_BYPASS_CONTROL_PLANE_PATH \
    EOS_BYPASS_PROVIDER_PATH EOS_VALIDATOR_PATH EOS_POLICY_PATH EOS_CONTROL_PLANE_PATH \
    EOS_PROVIDER_PATH; do
    [ -z "${!name:-}" ] || return 0
  done
  return 1
}

# bypass_reject_disabled_master_requests <request-name> [<request-name> ...]
# Master bypasses are permanent deny surfaces. A truthy master request must stop
# the caller before any action-specific authorization path can run.
bypass_reject_disabled_master_requests() {
  local name request_value
  declare -f eos_truthy >/dev/null 2>&1 || {
    printf 'BYPASS DENIED: canonical truthy helper is unavailable\n' >&2
    return 1
  }
  declare -f _bypass_reject >/dev/null 2>&1 || {
    printf 'BYPASS DENIED: canonical rejection helper is unavailable\n' >&2
    return 1
  }
  for name in "$@"; do
    [ -n "$name" ] || continue
    request_value="${!name:-}"
    if eos_truthy "$request_value"; then
      _bypass_reject "$name" "master bypass authorization is disabled"
      return 1
    fi
  done
  return 0
}

_bypass_policy_fields() {
  local name="${1:-}" policy_path
  policy_path="$(_eos_bypass_policy_path)" || return 1
  [ -r "$policy_path" ] || return 1
  awk -F '\t' -v request="$name" '
    NR>1 && $1==request {print $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 "\t" $8; found=1; exit}
    END {if(!found) exit 1}
  ' "$policy_path"
}

# bypass_request_authorized <request-name> <target> <fingerprint>
# Derives policy-owned gate/action/surface plus repository and exact HEAD locally.
# Approval references do not use the EOS_BYPASS_* prefix: those names are request
# surfaces only. EOS_APPROVAL_COMMENT_ID is a provider object reference.
bypass_request_authorized() {
  local name="${1:-}" target="${2:-}" fingerprint="${3:-}" preimage_prefix="${4:-}"
  local fields gate action surface target_type fingerprint_contract classification
  local repository target_commit approval_ref
  [ -n "$name" ] || return 1
  eos_truthy "${!name:-}" || return 1
  fields="$(_bypass_policy_fields "$name")" \
    || { _bypass_reject "$name" "request is absent from canonical policy"; return 1; }
  IFS=$'\t' read -r gate action surface target_type fingerprint_contract classification <<<"$fields"
  [ "$classification" = "action-specific" ] \
    || { _bypass_reject "$name" "master or invalid bypass surface cannot authorize"; return 1; }
  # The canonical policy declares the target form and the fingerprint preimage
  # contract for each request. Enforce both here: this is the only layer that
  # holds the preimage, so it is the only layer that can prove derivation.
  case "$target" in
    "$target_type"|"$target_type":*) : ;;
    *) _bypass_reject "$name" "target does not match the canonical policy target_type"; return 1 ;;
  esac
  [ -n "$preimage_prefix" ] && [ "sha256:${preimage_prefix}" = "$fingerprint_contract" ] \
    || { _bypass_reject "$name" "fingerprint was not derived from the canonical policy contract"; return 1; }
  approval_ref="${EOS_APPROVAL_COMMENT_ID:-}"
  case "$approval_ref" in *[!0-9]*|'') _bypass_reject "$name" "missing or invalid approval comment reference"; return 1 ;; esac
  repository="$(bypass_current_repository)" \
    || { _bypass_reject "$name" "repository identity is unavailable"; return 1; }
  target_commit="$(bypass_target_commit)" \
    || { _bypass_reject "$name" "target commit is unavailable"; return 1; }
  bypass_active "$name" "$gate" "$action" "$surface" "$repository" \
    "$target" "$fingerprint" "$target_commit" "$approval_ref"
}

_bypass_staged_tree_identity() {
  command -v git >/dev/null 2>&1 || return 1
  git write-tree 2>/dev/null
}

bypass_staged_tree_request() {
  local name="${1:-}" tree fingerprint
  eos_truthy "${!name:-}" || return 1
  tree="$(_bypass_staged_tree_identity)" \
    || { _bypass_reject "$name" "staged tree identity is unavailable"; return 1; }
  fingerprint="$(bypass_sha256_text "staged-tree:${tree}")" \
    || { _bypass_reject "$name" "staged tree fingerprint failed"; return 1; }
  bypass_request_authorized "$name" "staged-tree:${tree}" "$fingerprint" "staged-tree"
}

bypass_repository_tree_request() {
  local name="${1:-}" tree fingerprint
  eos_truthy "${!name:-}" || return 1
  tree="$(git rev-parse 'HEAD^{tree}' 2>/dev/null)" \
    || { _bypass_reject "$name" "repository tree identity is unavailable"; return 1; }
  fingerprint="$(bypass_sha256_text "repository-tree:${tree}")" \
    || { _bypass_reject "$name" "repository tree fingerprint failed"; return 1; }
  bypass_request_authorized "$name" "repository-tree:${tree}" "$fingerprint" "repository-tree"
}

bypass_command_request() {
  local name="${1:-}" command_text="${2:-}" fingerprint
  eos_truthy "${!name:-}" || return 1
  [ -n "$command_text" ] || { _bypass_reject "$name" "command context is empty"; return 1; }
  fingerprint="$(bypass_sha256_text "canonical-command:${command_text}")" \
    || { _bypass_reject "$name" "command fingerprint failed"; return 1; }
  bypass_request_authorized "$name" "command:${command_text}" "$fingerprint" "canonical-command"
}

bypass_hook_input_request() {
  local name="${1:-}" input="${2:-}" target="${3:-hook-input}" fingerprint
  eos_truthy "${!name:-}" || return 1
  [ -n "$input" ] || { _bypass_reject "$name" "hook input context is empty"; return 1; }
  fingerprint="$(bypass_sha256_text "canonical-hook-input:${input}")" \
    || { _bypass_reject "$name" "hook input fingerprint failed"; return 1; }
  bypass_request_authorized "$name" "$target" "$fingerprint" "canonical-hook-input"
}

bypass_commit_message_request() {
  local name="${1:-}" message="${2:-}" fingerprint
  eos_truthy "${!name:-}" || return 1
  fingerprint="$(bypass_sha256_text "commit-message:${message}")" \
    || { _bypass_reject "$name" "commit-message fingerprint failed"; return 1; }
  bypass_request_authorized "$name" "commit-message" "$fingerprint" "commit-message"
}

bypass_commit_message_staged_tree_request() {
  local name="${1:-}" message="${2:-}" tree fingerprint
  eos_truthy "${!name:-}" || return 1
  tree="$(_bypass_staged_tree_identity)" \
    || { _bypass_reject "$name" "staged tree identity is unavailable"; return 1; }
  fingerprint="$(bypass_sha256_text "commit-message-and-staged-tree:${message}\n${tree}")" \
    || { _bypass_reject "$name" "commit-message/staged-tree fingerprint failed"; return 1; }
  bypass_request_authorized "$name" "commit-message-and-staged-tree:${tree}" "$fingerprint" "commit-message-and-staged-tree"
}

# Force/main push approvals bind the exact command, destination ref, and the live
# remote head observed immediately before authorization. Ambiguous push syntax or
# provider/network failure denies the request.
bypass_git_ref_request() {
  local name="${1:-}" command_text="${2:-}" parsed remote ref remote_head fingerprint
  eos_truthy "${!name:-}" || return 1
  command -v python3 >/dev/null 2>&1 || { _bypass_reject "$name" "python3 is unavailable"; return 1; }
  parsed="$(printf '%s' "$command_text" | python3 -c '''
import shlex,sys,subprocess
try: toks=shlex.split(sys.stdin.read())
except Exception: raise SystemExit(1)
try: i=toks.index("git")
except ValueError: raise SystemExit(1)
j=i+1
# Skip the same global options the detector accepts, so an approved request for
# "git -c key=value push ..." is not denied before provider validation.
value_globals={"-c","--git-dir","--work-tree","--namespace","--exec-path","--config-env"}
while j<len(toks):
    tok=toks[j]
    if tok in value_globals: j+=2; continue
    if tok.startswith("--git-dir=") or tok.startswith("--work-tree=") or tok.startswith("--namespace=") or tok.startswith("--exec-path=") or tok.startswith("--config-env="): j+=1; continue
    if tok in {"--no-pager","--paginate","--bare","--literal-pathspecs","--no-replace-objects"}: j+=1; continue
    break
if j>=len(toks) or toks[j] != "push": raise SystemExit(1)
args=toks[j+1:]
value_opts={"--repo","--receive-pack","--exec"}
position=[]; skip=False
for tok in args:
    if skip: skip=False; continue
    if tok in value_opts: skip=True; continue
    if tok.startswith("-"): continue
    position.append(tok)
remote=position[0] if position else "origin"
refspec=position[1] if len(position)>1 else ""
if len(position)>2: raise SystemExit(1)
if not refspec:
    refspec=subprocess.check_output(["git","symbolic-ref","--quiet","--short","HEAD"],text=True).strip()
refspec=refspec.lstrip("+")
dst=refspec.rsplit(":",1)[-1]
if dst in {"HEAD",""}: raise SystemExit(1)
if not dst.startswith("refs/"): dst="refs/heads/"+dst
print(remote+"\t"+dst)
''' 2>/dev/null)" \
    || { _bypass_reject "$name" "git push destination is ambiguous"; return 1; }
  IFS=$'\t' read -r remote ref <<<"$parsed"
  # The exit status of a pipeline is the status of its last command, so piping
  # straight into awk would mask a timeout, auth failure, or network error and
  # bind the fingerprint to "absent". Capture first, check status, then reduce.
  local lookup_output lookup_status=0
  lookup_output="$(timeout 10s git ls-remote "$remote" "$ref" 2>/dev/null)" || lookup_status=$?
  [ "$lookup_status" -eq 0 ] \
    || { _bypass_reject "$name" "live remote head lookup failed"; return 1; }
  remote_head="$(printf '%s\n' "$lookup_output" | awk 'NR==1 {print $1}')" \
    || { _bypass_reject "$name" "live remote head lookup failed"; return 1; }
  [ -n "$remote_head" ] || remote_head="absent"
  fingerprint="$(bypass_sha256_text "command-ref-and-remote-head:${command_text}\n${remote}\n${ref}\n${remote_head}")" \
    || { _bypass_reject "$name" "git-ref fingerprint failed"; return 1; }
  bypass_request_authorized "$name" "git-ref:${remote}:${ref}:${remote_head}" "$fingerprint" "command-ref-and-remote-head"
}

# bypass_active <request-name> <gate> <action> <surface> <repository>
#               <target> <fingerprint> <target-commit> <approval-comment-id>
#
# A truthy EOS_BYPASS_* value is a request only. Authorization is returned only
# after the pinned validator verifies a live-qualified provider contract and one
# durable claim/marker pair. The local ledger is audit-only.
bypass_active() {
  local name="${1:-}" gate="${2:-}" action="${3:-}" surface="${4:-}"
  local repository="${5:-}" target="${6:-}" fingerprint="${7:-}"
  local target_commit="${8:-}" approval_ref="${9:-}"
  local request_value policy_path control_path validator_path classification
  local output err_file authorized

  [ -n "$name" ] || return 1
  request_value="${!name:-}"
  eos_truthy "$request_value" || return 1

  # Reject incomplete legacy call sites rather than silently treating the env as auth.
  if [ "$#" -ne 9 ] || [ -z "$gate" ] || [ -z "$action" ] || [ -z "$surface" ] \
    || [ -z "$repository" ] || [ -z "$target" ] || [ -z "$fingerprint" ] \
    || [ -z "$target_commit" ] || [ -z "$approval_ref" ]; then
    _bypass_reject "$name" "incomplete canonical bypass context"
    return 1
  fi
  case "$approval_ref" in *[!0-9]*|'') _bypass_reject "$name" "invalid approval comment reference"; return 1 ;; esac
  case "$fingerprint" in [0-9a-f][0-9a-f]*) [ "${#fingerprint}" -eq 64 ] || { _bypass_reject "$name" "invalid target fingerprint"; return 1; } ;; *) _bypass_reject "$name" "invalid target fingerprint"; return 1 ;; esac
  case "$target_commit" in [0-9a-f][0-9a-f]*) [ "${#target_commit}" -eq 40 ] || { _bypass_reject "$name" "invalid target commit"; return 1; } ;; *) _bypass_reject "$name" "invalid target commit"; return 1 ;; esac

  if _bypass_forbidden_path_override_present; then
    _bypass_reject "$name" "validator/policy/control-plane path overrides are forbidden"
    return 1
  fi

  policy_path="$(_eos_bypass_policy_path)" || { _bypass_reject "$name" "canonical helper path resolution failed"; return 1; }
  control_path="$(_eos_bypass_control_path)" || { _bypass_reject "$name" "canonical helper path resolution failed"; return 1; }
  validator_path="$(_eos_bypass_validator_path)" || { _bypass_reject "$name" "canonical helper path resolution failed"; return 1; }
  [ -r "$policy_path" ] || { _bypass_reject "$name" "canonical bypass policy is missing"; return 1; }
  [ -r "$control_path" ] || { _bypass_reject "$name" "canonical control-plane configuration is missing"; return 1; }
  [ -r "$validator_path" ] || { _bypass_reject "$name" "canonical validator is missing"; return 1; }
  command -v python3 >/dev/null 2>&1 || { _bypass_reject "$name" "python3 is unavailable"; return 1; }

  classification="$(awk -F '\t' -v request="$name" 'NR>1 && $1==request {print $8; found=1} END {if(!found) exit 1}' "$policy_path" 2>/dev/null)" \
    || { _bypass_reject "$name" "request is absent from canonical policy"; return 1; }
  if [ "$classification" = "master-disabled" ]; then
    _bypass_reject "$name" "master bypass authorization is disabled"
    return 1
  fi
  [ "$classification" = "action-specific" ] || { _bypass_reject "$name" "invalid policy classification"; return 1; }

  err_file="$(mktemp "${TMPDIR:-/tmp}/eos-bypass.XXXXXX")" \
    || { _bypass_reject "$name" "cannot allocate validator error channel"; return 1; }
  if ! output="$(python3 "$validator_path" \
      --stage consumed \
      --bypass "$name" \
      --gate "$gate" \
      --action "$action" \
      --surface "$surface" \
      --repository "$repository" \
      --target "$target" \
      --target-fingerprint "$fingerprint" \
      --target-commit "$target_commit" \
      --approval-comment-id "$approval_ref" 2>"$err_file")"; then
    rm -f "$err_file"
    _bypass_reject "$name" "provider verification failed closed"
    return 1
  fi
  rm -f "$err_file"

  authorized="$(printf '%s' "$output" | python3 -c 'import json,sys; value=json.load(sys.stdin); print("true" if value.get("authorized") is True else "false")' 2>/dev/null)" \
    || { _bypass_reject "$name" "validator returned malformed JSON"; return 1; }
  [ "$authorized" = "true" ] || { _bypass_reject "$name" "validator did not grant authorization"; return 1; }

  evidence_record "bypass_authorized" "${name}:${approval_ref}:${fingerprint}:${target_commit}" \
    || { _bypass_reject "$name" "authorization audit evidence could not be written"; return 1; }
  printf 'BYPASS AUTHORIZED: %s — provider-verified one-shot approval %s\n' "$name" "$approval_ref" >&2
  return 0
}
