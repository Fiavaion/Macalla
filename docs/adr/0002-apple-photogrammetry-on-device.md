# ADR 0002: Apple PhotogrammetrySession for on-device and Mac meshes

- Status: **proposed — pending M0 spike "PhotogrammetrySession"**
- Date: 2026-10-25
- PRD: D8, P2; open question "Does Apple's reduced-detail iOS mesh meet the quality bar?"

## Context

The success metric needs a usable textured mesh, offline, on a recent iPhone. Apple's `PhotogrammetrySession` runs on device (reduced detail) and on the Mac (up to raw). Writing our own MVS on device is a large cost.

## Decision

Use `PhotogrammetrySession` on device and Mac, fed with our own stills and ARKit poses (D3, D12). COLMAP/GLOMAP + OpenMVS stay server-only.

## Decision rule (pre-registered before measuring; thresholds confirmed by the product owner 2026-10-25)

Spike: run the same three golden-set captures on iPhone 13, iPhone 16 Pro and iPad Pro M4.

- **Go** if it runs on iPhone 16 Pro and iPad Pro M4, finishes each capture in under 6 minutes there (leaving time for capture inside the 10-minute success metric), and produces a closed, textured mesh judged usable for 2 of 3 objects.
- **Partial** if it runs only on some reference devices: ship it there, with a clear message elsewhere (P2).
- **No-go** if output fails the quality bar on every device: M3 needs its own on-device MVS, and the MVP date moves.

## Consequences

Go keeps M3 small. Partial or no-go triggers a new ADR before M3 starts.

## Findings so far (2026-10-25, before measurement)

- On iOS 27.1 `PhotogrammetrySession.Request.Detail` has only `.reduced`; medium, full and raw are Mac-only, as the PRD assumed.
- Spike screen: `App/Sources/Spikes/PhotogrammetrySpikeView.swift`. Copy a capture's photos into the app's `Documents/spike-images` (Finder or Files), run `./scripts/ios.sh device -- -spike photogrammetry` (a Debug build; the reconstruction itself runs in Apple's optimised framework), tap Reconstruct. Time, USDZ size and thermal state print in the terminal; open `spike-output.usdz` in Files to judge quality.
