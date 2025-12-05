#!/usr/bin/env bash
set -euo pipefail

# Builds the Swiss Ephemeris static library for both device (iphoneos) and
# simulator (iphonesimulator) and merges them into ThirdParty/SwissEph/lib/libswe.a
# so Xcode can link for tests/archives without manual prep.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="$ROOT_DIR/ThirdParty/SwissEph/src"
OUT_DIR="$ROOT_DIR/ThirdParty/SwissEph/lib"

mkdir -p "$OUT_DIR"

build_arch() {
  local sdk="$1" arch="$2" tag="$3"
  local sdk_path
  sdk_path="$(xcrun --sdk "$sdk" --show-sdk-path)"
  local cc
  cc="$(xcrun --sdk "$sdk" -f clang)"
  local build_dir="$OUT_DIR/build-$tag"
  rm -rf "$build_dir"
  mkdir -p "$build_dir"

  pushd "$SRC_DIR" >/dev/null
  for c in swe*.c swem*.c sweh*.c; do
    # Skip the test harness if present
    [[ "$c" == "swetest.c" ]] && continue
    "$cc" -arch "$arch" -isysroot "$sdk_path" -O2 -I. -c "$c" -o "$build_dir/${c%.c}.o"
  done
  libtool -static -o "$build_dir/libswe.a" "$build_dir"/*.o
  popd >/dev/null
}

echo "Building SwissEph for device (iphoneos, arm64)..."
build_arch iphoneos arm64 ios
cp "$OUT_DIR/build-ios/libswe.a" "$OUT_DIR/libswe_ios.a"

echo "Building SwissEph for simulator (iphonesimulator, arm64)..."
build_arch iphonesimulator arm64 sim
cp "$OUT_DIR/build-sim/libswe.a" "$OUT_DIR/libswe_sim.a"

# Default libswe.a remains the device slice for backward compatibility (IPA builds).
cp "$OUT_DIR/libswe_ios.a" "$OUT_DIR/libswe.a"

echo "SwissEph static libraries ready at:"
ls -l "$OUT_DIR"/libswe*.a
