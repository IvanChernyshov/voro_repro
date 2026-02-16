#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

PATCH_FILE="${PATCH_FILE:-$ROOT_DIR/patches/0001-inflate-max-radius-nextafter-3d.patch}"
SRC_DIR="$ROOT_DIR/voro++"
OUT_DIR="${OUT_DIR:-$ROOT_DIR/.build/voro_patched}"

rm -rf "$OUT_DIR"
mkdir -p "$(dirname "$OUT_DIR")"
cp -R "$SRC_DIR" "$OUT_DIR"

# Apply the patch relative to the Voro++ root.
patch -p1 -d "$OUT_DIR" < "$PATCH_FILE" >/dev/null

echo "Prepared patched Voro++ tree at: $OUT_DIR"
