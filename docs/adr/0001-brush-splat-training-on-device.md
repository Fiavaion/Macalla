# ADR 0001: Brush for splat training on device and Mac

- Status: **proposed — pending M0 spike "Brush on iOS"**
- Date: 2026-10-25
- PRD: D9, P3

## Context

Splats must be trained from the same capture as the mesh (Goal 4). Inria's 3DGS code is research-only, so it can't ship in the app (D6). Brush is Apache 2.0, written in Rust on wgpu, and runs on Metal.

## Decision

Use Brush for splat training on device and on the Mac companion; use gsplat on the self-hosted server.

## Decision rule (pre-registered before measuring; thresholds confirmed by the product owner 2026-10-25)

Spike: build Brush for iOS on Metal and train a 300-shot golden capture with ARKit poses as priors.

- **Go** if it builds without patches that change its licence, trains on iPhone 16 Pro and iPad Pro M4 without being killed for memory, and a 7,000-iteration run finishes in under 15 minutes on iPad Pro M4.
- **No-go** otherwise: splats are offered on Mac and server only, and P3's on-device option is hidden (PRD M3).

Record iterations per second on both devices and peak memory in the spike report, whatever the outcome.

## Consequences

Go adds a Rust toolchain and an XCFramework build step for Brush. No-go means on-device users get a mesh only.

## Findings so far (2026-10-25, before measurement)

Details and commands: [spikes/brush/README.md](../../spikes/brush/README.md).

- Brush (pinned `1388f74c`) builds for `aarch64-apple-ios` and `aarch64-apple-ios-sim` with **no Brush source patched**: a no-op `rfd` stub (no iOS file-dialog backend) and our own FFI crate that selects Metal explicitly (cubecl only maps macOS to Metal). Both are one-line upstream fixes worth offering.
- It trains through our C entry point on Mac Metal. The **iOS simulator cannot train** (no indirect dispatch), so measurement is device-only.
- Licences: Apache-2.0; 600 crates, no GPL/AGPL/non-commercial. Four transitive crates are MPL-2.0 (`buildid`, `colored`, `indent`, `option-ext`), which D6 already allows (file-level copyleft).
- **Open, must resolve before a go:** Brush always pulls in `rerun`, which links an analytics crate (`re_analytics`) and auth code into the binary. That conflicts with P11 even if never called, and inflates the runner executable to 140 MB. A go requires making `brush-rerun` optional (upstream or in our fork of the dependency graph).
- The decision rule's threshold is ≈ 7.8 iterations/s on iPad Pro M4 (7,000 in 15 minutes).
- Upstream (2026-10-25): the iOS build fixes were already offered by another contributor on [brush#27](https://github.com/ArthurBrussee/brush/issues/27) (iPhone 17 Pro, NeRF-synthetic lego: 13.6 it/s, 10,000 steps in 735 s, 3.1 GB peak); we confirmed them there rather than duplicating. Opened [brush#561](https://github.com/ArthurBrussee/brush/pull/561) (rerun optional; iOS dependency tree 583 → 352 crates, no `re_*`) and [cubecl#1930](https://github.com/tracel-ai/cubecl/pull/1930) (Metal for `Auto` on every Apple OS).
- Benchmark dataset: NeRF-synthetic lego, 100 images at 800×800, in `../Macalla-data/nerf_synthetic_lego` (CC-BY-NC model: local benchmarking only, never committed). Mac baseline, Apple M5 Pro: 2,000 iterations in 24 s wall, ≈ 85 it/s at the end.
