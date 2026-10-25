# Current status

Updated 2026-10-25 (end of M0 desk work; everything left in M0 needs hardware or a decision).

## What works

- App: iOS/iPadOS 27 SwiftUI shell (`project.yml`, XcodeGen), placeholder projects screen, Debug-only spike screens for ADR 0002 and 0003 (`App/Sources/Spikes/`), openable at launch with `-spike splats|photogrammetry`.
- `Packages/MacallaKit`: project bundle schema v1 (`ProjectManifest`, `CaptureSession`, `Shot`, `Coverage`, `DerivedSpec`, `ProcessingJob`, `ProjectBundle.validate()`), sample bundle `Tests/MacallaKitTests/Fixtures/Teapot.macalla`, 3DGS PLY reader/writer (`SplatPLY`) and a synthetic benchmark cloud. Hardened against hostile input after review.
- `Packages/CruthKit`: Swift wrapper over Cruth's C API; `CruthCore.xcframework` (iOS, simulator, macOS) built by `scripts/build-cruth.sh` from the Cruth commit pinned in `spec/cruth-commit`. Decimation to an exact budget verified on the Mac and in the simulator.
- Licence guard `scripts/check-licences.sh` (allow-list, declared packages, licence markers, SPDX headers), `spec/dependencies.md`, `CONTRIBUTING.md`, CI workflow `.github/workflows/ci.yml` (not yet run, see blockers).
- `spikes/brush/`: Brush builds for iOS device and simulator unpatched; trains on Mac Metal; device runner ready (`run-device.sh`).
- Tests: Mac `swift test` (MacallaKit, CruthKit) and the simulator scheme (package tests + 2 UI tests) pass.
- Device signing: `Signing.local.xcconfig` (git-ignored) uses the same team as Cruth.

## What's broken or missing

- CI runs on GitHub (public repo, so Actions billing is not an issue). Licence guard passes; the unit and app jobs fail at cloning Cruth, which is private: needs a `CRUTH_TOKEN` secret or a public Cruth.
- No spike has been measured: all three need devices (simulators lack splat rendering, Brush's indirect dispatch, and photogrammetry support).
- Brush links `rerun`/`re_analytics`: a P11 privacy problem to fix before ADR 0001 can be a go.
- The pinned Cruth commit lives on branch `claude/lucid-franklin-mrpthk`, not `main`; re-pin after that branch merges.

## Next 3 tasks

1. Unblock CI (Cruth access), then confirm the first green run.
2. Device spikes: splat rendering and photogrammetry on whatever devices are available (iPad Pro M1 now; reference devices later), Brush on iPhone 16 Pro / iPad Pro M4 with a posed dataset.
3. Record results in ADRs 0001–0003 and decide go/no-go; then delete the spike screens and start M1 (capture core).

## Blockers

- Reference devices: iPhone 13, iPhone 16 Pro, iPad Pro M4 (only an iPad Pro M1 is known to be available).
- A posed dataset for Brush (COLMAP or Nerfstudio folder) until M1 capture exists.
- User confirmation of the ADR decision thresholds.
