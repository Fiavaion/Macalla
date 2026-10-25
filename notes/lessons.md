# Lessons ledger

Tag the insight inline at the point it happens (`LESSON-BUILD-001: …`), then add the fuller entry here. The global `/lessons` folds inline tags into this file.

## BUILD

- **LESSON-BUILD-001** (2026-10-25): Xcode 27.1 ships without the iOS 27 simulator runtime; only 26.5 was installed. With an iOS 27 deployment target nothing runs in the simulator until `xcodebuild -downloadPlatform iOS` has run. `scripts/ios.sh` refuses older runtimes with that hint.
- **LESSON-BUILD-002** (2026-10-25): The iOS 27.1 *simulator* SDK has no Gaussian splat API (`GaussianSplatComponent` is device-SDK only), while `PhotogrammetrySession` is declared in both but unsupported in the simulator. Check both SDK swiftinterfaces before assuming a RealityKit feature can be simulator-tested.
- **LESSON-BUILD-003** (2026-10-25): Macalla's CI and outside contributors need to fetch Cruth. It was private, so CI failed at the clone; Cruth was made public the same day. CI still reads an optional `CRUTH_TOKEN` secret if that ever changes.
- **LESSON-BUILD-004** (2026-10-25): GitHub's `macos-26` image stops at Xcode 26.6; iOS 27 needs the `xcode-27` image (public preview). The Xcode-select step must fail when Xcode 27 is missing: a silent fallback to 26.6 hid this behind a passing unit job. Don't pipe `xcodebuild -version` into `grep -q` (broken-pipe crash).

## API

- **LESSON-API-001** (2026-10-25): Swift's synthesised `Codable` for enums with associated values writes `{"faces":{"_0":5000}}`. Bundle files are read by non-Swift tiers, so bundle enums with payloads get hand-written single-value coding (`DerivedSpec.Budget`).
- **LESSON-API-002** (2026-10-25): RealityKit silently drops sub-pixel Gaussian splats. A synthetic 500K-splat shell with 0.5 mm splats rendered nothing on an iPad Pro M1 while reporting 59 fps and "rendering normal". A 2 cm opaque marker cube at the splat centre exposed it. Every splat benchmark needs a visible check that splats were drawn, not just a frame rate.
- **LESSON-API-003** (2026-10-25): RealityKit (iOS 27.1) draws at most 262,144 splats per `GaussianSplatResource`; above that it loads, reports normal rendering and draws nothing. Split clouds into ≤ 262,144-splat entities. `LowLevelBuffer` capacities must be a multiple of 16 bytes.
- **LESSON-TEST-001** (2026-10-25): Brush on NeRF-synthetic lego with default settings ends at ~5,500 splats (both our FFI and brush-cli, alpha mode masked or transparent), far from the ~477K reported upstream. Don't use lego as the Brush benchmark until that is understood; use a real-photo capture.
