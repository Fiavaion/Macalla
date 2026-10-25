# ADR 0001: Brush for splat training on device and Mac

- Status: **proposed — pending M0 spike "Brush on iOS"**
- Date: 2026-10-25
- PRD: D9, P3

## Context

Splats must be trained from the same capture as the mesh (Goal 4). Inria's 3DGS code is research-only, so it can't ship in the app (D6). Brush is Apache 2.0, written in Rust on wgpu, and runs on Metal.

## Decision

Use Brush for splat training on device and on the Mac companion; use gsplat on the self-hosted server.

## Decision rule (pre-registered before measuring)

Spike: build Brush for iOS on Metal and train a 300-shot golden capture with ARKit poses as priors.

- **Go** if it builds without patches that change its licence, trains on iPhone 16 Pro and iPad Pro M4 without being killed for memory, and a 7,000-iteration run finishes in under 15 minutes on iPad Pro M4.
- **No-go** otherwise: splats are offered on Mac and server only, and P3's on-device option is hidden (PRD M3).

Record iterations per second on both devices and peak memory in the spike report, whatever the outcome.

## Consequences

Go adds a Rust toolchain and an XCFramework build step for Brush. No-go means on-device users get a mesh only.
