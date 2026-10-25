#!/usr/bin/env bash
# Build Cruth's C++ geometry core as Packages/CruthKit/CruthCore.xcframework (PRD D4).
#
#   ./scripts/build-cruth.sh            build from the checkout in ../Cruth (or $CRUTH_DIR)
#
# Slices: iOS device (arm64), iOS simulator (arm64) and macOS (arm64), so the
# Swift wrapper is tested headless on the Mac as well as in the app. The Cruth
# commit the app was last verified against is pinned in spec/cruth-commit; the
# script warns when the checkout differs, and CI checks out exactly that commit.
# SPDX-License-Identifier: MIT
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cruth="${CRUTH_DIR:-$root/../Cruth}"
work="$root/build/cruth"
out="$root/Packages/CruthKit/CruthCore.xcframework"
pinned="$(tr -d '[:space:]' < "$root/spec/cruth-commit")"

fail() { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }
[[ -f "$cruth/core/include/cruth/cruth.h" ]] || fail "Cruth not found at $cruth; clone github.com/Fiavaion/Cruth there or set CRUTH_DIR"
command -v cmake >/dev/null || fail "cmake is missing: brew install cmake ninja"
command -v ninja >/dev/null || fail "ninja is missing: brew install ninja"

actual="$(git -C "$cruth" rev-parse HEAD 2>/dev/null || echo unknown)"
if [[ "$actual" != "$pinned" ]]; then
  printf '\033[33mwarning:\033[0m Cruth is at %s, spec/cruth-commit pins %s\n' "${actual:0:12}" "${pinned:0:12}" >&2
fi

# build_slice <name> <cmake platform args...>: configure, build, merge the static libs into
# $work/<name>/libCruthCore.a. Called directly, never in $(...): bash 3.2 turns set -e off
# inside command substitution, which once let a failed build package stale libraries.
build_slice() {
  local name="$1"; shift
  local dir="$work/$name"
  rm -f "$dir/libCruthCore.a"
  cmake -S "$cruth" -B "$dir" -G Ninja -DCMAKE_BUILD_TYPE=Release \
    -DCRUTH_BUILD_TESTS=OFF -DCRUTH_BUILD_CLI=OFF -DCMAKE_OSX_ARCHITECTURES=arm64 "$@" >/dev/null \
    || fail "cmake configure failed for $name"
  cmake --build "$dir" --target cruth_core cruth_quadriflow cruth_mikktspace >/dev/null \
    || fail "cmake build failed for $name (rerun: cmake --build $dir)"
  libtool -static -o "$dir/libCruthCore.a" \
    "$dir/core/libcruth_core.a" "$dir/third_party/libcruth_quadriflow.a" "$dir/third_party/libcruth_mikktspace.a" \
    || fail "libtool failed for $name"
}

ios=(-DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_DEPLOYMENT_TARGET=27.0)
build_slice ios "${ios[@]}" -DCMAKE_OSX_SYSROOT=iphoneos
build_slice ios-simulator "${ios[@]}" -DCMAKE_OSX_SYSROOT=iphonesimulator
build_slice macos -DCMAKE_OSX_DEPLOYMENT_TARGET=26.0

# Only the C API is public; the module map lets Swift `import CruthCore`.
headers="$work/headers"
rm -rf "$headers" && mkdir -p "$headers"
cp "$cruth/core/include/cruth/cruth.h" "$headers/"
cat > "$headers/module.modulemap" <<'EOF'
module CruthCore {
    header "cruth.h"
    link "c++"
    export *
}
EOF

rm -rf "$out"
xcodebuild -create-xcframework \
  -library "$work/ios/libCruthCore.a" -headers "$headers" \
  -library "$work/ios-simulator/libCruthCore.a" -headers "$headers" \
  -library "$work/macos/libCruthCore.a" -headers "$headers" \
  -output "$out" >/dev/null
echo "$actual" > "$out/cruth-commit"
echo "built $out from Cruth ${actual:0:12}"
