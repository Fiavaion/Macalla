# ADR 0003: RealityKit for splat rendering

- Status: **proposed — pending M0 spike "RealityKit splats"**
- Date: 2026-10-25
- PRD: D2, F1

## Context

iOS 27 RealityKit can render Gaussian splats natively, which is part of why iOS 27 is the minimum OS (D2). The alternative is our own Metal splat renderer.

## Decision

Render splats with RealityKit, alongside the mesh, in AR and in the orbit viewer.

## Decision rule (pre-registered before measuring)

Spike: load a 500K-splat PLY into RealityKit on iPhone 13 and iPhone 16 Pro, in AR with the camera feed.

- **Go** if it holds 30 fps or better on iPhone 13 and 60 fps on iPhone 16 Pro, sustained for 60 s.
- **No-go**: write a Metal splat renderer (new ADR), and decide whether D2's iOS 27 minimum still earns its place.

## Consequences

Go means no custom renderer. No-go adds an M1/M3 rendering workstream.
