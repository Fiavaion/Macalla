# Lessons ledger

Tag the insight inline at the point it happens (`LESSON-BUILD-001: …`), then add the fuller entry here. The global `/lessons` folds inline tags into this file.

## BUILD

- **LESSON-BUILD-001** (2026-10-25): Xcode 27.1 ships without the iOS 27 simulator runtime; only 26.5 was installed. With an iOS 27 deployment target nothing runs in the simulator until `xcodebuild -downloadPlatform iOS` has run. `scripts/ios.sh` refuses older runtimes with that hint.
- **LESSON-BUILD-002** (2026-10-25): The iOS 27.1 *simulator* SDK has no Gaussian splat API (`GaussianSplatComponent` is device-SDK only), while `PhotogrammetrySession` is declared in both but unsupported in the simulator. Check both SDK swiftinterfaces before assuming a RealityKit feature can be simulator-tested.
- **LESSON-BUILD-003** (2026-10-25): Fiavaion/Cruth is a private repo, so Macalla's public CI and outside contributors can't fetch the geometry core without a token. CI reads an optional `CRUTH_TOKEN` secret.

## API

- **LESSON-API-001** (2026-10-25): Swift's synthesised `Codable` for enums with associated values writes `{"faces":{"_0":5000}}`. Bundle files are read by non-Swift tiers, so bundle enums with payloads get hand-written single-value coding (`DerivedSpec.Budget`).
