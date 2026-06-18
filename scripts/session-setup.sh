#!/usr/bin/env bash
#
# session-setup.sh — runs at every SessionStart (via .claude/settings.json hook).
# Ensures resource-saving tools (graphify, RTK) are installed and ready.
# Safe to run repeatedly; fails gracefully if network is unavailable.
#
# Governing policy: core/resource-management.md  (<graphify-pre-code>, <rtk>)
# Hook registration: .claude/settings.json (SessionStart)

set -u

EOS_ROOT="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)"

G=$'\033[32m'; Y=$'\033[33m'; D=$'\033[2m'; Z=$'\033[0m'
ok()   { printf '%s✅%s %s\n' "$G" "$Z" "$1"; }
warn() { printf '%s⚠️ %s%s\n' "$Y" "$Z" "$1"; }
info() { printf '%s[session]%s %s\n' "$D" "$Z" "$1"; }

# ── 1. HTTPS override (no SSH agent in web sessions) ─────────────────────────
git config --global url."https://github.com/".insteadOf "git@github.com:" 2>/dev/null || true

# ── 2. graphify ──────────────────────────────────────────────────────────────
if ! command -v graphify >/dev/null 2>&1; then
  info "graphify not found — installing..."
  if command -v uv >/dev/null 2>&1; then
    uv tool install graphifyy --quiet 2>&1 | tail -1 && ok "graphify installed" || warn "graphify install failed"
  elif command -v pip3 >/dev/null 2>&1; then
    pip3 install graphifyy --quiet 2>&1 | tail -1 && ok "graphify installed (pip)" || warn "graphify install failed"
  else
    warn "graphify unavailable: no uv or pip3 found"
  fi
fi

if command -v graphify >/dev/null 2>&1; then
  GRAPH="$EOS_ROOT/graphify-out/graph.json"
  if [ ! -f "$GRAPH" ]; then
    info "building knowledge graph..."
    ( cd "$EOS_ROOT" && graphify extract . 2>&1 | tail -2 ) \
      && ok "graphify graph built" \
      || warn "graphify extract failed (see error above)"
  else
    NODES=$(python3 -c "import json; g=json.load(open('$GRAPH')); print(len(g.get('nodes',[])))" 2>/dev/null || echo "?")
    ok "graphify ready — $NODES nodes in graph"
  fi

  # Generate GRAPH_REPORT.md and wiki/ for broad navigation (referenced in CLAUDE.md)
  if [ ! -f "$EOS_ROOT/graphify-out/GRAPH_REPORT.md" ]; then
    info "generating GRAPH_REPORT.md and wiki/..."
    ( cd "$EOS_ROOT" && graphify cluster-only . 2>&1 | tail -2 ) \
      && ok "GRAPH_REPORT.md and wiki/ generated" \
      || warn "graphify cluster-only failed"
  fi
fi

# ── 3. RTK ───────────────────────────────────────────────────────────────────
if ! command -v rtk >/dev/null 2>&1; then
  info "RTK not found — installing..."
  if command -v cargo >/dev/null 2>&1; then
    cargo install --git https://github.com/rtk-ai/rtk --quiet 2>&1 | tail -1 \
      && ok "RTK installed" \
      || warn "RTK install failed (network/cargo issue)"
  else
    warn "RTK unavailable: cargo not found (install via: brew install rtk)"
  fi
fi

if command -v rtk >/dev/null 2>&1; then
  ok "RTK $(rtk --version 2>/dev/null | head -1) ready (60-90% Bash token savings)"
fi

# ── Done ─────────────────────────────────────────────────────────────────────
printf '\n'
info "session setup complete."
