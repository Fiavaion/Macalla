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
