#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
#
# Runs the Brush spike on a connected iPhone or iPad:
#
#   ./run-device.sh DATASET [ITERATIONS]
#
# DATASET is a COLMAP or Nerfstudio (transforms.json) folder. It is bundled
# into the runner app, which trains it once at launch and prints
# "BRUSH RESULT {...}" (iterations/s, wall time, peak memory). ITERATIONS
# defaults to 7000, the ADR 0001 decision run. Set BRUSH_DEVICE to a UDID to
# pick a device. Signing comes from ../../Signing.local.xcconfig.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
RUNNER="$HERE/runner"
DERIVED="$HERE/build/DerivedData"
dataset="${1:?usage: run-device.sh DATASET [ITERATIONS]}"
iterations="${2:-7000}"
[[ -d "$dataset" ]] || { echo "not a folder: $dataset" >&2; exit 1; }

[[ -d "$HERE/build/MacallaBrush.xcframework" ]] || "$HERE/build-ios.sh"

rm -rf "$RUNNER/Dataset"
cp -R "$dataset" "$RUNNER/Dataset"
xcodegen generate --quiet --spec "$RUNNER/project.yml" --project "$RUNNER"

device="${BRUSH_DEVICE:-}"
if [[ -z "$device" ]]; then
    device="$(xcrun devicectl list devices 2>/dev/null | grep -Ei 'iphone|ipad' | grep -v -e simulated -e unavailable \
        | grep -oE '[0-9A-Fa-f-]{20,40} \(UDID\)' | head -1 | cut -d' ' -f1 || true)"
fi
[[ -n "$device" ]] || { echo "no device: connect, unlock, trust this Mac, enable Developer Mode, or set BRUSH_DEVICE" >&2; exit 1; }

xcodebuild -project "$RUNNER/BrushSpike.xcodeproj" -scheme BrushSpike -configuration Release \
    -destination "id=$device" -derivedDataPath "$DERIVED" \
    -allowProvisioningUpdates -allowProvisioningDeviceRegistration build \
    | grep -E "error|warning: .*BrushSpike|BUILD" || true
app="$DERIVED/Build/Products/Release-iphoneos/BrushSpike.app"
[[ -d "$app" ]] || { echo "build failed" >&2; exit 1; }
bundle_id="$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$app/Info.plist")"

xcrun devicectl device install app --device "$device" "$app"
# Keep the device unlocked and the app in the foreground for the whole run.
xcrun devicectl device process launch --console --terminate-existing \
    --environment-variables "{\"BRUSH_ITERS\": \"$iterations\"}" --device "$device" "$bundle_id"
