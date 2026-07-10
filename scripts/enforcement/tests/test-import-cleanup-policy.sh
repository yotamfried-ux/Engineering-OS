#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-import-cleanup.py"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass() {
  local name="$1"; shift
  if "$@" >/tmp/import-cleanup-test.log 2>&1; then
    echo "ok: $name"
  else
    echo "fail: $name"
    cat /tmp/import-cleanup-test.log
    exit 1
  fi
}

failcase() {
  local name="$1"; shift
  if "$@" >/tmp/import-cleanup-test.log 2>&1; then
    echo "unexpected pass: $name"
    exit 1
  fi
  echo "ok: $name"
}

run_case() {
  local dir="$1"
  printf '%s\n' "case.jsx" > "$dir/files.txt"
  python3 "$CHECK" --root "$dir" --files-from "$dir/files.txt"
}

mkdir -p "$TMP/unused-default"
cat > "$TMP/unused-default/case.jsx" <<'EOF'
import React from 'react'
export const value = 1
EOF
failcase semicolonless_unused_default_fails run_case "$TMP/unused-default"

mkdir -p "$TMP/unused-named"
cat > "$TMP/unused-named/case.jsx" <<'EOF'
import { useMemo, useState as stateHook } from 'react'
export const value = 1
EOF
failcase semicolonless_unused_named_fails run_case "$TMP/unused-named"

mkdir -p "$TMP/used-default"
cat > "$TMP/used-default/case.jsx" <<'EOF'
import React from 'react'
export const value = React.createElement('div')
EOF
pass semicolonless_used_default_passes run_case "$TMP/used-default"

mkdir -p "$TMP/semicolon"
cat > "$TMP/semicolon/case.jsx" <<'EOF'
import React from 'react';
export const value = 1;
EOF
failcase semicolon_terminated_unused_still_fails run_case "$TMP/semicolon"

mkdir -p "$TMP/multiline"
cat > "$TMP/multiline/case.jsx" <<'EOF'
import {
  useMemo,
  useState as stateHook,
} from 'react'
export const value = useMemo(() => stateHook, [])
EOF
pass multiline_named_import_passes run_case "$TMP/multiline"

mkdir -p "$TMP/side-effect"
cat > "$TMP/side-effect/case.jsx" <<'EOF'
import './styles.css'
export const value = 1
EOF
pass side_effect_import_passes run_case "$TMP/side-effect"

mkdir -p "$TMP/namespace"
cat > "$TMP/namespace/case.ts" <<'EOF'
import * as path from 'node:path'
export const value = path.join('a', 'b')
EOF
printf '%s\n' "case.ts" > "$TMP/namespace/files.txt"
pass namespace_import_passes python3 "$CHECK" --root "$TMP/namespace" --files-from "$TMP/namespace/files.txt"

mkdir -p "$TMP/with-attribute-unused"
cat > "$TMP/with-attribute-unused/case.jsx" <<'EOF'
import data from './data.json' with { type: 'json' };
export const value = 1
EOF
failcase import_with_attribute_unused_fails run_case "$TMP/with-attribute-unused"

mkdir -p "$TMP/assert-attribute-used"
cat > "$TMP/assert-attribute-used/case.jsx" <<'EOF'
import data from './data.json' assert {
  type: 'json',
}
export const value = data
EOF
pass legacy_assert_attribute_used_passes run_case "$TMP/assert-attribute-used"

mkdir -p "$TMP/waiver"
cat > "$TMP/waiver/case.jsx" <<'EOF'
// EOS_SEMANTIC_CLEANUP_WAIVER: imported for a documented build-time side effect
import React from 'react'
export const value = 1
EOF
pass concrete_waiver_passes run_case "$TMP/waiver"

echo "import cleanup policy simulations passed"
