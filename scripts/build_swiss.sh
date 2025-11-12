#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SWISS_SRC="$ROOT/ThirdParty/SwissEph/src"
OBJ_DIR="$ROOT/ThirdParty/SwissEph/obj"
LIB_DIR="$ROOT/ThirdParty/SwissEph/lib"

if [ ! -d "$SWISS_SRC" ]; then
  echo "Swiss Ephemeris sources not found at $SWISS_SRC" >&2
  exit 1
fi

mkdir -p "$OBJ_DIR" "$LIB_DIR"
rm -f "$OBJ_DIR"/*.o "$LIB_DIR"/libswe.a

SDK_PATH="$(xcrun --sdk iphonesimulator --show-sdk-path)"
CFLAGS=(
  -arch arm64
  -isysroot "$SDK_PATH"
  -mios-simulator-version-min=13.0
  -I"$SWISS_SRC"
)

echo ":: Building Swiss Ephemeris objects for simulator"
for src in "$SWISS_SRC"/*.c; do
  base="$(basename "${src%.*}")"
  xcrun clang "${CFLAGS[@]}" -c "$src" -o "$OBJ_DIR/$base.o"
done

echo ":: Archiving into libswe.a"
libtool -static -o "$LIB_DIR/libswe.a" "$OBJ_DIR"/*.o

echo "Swiss Ephemeris simulator archive ready at $LIB_DIR/libswe.a"
