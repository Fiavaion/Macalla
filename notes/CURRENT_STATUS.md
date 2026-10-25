# Current status

Updated 2026-10-25 (project bootstrap).

## What works

- XcodeGen project (`project.yml`): `Macalla` app (iOS/iPadOS 27, SwiftUI, Swift 6) with a placeholder "No scans yet" screen, plus `MacallaUITests`.
- `Packages/MacallaKit`: `ProjectManifest` (bundle `manifest.json` v1: encode, decode, version check), 3 Swift Testing tests passing headless.
- `scripts/ios.sh` generate / build / run / unit / test / device.
- Public repo: github.com/Fiavaion/Macalla (main pushed 2026-10-25).

## What's broken or missing

- No CI and no licence allow-list check yet (M0).
- Cruth core is not yet built as an XCFramework (M0).

## Next 3 tasks (M0)

1. CI: build the app, `swift test`, licence allow-list guard (D6).
2. Cruth core as an XCFramework with a thin Swift wrapper; decimate a test mesh on device.
3. Run the three spikes in `docs/adr/0001`–`0003` and record go/no-go against their pre-registered rules.

## Blockers

- Spikes need the reference devices: iPhone 13, iPhone 16 Pro, iPad Pro M4.
