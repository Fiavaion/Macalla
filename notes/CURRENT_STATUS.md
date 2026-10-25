# Current status

Updated 2026-10-25, session end: M0 desk work finished; first device spike measured on an iPad Pro M1.

## Phase

M0 · Foundations and spikes. Every M0 box that can be done without reference hardware is done. Remaining: the three spikes on reference devices (iPhone 13, iPhone 16 Pro, iPad Pro M4) and their go/no-go decisions. ADR thresholds are confirmed by the product owner.

## Build and test (run this session on `5e4c535`)

- `./scripts/ios.sh test`: Mac `swift test` 24/24 MacallaKit, 4/4 CruthKit; simulator (iOS 27, iPhone) 30/30 (package tests + 2 UI tests).
- `bash scripts/check-licences.sh`: OK.
- GitHub CI on `5e4c535`: success (licence guard, package tests, app build + UI tests on the `xcode-27` runner).

## What works

- App shell (iOS/iPadOS 27, SwiftUI, Swift 6) with Debug-only spike screens: `-spike splats [-splatCount N] [-splatChunk N] [-autoMeasure YES]`, `-spike photogrammetry`.
- MacallaKit: bundle schema v1 + validator + sample bundle; `SplatPLY` reader/writer; `SplatCloud` (benchmark sphere, `chunks`, `fitted(toSize:)`).
- CruthKit + `scripts/build-cruth.sh` (Cruth pinned in `spec/cruth-commit`; Cruth is public).
- Device loop: `./scripts/ios.sh device -- <app args>`; signing via git-ignored `Signing.local.xcconfig` (bundle id `com.fiavaion.macalla`).
- Brush builds for iOS (`spikes/brush`), trains on Mac Metal (M5 Pro: lego 2,000 iterations in 24 s).

## Spike results so far

- **ADR 0003 (RealityKit splats)**, iPad Pro M1 (not a reference device): trained 420,979-splat scan 33.7 fps mean, 18.0 worst second; RealityKit draws ≤ 262,144 splats per resource, so clouds are chunked. Leaning: RealityKit + chunking + per-device splat budget. Table in the ADR.
- ADR 0001, 0002: not measured.

## What's broken or missing

- Brush on NeRF-synthetic lego ends at ~5,500 splats (also with brush-cli), so lego can't be the Brush benchmark (LESSON-TEST-001). Needs a real-photo capture.
- Brush links `rerun`/`re_analytics` (P11): fix proposed upstream in brush#561, not merged.
- Not defects, deliberate: spike screens and their Info.plist file-sharing keys exist only in Debug; benchmark data lives outside the repo in `../Macalla-data` (lego CC-BY-NC, panther no stated licence: local benchmarking only).

## Next 3 tasks

1. iPhone 13 (and an iPhone 16 Pro if available): splat spike with `spike.ply` = `../Macalla-data/panther.ply`, `-splatChunk 250000 -autoMeasure YES`; decide ADR 0003.
2. Real-photo capture of a small object (60–100 photos): photogrammetry spike on device (ADR 0002), then COLMAP poses → Brush device run (ADR 0001).
3. Record results, decide go/no-go for all three ADRs, delete the spike screens, start M1 (capture core).

## Blockers

- Reference devices: iPhone 13 is paired but was unavailable; no iPhone 16 Pro or iPad Pro M4 known.
- A real-photo capture from the user.
- Upstream review of brush#561 (or a decision to build from our fork).

## Touched this session

- ADRs: [0001](../docs/adr/0001-brush-splat-training-on-device.md), [0002](../docs/adr/0002-apple-photogrammetry-on-device.md), [0003](../docs/adr/0003-realitykit-splat-rendering.md)
- Upstream: [cubecl#1930](https://github.com/tracel-ai/cubecl/pull/1930), [brush#561](https://github.com/ArthurBrussee/brush/pull/561), [brush#27 comment](https://github.com/ArthurBrussee/brush/issues/27#issuecomment-6402071646)
- [spikes/brush/README.md](../spikes/brush/README.md), [spec/dependencies.md](../spec/dependencies.md), [lessons](lessons.md)
