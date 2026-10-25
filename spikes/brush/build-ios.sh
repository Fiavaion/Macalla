#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
#
# Builds macalla-brush-ffi (Macalla's C entry point into Brush) for iOS device
# and simulator and packages it as build/MacallaBrush.xcframework.
# See README.md for why it wraps Brush rather than using Brush's own brush-c.
#
#   ./build-ios.sh
#
# Needs: Xcode command line tools, rustup (Homebrew's keg-only one is found).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$HERE/brush-src"
CRATE="$HERE/macalla-brush-ffi"
OUT="$HERE/build"
BRUSH_REPO="https://github.com/ArthurBrussee/brush"
BRUSH_COMMIT="1388f74c6fe0236f68ee4915564bf00e9d2e3747"
TARGETS=(aarch64-apple-ios aarch64-apple-ios-sim)
export IPHONEOS_DEPLOYMENT_TARGET="${IPHONEOS_DEPLOYMENT_TARGET:-18.0}"

for dir in /opt/homebrew/opt/rustup/bin "$HOME/.cargo/bin"; do
    [[ -d "$dir" ]] && PATH="$dir:$PATH"
done
command -v cargo >/dev/null || { echo "cargo not found: install rustup" >&2; exit 1; }
rustup target add "${TARGETS[@]}" >/dev/null

if [[ ! -d "$SRC/.git" ]]; then
    git clone "$BRUSH_REPO" "$SRC"
fi
if [[ "$(git -C "$SRC" rev-parse HEAD)" != "$BRUSH_COMMIT" ]]; then
    git -C "$SRC" fetch --quiet origin
    git -C "$SRC" checkout --quiet "$BRUSH_COMMIT"
fi

for t in "${TARGETS[@]}"; do
    echo "== cargo build macalla-brush-ffi --target $t"
    (cd "$CRATE" && cargo build --locked --release --target "$t")
done

rm -rf "$OUT/MacallaBrush.xcframework" "$OUT/headers"
mkdir -p "$OUT/headers"
cp "$HERE/include/macalla_brush.h" "$HERE/include/module.modulemap" "$OUT/headers/"

# The archives are not stripped: `strip` turns hidden Rust symbols into
# duplicate globals and linking fails. The app's -dead_strip link trims them.
args=()
for t in "${TARGETS[@]}"; do
    args+=(-library "$CRATE/target/$t/release/libmacalla_brush.a" -headers "$OUT/headers")
done
xcodebuild -create-xcframework "${args[@]}" -output "$OUT/MacallaBrush.xcframework"
du -sh "$OUT/MacallaBrush.xcframework"
echo "Built $OUT/MacallaBrush.xcframework (Brush $BRUSH_COMMIT)"
