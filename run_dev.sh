#!/usr/bin/env bash
set -euo pipefail

# Build + run the Voro++ *dev* reproduction.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VORO_DIR="${VORO_DIR:-$ROOT_DIR/voro_dev}"
VORO_SRC="$VORO_DIR/src"

CXX="${CXX:-c++}"
CXXFLAGS_DEFAULT="-O2 -std=c++11"
CXXFLAGS="${CXXFLAGS:-$CXXFLAGS_DEFAULT}"

OUT_FILE="${1:-out_dev.txt}"

"$CXX" $CXXFLAGS -I"$VORO_SRC" \
  "$ROOT_DIR/main_dev.cpp" \
  "$VORO_SRC/voro++.cc" \
  -o "$ROOT_DIR/repro_dev"

"$ROOT_DIR/repro_dev" | tee "$ROOT_DIR/$OUT_FILE"
