#!/usr/bin/env bash
# Build, run and test the app from the terminal (and from VS Code tasks).
#
#   ./scripts/ios.sh generate   regenerate Macalla.xcodeproj from project.yml
#   ./scripts/ios.sh build      build for the iPhone simulator
#   ./scripts/ios.sh run        build, boot a simulator, install and launch (logs stream here)
#   ./scripts/ios.sh unit       run the package unit tests headless on the Mac (swift test)
#   ./scripts/ios.sh test       unit tests on the Mac, then unit and UI smoke tests in the simulator; extra arguments
#                               go to xcodebuild, e.g. -only-testing:MacallaUITests/LaunchSmokeTests
#   ./scripts/ios.sh device     build, install and launch on a connected iPhone or iPad (needs signing);
#                               arguments after -- go to the app, e.g. device -- -spike splats (spikes are Debug-only)
#   ./scripts/ios.sh open       open the project in Xcode
#   ./scripts/ios.sh clean      delete the build products
#
# build, run and device take --release to build the Release configuration.
#
# Environment: MACALLA_SIMULATOR picks a simulator by name (default: the first
# available iPhone on an iOS 27 or later runtime); MACALLA_DEVICE picks a device.
# The UI test result bundle lands in build/ios/UITests.xcresult.
# SPDX-License-Identifier: MIT
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
derived="$root/build/ios"
bundle_id_default="org.macalla.app"
configuration=Debug

fail() { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }
[[ "$(uname -s)" == "Darwin" ]] || fail "the app builds on macOS with Xcode only"

pretty() { if command -v xcbeautify >/dev/null; then xcbeautify; else cat; fi; }

generate() {
  ensure_cruth
  command -v xcodegen >/dev/null || fail "xcodegen is missing: brew install xcodegen"
  (cd "$root" && xcodegen generate --quiet)
}

simulator_id() {
  # Only iOS 27+ runtimes qualify: the deployment target is iOS 27 (PRD D2).
  local line
  line="$(xcrun simctl list devices available | awk -v want="${MACALLA_SIMULATOR:-}" '
    /^-- iOS / { split($3, v, "."); ok = (v[1] + 0 >= 27); next }
    /^-- /     { ok = 0; next }
    ok && ((want == "" && $1 == "iPhone") || (want != "" && index($0, "    " want " (") == 1)) { print; exit }')"
  [[ -n "$line" ]] || fail "no iOS 27 simulator found. Install the runtime: xcodebuild -downloadPlatform iOS"
  sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/' <<<"$line"
}

bundle_id() {
  local id=""
  [[ -f "$root/Signing.local.xcconfig" ]] && id="$(sed -nE 's/^ *MACALLA_BUNDLE_ID *= *([^ ]+).*/\1/p' "$root/Signing.local.xcconfig" | tail -1)"
  echo "${id:-$bundle_id_default}"
}

xcb() {
  xcodebuild -project "$root/Macalla.xcodeproj" -scheme Macalla -derivedDataPath "$derived" "$@" | pretty
}

# (Re)build CruthCore.xcframework when it is missing or was built from another Cruth commit than the pin.
ensure_cruth() {
  local stamp="$root/Packages/CruthKit/CruthCore.xcframework/cruth-commit"
  if [[ "$(cat "$stamp" 2>/dev/null)" != "$(tr -d '[:space:]' < "$root/spec/cruth-commit")" ]]; then
    "$root/scripts/build-cruth.sh"
  fi
}

unit() {
  ensure_cruth
  (cd "$root/Packages/MacallaKit" && swift test)
  (cd "$root/Packages/CruthKit" && swift test)
}

build_sim() {
  generate >&2
  local id; id="$(simulator_id)"
  xcb -configuration "$configuration" -destination "id=$id" CODE_SIGNING_ALLOWED=NO build >&2
  echo "$id"
}

command="${1:-help}"
app_args=()
if [[ "$command" == build || "$command" == run || "$command" == device ]]; then
  shift
  while (( $# )); do
    case "$1" in
      --release) configuration=Release ;;
      --) [[ "$command" == device ]] || fail "only device passes arguments to the app"; shift; app_args=("$@"); break ;;
      *) fail "unknown option for $command: $1" ;;
    esac
    shift
  done
fi

case "$command" in
  generate) generate; echo "generated $root/Macalla.xcodeproj" ;;
  build) build_sim >/dev/null ;;
  run)
    id="$(build_sim)"
    app="$derived/Build/Products/$configuration-iphonesimulator/Macalla.app"
    # Installing into a simulator that is still booting silently loses the app.
    xcrun simctl bootstatus "$id" -b >/dev/null
    open -a Simulator --args -CurrentDeviceUDID "$id"
    xcrun simctl install "$id" "$app"
    echo "launching $(bundle_id) (Ctrl-C stops log streaming; the app keeps running)"
    xcrun simctl launch --console-pty "$id" "$(bundle_id)"
    ;;
  unit) unit ;;
  test)
    shift
    unit
    generate
    id="$(simulator_id)"
    xcrun simctl bootstatus "$id" -b >/dev/null
    rm -rf "$derived/UITests.xcresult"
    xcb -configuration Debug -destination "id=$id" -resultBundlePath "$derived/UITests.xcresult" \
      CODE_SIGNING_ALLOWED=NO test ${1+"$@"}
    ;;
  device)
    generate
    device="${MACALLA_DEVICE:-}"
    if [[ -z "$device" ]]; then
      device="$(xcrun devicectl list devices 2>/dev/null | grep -Ei 'iphone|ipad' | grep -v simulated | grep -v unavailable \
        | grep -oE '[0-9A-Fa-f-]{20,40} \(UDID\)' | head -1 | cut -d' ' -f1 || true)"
    fi
    [[ -n "$device" ]] || fail "no device found. Connect it, unlock it, trust this Mac and enable Developer Mode, or set MACALLA_DEVICE"
    # Build for this device, not a generic one, so Xcode registers it in the provisioning profile.
    xcb -configuration "$configuration" -destination "id=$device" \
      -allowProvisioningUpdates -allowProvisioningDeviceRegistration build
    app="$derived/Build/Products/$configuration-iphoneos/Macalla.app"
    xcrun devicectl device install app --device "$device" "$app"
    # --console streams the app's stdout here (spike results print there); Ctrl-C detaches.
    # App arguments go after --, or devicectl reads flags like -autoMeasure as its own options.
    launch=(xcrun devicectl device process launch --console --terminate-existing --device "$device" "$(bundle_id)")
    (( ${#app_args[@]} )) && launch+=(-- "${app_args[@]}")
    "${launch[@]}"
    ;;
  open) generate; open "$root/Macalla.xcodeproj" ;;
  clean) rm -rf "$derived"; echo "removed $derived" ;;
  *) sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
esac
