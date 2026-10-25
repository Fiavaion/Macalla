# ADR 0003: RealityKit for splat rendering

- Status: **proposed — pending M0 spike "RealityKit splats"**
- Date: 2026-10-25
- PRD: D2, F1

## Context

iOS 27 RealityKit can render Gaussian splats natively, which is part of why iOS 27 is the minimum OS (D2). The alternative is our own Metal splat renderer.

## Decision

Render splats with RealityKit, alongside the mesh, in AR and in the orbit viewer.

## Decision rule (pre-registered before measuring; thresholds confirmed by the product owner 2026-10-25)

Spike: load a 500K-splat PLY into RealityKit on iPhone 13 and iPhone 16 Pro, in AR with the camera feed.

- **Go** if it holds 30 fps or better on iPhone 13 and 60 fps on iPhone 16 Pro, sustained for 60 s.
- **No-go**: write a Metal splat renderer (new ADR), and decide whether D2's iOS 27 minimum still earns its place.

## Consequences

Go means no custom renderer. No-go adds an M1/M3 rendering workstream.

## Findings so far (2026-10-25, before measurement)

- The API exists on iOS 27.1: `GaussianSplatComponent(GaussianSplatResource(BufferResource(...)))`, fed from `LowLevelBuffer`s, with scale and opacity activations and a `GaussianSplatEvents.RenderingChanged` event that reports when RealityKit lowers splat quality. There is no file loader; `SplatPLY` in MacallaKit reads trainer PLYs.
- **The simulator SDK has no splat API at all**, so this can only be measured, and only ever tested, on a device.
- Unverified until seen on a device: quaternion order (we pass x, y, z, w) and whether the degree-0 coefficients are interpreted as 3DGS SH (we pass them unchanged). A wrong guess shows as mis-rotated or mis-coloured splats on the synthetic sphere, which is coloured by direction.
- Spike screen: `App/Sources/Spikes/SplatSpikeView.swift`. Run with `./scripts/ios.sh device -- -spike splats` (a Debug build: spikes are compiled out of Release; RealityKit renders at full speed either way), tap "Measure 60 s"; the result line prints in the terminal. `-splatCount N` changes the synthetic count; a `spike.ply` copied into the app's Documents replaces the synthetic sphere.

## Measurements (2026-10-25, iPad Pro 12.9" M1, iPadOS 27, Debug build, camera-anchored at 0.5 m so the cloud is always in view)

Not a reference device; extra data before the iPhone 13 and iPhone 16 Pro runs. Each run shows a 2 cm opaque marker cube at the cloud's centre so an empty render can't pass as a fast one.

| Cloud | Splats | Visible | Mean fps | Worst second |
| --- | --- | --- | --- | --- |
| Synthetic sphere, 8 mm splats | 2,000 | yes | 59.9 | 58.0 |
| Synthetic sphere, 2 mm splats | 100,000 | yes | ≈51 (live) | n/a |
| Synthetic sphere, 2 mm splats | 250,000 | yes | ≈33 (live) | n/a |
| Synthetic sphere, 2 mm, two pieces of 250,000 | 500,000 | yes | 19.8 / 15.7 (two runs) | 9.5 / 15.0 |
| **Trained scan (`panther`), SH degree 3, two pieces** | **420,979** | **yes** | **33.7** | **18.0** |

Findings that change the design:

1. **One splat resource draws at most 262,144 (2^18) splats.** 262,144 renders; 300,000 and 500,000 load without error, report "rendering normal" and full frame cost, and draw nothing. Clouds must be split across entities of ≤ 262,144 splats (`SplatCloud.chunks`); 500,000 in two pieces renders.
2. **Buffer capacities must be a multiple of 16 bytes**, or `BufferResource` throws `invalid(bufferCapacity:)` (262,145 splats × 12 bytes). Fixed by padding.
3. **Sub-pixel splats are dropped**: 500,000 synthetic 0.5 mm splats drew nothing at 59 fps. Our first "result" was this empty render.
4. Quaternion order (x, y, z, w) and degree-0/degree-3 SH colour are right: the direction-coloured sphere and the trained scan render with correct colour and shape.

Leaning (not a decision; reference devices pending): a full-screen ~420K-splat scan does not hold 30 fps every second even on an M1, so the iPhone 13 bar is unlikely to be met at that budget. Likely outcome: RealityKit stays, with a per-device splat budget (or LOD) and chunking, rather than a custom Metal renderer. The iPhone 13 and iPhone 16 Pro runs decide it.
