#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECKER="$ROOT/scripts/enforcement/check-scaling-extension.py"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

python3 "$CHECKER" --root "$ROOT"

copy_repo() {
  local name="$1"
  local repo="$TMPDIR/$name"
  mkdir -p "$repo"
  tar --exclude='.git' -C "$ROOT" -cf - . | tar -C "$repo" -xf -
  printf '%s\n' "$repo"
}

expect_reject() {
  local name="$1"
  local repo="$2"
  if python3 "$repo/scripts/enforcement/check-scaling-extension.py" --root "$repo" >/tmp/scaling-$name.out 2>&1; then
    echo "ERROR_FOR_AGENT: scaling checker accepted incomplete fixture $name" >&2
    cat /tmp/scaling-$name.out >&2
    exit 1
  fi
  echo "rejected incomplete fixture: $name"
}

repo="$(copy_repo missing-template)"
mkdir -p "$repo/templates/unregistered-app"
expect_reject missing-template "$repo"

repo="$(copy_repo missing-roadmap)"
awk 'BEGIN{FS=OFS="\t"} !/^web-application\t/' "$repo/scripts/enforcement/project-type-roadmaps.tsv" > "$repo/roadmaps.tmp"
mv "$repo/roadmaps.tmp" "$repo/scripts/enforcement/project-type-roadmaps.tsv"
expect_reject missing-roadmap "$repo"

repo="$(copy_repo missing-docs-metadata)"
awk 'BEGIN{FS=OFS="\t"} $3=="web-application"{$6="NONE"} {print}' "$repo/scripts/enforcement/documentation-sources.tsv" > "$repo/docs.tmp"
mv "$repo/docs.tmp" "$repo/scripts/enforcement/documentation-sources.tsv"
expect_reject missing-docs-metadata "$repo"

repo="$(copy_repo missing-pattern-skill)"
for file in pattern-requirements.tsv skill-requirements.tsv; do
  awk 'BEGIN{FS=OFS="\t"} $3!="web-application"' "$repo/scripts/enforcement/$file" > "$repo/$file.tmp"
  mv "$repo/$file.tmp" "$repo/scripts/enforcement/$file"
done
expect_reject missing-pattern-skill "$repo"

repo="$(copy_repo missing-game-evidence)"
awk 'BEGIN{FS=OFS="\t"} $1=="game-development"{$7="telemetry export"} {print}' "$repo/scripts/enforcement/project-type-roadmaps.tsv" > "$repo/game.tmp"
mv "$repo/game.tmp" "$repo/scripts/enforcement/project-type-roadmaps.tsv"
expect_reject missing-game-evidence "$repo"

repo="$(copy_repo missing-project-type-roadmap)"
awk 'BEGIN{FS=OFS="\t"} !/^admin-dashboard\t/' "$repo/scripts/enforcement/project-type-roadmaps.tsv" > "$repo/roadmaps2.tmp"
mv "$repo/roadmaps2.tmp" "$repo/scripts/enforcement/project-type-roadmaps.tsv"
expect_reject missing-project-type-roadmap "$repo"

repo="$(copy_repo stale-roadmap-template-path)"
awk 'BEGIN{FS=OFS="\t"} $1=="admin-dashboard"{$5="NONE"} {print}' "$repo/scripts/enforcement/project-type-roadmaps.tsv" > "$repo/roadmaps3.tmp"
mv "$repo/roadmaps3.tmp" "$repo/scripts/enforcement/project-type-roadmaps.tsv"
expect_reject stale-roadmap-template-path "$repo"

echo "scaling extension checker tests passed"
