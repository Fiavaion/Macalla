# Macalla — PRD

Oct 25, 2026 · @Mark Jones

## Overview

A free, open-source iPhone and iPad app that turns a walk around an object into a textured mesh at the polycount you choose, plus a Gaussian splat of the same capture. It auto-captures stills, leaves each photo in AR where it was taken, shows live coverage, and processes on the device by default with optional offload to your own Mac or GPU server.

- **Name:** Macalla (Irish: echo), for the photos it leaves in space. Chosen 2026-10-25 over the earlier working name Lorg.
- **Publisher:** Mark's company; MIT licence with DCO; public GitHub; App Store release.
- **Family:** a capture front end to Cruth. Both apps share one C++ geometry core for decimation, remeshing, retopology, UVs, baking and print checks; scans can feed Cuardach as AR assets and tracking targets.
- **Evidence:** competitors, APIs, methods and licences are in [RESEARCH.md](RESEARCH.md).

## Goals and non-goals

The app wins on capture quality and output control, not on owning a cloud.

**Goals**

1. A first-time user gets a usable textured mesh of a 10 to 50 cm object in under 10 minutes, start to finish, on a recent iPhone, offline.
2. Every kept photo is visible, inspectable and replaceable in AR at the place it was taken.
3. The user sets an exact output budget (faces or quads) and topology style, and can change it without re-running reconstruction.
4. One capture yields both a mesh and a splat, aligned in the same coordinate frame.
5. Processing location is the user's choice: device, own Mac, or own server. No vendor cloud and no training on user scans.
6. Fully open source under MIT; no copyleft or research-only code in the App Store binary.

**Non-goals for V1**

- Room-scale or building-scale scanning (object and small-scene only).
- Android, web and Vision Pro clients (the USD outputs work there; the app does not).
- A hosted cloud service or accounts.
- Generating 3D from a single image or text.
- Full sculpting and texture painting (that is Cruth's job; the app hands off).

## Users and core use cases

The primary user is an art, design or games student or hobbyist with an iPhone and no photogrammetry training; the secondary user is a technical artist who wants control over topology and processing.

| User | Use case | What they need from the app |
| --- | --- | --- |
| Design student | Scan a prototype or found object for a portfolio render | Guided capture, good default mesh, USDZ for AR Quick Look |
| Games student | Turn a prop into a game asset | Exact face budget, quad or tri topology, normal map bake, LODs, glTF/FBX |
| Maker | Scan a part to reprint or modify | True scale, watertight solid, print checks |
| Technical artist | Hero asset with clean topology | Flow-guided quad retopo, server processing, raw dense mesh export |
| Fine-art and media practitioner | Splat of a sculpture or textile for a moving-image or real-time piece | Splat output, PLY export, mesh proxy for lighting or collision |
| Educator or lab manager | Students process without an expensive cloud plan | A self-hosted server the whole class can share |

## Binding design decisions

These are fixed for V1 unless a milestone spike proves one unworkable; change them only by editing this table.

| # | Decision | Choice | Rationale |
| --- | --- | --- | --- |
| D1 | App stack | Native Swift and SwiftUI; ARKit, RealityKit, AVFoundation, Metal | Lowest-latency AR and camera access; no cross-platform penalty |
| D2 | Minimum OS | iOS and iPadOS 27 | Native RealityKit splat rendering and ARKit object tracking on iOS; every iOS 26 device can run 27 |
| D3 | Capture pipeline | Own ARKit + high-resolution stills, not `ObjectCaptureView` | Needed for custom auto-shutter, gates and photo ghosts; works without LiDAR |
| D4 | Geometry engine | Cruth's shared C++ core, shipped as an XCFramework with a thin Swift wrapper | One remesh, retopo, UV and bake implementation across both apps |
| D5 | Licence | MIT with DCO, same as Cruth | Permissive; App Store safe |
| D6 | Dependency rule | No GPL, AGPL or non-commercial code in the app binary; enforced by a CI allow-list | GPL conflicts with App Store terms; Inria 3DGS code is research-only |
| D7 | Processing | Hybrid: device default, then own Mac, then own server; no vendor cloud | Privacy, zero running cost, institutional use |
| D8 | Mesh backends | Apple `PhotogrammetrySession` on device and Mac; COLMAP/GLOMAP + OpenMVS on server | Best available per tier; AGPL only on server |
| D9 | Splat backend | Brush (Apache 2.0) on device and Mac if the M0 spike passes; gsplat on server | Portable, permissive, proven trainer |
| D10 | Canonical format | USD for project outputs (mesh, splat reference, LODs, metadata) | Matches Cruth; opens in Apple, Blender, Unreal, Houdini |
| D11 | Polycount model | Reconstruct dense once; derive budgets as cheap, re-runnable outputs | Changing the target must not repeat reconstruction |
| D12 | Pose source | ARKit world-tracking poses stored per shot and passed as priors to every backend | Faster, metric, more robust reconstruction; makes ghosts exact |

## Capture experience requirements

The shutter fires on new viewpoint, not on time; every frame must pass quality gates before it is kept; and every kept shot stays in the scene as a photo ghost that feeds coverage and next-best-view guidance.

&#91;embedded content: capture loop · 2 checks per frame, every kept shot becomes a ghost\]

| ID | Requirement | Acceptance | Priority |
| --- | --- | --- | --- |
| C1 | Bounding box: detect the subject on a surface from ARKit planes and a tap; user can resize and rotate it | Box placed in under 10 s for a typical tabletop object | MVP |
| C2 | Auto-shutter on viewpoint novelty: fire when the view direction is at least θ from every kept shot (default 8°, set by preset) | No two kept shots in one pass closer than θ/2 | MVP |
| C3 | Quality gates: gyro rate, sharpness against the session's running median, highlight clipping over the mask, focus settled, subject fully in frame | 95% or more of kept shots pass manual review on the golden set | MVP |
| C4 | Exposure and white balance locked per pass; Pro panel for focus, ISO, shutter, white balance and torch | Lock survives the whole pass | MVP |
| C5 | Manual shutter and auto-shutter pause toggle | One tap each | MVP |
| C6 | Photo ghosts: each kept shot drawn as its frustum with a 256 px thumbnail at its pose; fades with distance and while moving; full strength when the user is still | 30 fps or better with 200 ghosts on iPhone 13 | MVP |
| C7 | Ghost inspection: tap for the full photo, scores and mask; delete; retake with an overlay showing pose error | Retake reported aligned within 2° and 3 cm | MVP |
| C8 | View-sphere coverage: geodesic dome (default 162 cells) around the box, showing per-cell shot count and quality, in AR and as a 2D minimap | Dome updates within one frame of a kept shot | MVP |
| C9 | Surface coverage heat map on the LiDAR mesh or feature points: views per vertex below 60° grazing, in a colour-blind-safe palette | Matches an offline recount within 5% | MVP |
| C10 | Next-best-view: arrow and target ring to the nearest weak cell, with haptic and optional spoken cues | Following arrows alone reaches 85% cell coverage on the golden set | MVP |
| C11 | Output-aware recipes: the chosen preset sets θ, minimum views per vertex and required elevation bands | Each preset documented with its parameters | MVP |
| C12 | Multi-pass and flip: start a new pass after flipping the object; passes merge using masks | Base and top merge without manual alignment on 8 of 10 golden objects | MVP |
| C13 | Coverage target and progress: show percent complete; suggest stopping at target; never stop without confirmation | Progress shown at all times | MVP |
| C14 | Rejected frames logged with reason and turned into short on-screen hints | Hint shown within 300 ms of a rejection streak | MVP |

## Processing requirements

A job router sends each processing job to the best tier the user allows, and every tier reads and writes the same project bundle; the tiered architecture is drawn in the research doc.

| ID | Requirement | Priority |
| --- | --- | --- |
| P1 | Instant preview within 15 s of ending capture: LiDAR mesh or feature-point cloud textured from thumbnails, shown in AR at true scale | MVP |
| P2 | On-device dense mesh via Apple `PhotogrammetrySession` where the device supports it, with a run-time capability check and a clear message where it does not | MVP |
| P3 | On-device splat training via Brush when the M0 spike passes; otherwise splats are offered only on Mac and server | MVP (conditional) |
| P4 | Automatic subject masking from the AR bounding box plus a segmentation model; masks editable in the photo viewer | MVP |
| P5 | Mac companion app: discovered on the local network, pairs with a one-time code, runs Apple medium/full/raw detail, Brush splats and large quad remeshes | V1 |
| P6 | Self-hosted server: Docker image with COLMAP/GLOMAP, OpenMVS, gsplat and a mesh-from-splat method; exposes a small HTTPS job API; ARKit poses used as priors | V1 |
| P7 | Job router policy: user sets allowed tiers per project; router picks by device support, job size and tier availability; falls back down the list on failure | V1 |
| P8 | Resumable chunked upload and download; jobs idempotent by bundle hash and job spec | V1 |
| P9 | Background processing continues when the app is backgrounded, within iOS limits, with a notification on completion | MVP |
| P10 | Server tier optional learned passes: MapAnything preview, PBR de-lighting, artist-style remesh | Later |
| P11 | No telemetry on scan content; crash reports opt-in; no data leaves the device unless the user sends a job to a tier they added | MVP |

## Output requirements

The user picks a budget and a topology style before or after capture; the app derives that output from the dense reconstruction in seconds and can re-derive it any number of times.

**Budget and style picker**

- Presets: 1K, 5K, 20K, 100K faces, plus Dense (no reduction) and a typed custom number.
- Use-case presets that set budget, style, maps and format together: AR / web (5K tris, USDZ + GLB), Game prop (budget of choice, quads, normal + AO maps, LOD0–3), 3D print (watertight solid, no texture, STL/3MF), Hero (dense + quad retopo + displacement).
- Topology style: Triangles, Quad-dominant, All quads.
- Preview updates live: wireframe overlay, face count, texture density, and a deviation heat map against the dense mesh.

| ID | Requirement | Acceptance | Priority |
| --- | --- | --- | --- |
| O1 | Triangle decimation to an exact face count, preserving UV seams, borders and normals | Result within ±1% of target; Hausdorff error reported | MVP |
| O2 | Quad remesh to a target quad count, quad-dominant or all-quad, with feature-edge preservation | Within ±10% of target; under 2% non-quad faces in all-quad mode | MVP |
| O3 | Isotropic remesh at a target edge length | Edge-length standard deviation under 15% of mean | V1 |
| O4 | Automatic UV unwrap and packing for any derived mesh | No overlapping charts; packing efficiency reported | MVP |
| O5 | Bake from dense mesh to derived mesh: colour, tangent-space normal, AO; displacement in V1 | Bakes at 1K, 2K, 4K; no seams visible at 1 m in the viewer | MVP |
| O6 | LOD chain sharing one atlas | User sets count and ratio | V1 |
| O7 | Quad-to-quad reduction that removes loops while keeping flow | Removes loops without introducing triangles | V1 |
| O8 | Flow-guided retopo: paint guide curves on the mesh to steer edge loops | Loops follow painted curves within one face width | V1 |
| O9 | Hole fill, small-component removal, flip-to-solid; print checks (watertight, wall thickness) from Cruth core | Print preset output passes its own checks | V1 |
| O10 | Crop, rotate, set origin and up axis, set scale from a measured distance | Applies to all derived outputs | MVP |

**Export formats**

| Format | Contents | Priority |
| --- | --- | --- |
| USDZ / USD | Mesh, materials, LODs, splat reference, capture metadata | MVP |
| glTF / GLB | Mesh, PBR materials, LODs | MVP |
| OBJ + MTL | Mesh and textures | MVP |
| PLY | Splats; point cloud; mesh | MVP |
| STL / 3MF | Print solids | V1 |
| FBX | Mesh and textures for Maya and Unity users | V1, writer licence open |
| Project bundle | Everything, for re-processing elsewhere | MVP |

## Beyond-clone features

Photo ghosts, next-best-view and output-aware capture are MVP and specified under capture; these build on them.

| ID | Feature | Behaviour | Priority |
| --- | --- | --- | --- |
| F1 | Mesh + splat asset | One USD file holds the derived mesh and the splat in the same frame; viewer toggles or blends them; optional bake of splat appearance onto the mesh texture | V1 |
| F2 | Scan as AR tracking target | Export an ARKit reference object (iOS 27) and send scan + reference object to Cuardach | V1 |
| F3 | Rig and DSLR ingest | Import a folder of external photos (e.g. the NCAD Canon rig), align them with phone shots, show them as ghosts too | V1 |
| F4 | 3D-print mode | Scale from LiDAR or a typed measurement; watertight solid; wall-thickness check and repair; STL/3MF | V1 |
| F5 | Multi-pass and flip | Capture top, flip the object, capture the base; passes merge automatically using the subject mask | MVP |
| F6 | Turntable mode | Phone on a tripod, object on a turntable; time- or Bluetooth-triggered shutter; ghosts arranged as a ring | V1 |
| F7 | Capture coach | After capture, flags the weakest shots by score and suggests specific retakes | V1 |
| F8 | De-lit PBR textures | Server pass producing albedo, roughness and normal maps | Later |
| F9 | Part segmentation | Split an object into parts before remeshing | Later |
| F10 | Revisit and diff | Re-scan, align with the earlier scan, colour the differences | Later |
| F11 | Learned artist topology | Meshtron- or QuadGPT-class remesh as a server option | Later |
| F12 | Open in Cruth | Hand off the dense or derived mesh to Cruth for sculpting and texture work | V1 |

## Data model: the project bundle

Each scan is one folder-based bundle that any tier can read, re-process and write back into; the app never stores scan data anywhere else.

```
Teapot.macalla/
  manifest.json          bundle version, device, OS, creation time, allowed tiers, target presets
  capture/
    session.json         bounding box, gravity, scale source, passes, lock settings
    shots/
      0001.heic          full-resolution still
      0001.json          pose (4x4), intrinsics, exposure, focus, scores, pass id, kept or rejected
      0001.depth.tiff    LiDAR depth where available
      0001.mask.png      subject mask (editable)
      0001.thumb.jpg     256 px ghost texture
    coverage.json        view-sphere cells and per-vertex coverage counts
    arkit-mesh.usdc      LiDAR scene mesh, when present
  recon/
    dense.usdc           dense mesh with full-resolution texture
    splat.ply            trained splat
    cameras.json         refined poses from the backend
  derived/
    <preset-id>/
      mesh.usdc          derived mesh, UVs, baked maps, LODs
      spec.json          budget, style, maps, source hash
  jobs/
    <job-id>.json        tier, spec, status, timings, logs
```

- `spec.json` plus the dense mesh hash makes every derived output reproducible and cacheable.
- Rejected shots stay on disk until the user purges them, so the coach and ghost viewer can explain rejections.
- The bundle exports as a zip; importing one restores the ghosts and coverage exactly.

## Non-functional requirements

Capture must stay smooth on a three-year-old iPhone; heavy processing may be slower on older devices but must never block capture.

| Area | Requirement |
| --- | --- |
| Devices | Capture on any iPhone or iPad running iOS 27 with ARKit world tracking; LiDAR improves scale, preview and coverage but is optional. Reference devices for testing: iPhone 13, iPhone 16 Pro, iPad Pro M4 |
| AR frame rate | 60 fps on LiDAR Pro devices and at least 30 fps on iPhone 13 with 200 ghosts, coverage dome and heat map visible |
| Shutter latency | Under 150 ms from trigger to still request; scoring under 8 ms per frame on iPhone 13 |
| Thermal | A 300-shot capture must not reach the serious thermal state on iPhone 16 Pro; under thermal pressure the app reduces overlay detail before it drops frames |
| Storage | HEIC stills; user-visible bundle sizes; one-tap purge of originals after reconstruction |
| Derivation speed | 100K to 5K tri decimation with UV and bake at 2K under 20 s on iPhone 16 Pro |
| Privacy | No accounts, no analytics on scan content, location stripped from shots unless the user opts in |
| Accessibility | VoiceOver labels on all controls; haptic and spoken shutter and coverage cues so capture works without watching the screen; Dynamic Type; colour-blind-safe coverage palette (not red/green only) |
| Localisation | English and Irish at launch; strings externalised |
| Quality | Unit tests for core geometry via Cruth; golden-scan regression set of 10 objects run on every release |

## Milestones M0–M6

The MVP goes to TestFlight once M4's gate passes; V1 goes to the App Store after M6. Each milestone closes only when every acceptance criterion below is ticked.

&#91;embedded content: roadmap · M0–M6 with gates; MVP after M4, V1 after M6\]

### M0 · Foundations and spikes

- [ ] Public repo, MIT + DCO, CLAUDE.md, CI building the iOS app and running unit tests
- [ ] Licence allow-list check in CI fails the build on GPL, AGPL or non-commercial dependencies
- [ ] Cruth core builds as an XCFramework and a Swift call decimates a test mesh on device
- [ ] Spike report: Brush builds for iOS on Metal, with iterations per second on iPhone 16 Pro and iPad Pro M4; go or no-go recorded
- [ ] Spike report: Apple `PhotogrammetrySession` support and output quality on the three reference devices
- [ ] Spike report: RealityKit iOS 27 splat rendering of a 500K-splat file at 30 fps or better, or decision to write a Metal renderer
- [ ] Project bundle schema v1 written and validated with a sample bundle

### M1 · Capture core

- [ ] AR session with high-resolution stills and per-shot pose, intrinsics, gravity and depth saved to the bundle
- [ ] Bounding box placement meets C1
- [ ] Auto-shutter and gates meet C2 to C5
- [ ] Photo ghosts render and fade per C6 at 30 fps or better with 200 ghosts on iPhone 13
- [ ] Ghost inspection, delete and aligned retake meet C7
- [ ] Rejection hints meet C14

### M2 · Coverage and guidance

- [ ] View-sphere dome and minimap meet C8
- [ ] Surface heat map meets C9 on LiDAR and non-LiDAR devices
- [ ] Next-best-view meets C10: a tester following only the arrows reaches 85% cell coverage of a 30 cm object within 3 minutes
- [ ] Output-aware recipes (C11) and multi-pass flip (C12) work on the golden set
- [ ] Coverage progress and stop suggestion meet C13

### M3 · On-device reconstruction

- [ ] Instant preview within 15 s of ending capture (P1)
- [ ] Apple dense mesh produced on supported devices, with a clear message on others (P2)
- [ ] Subject masks generated and editable (P4)
- [ ] Splats trained on device if M0's Brush spike passed (P3); otherwise the splat option is hidden on device
- [ ] Background processing with completion notification (P9)
- [ ] AR and orbit viewer for mesh and splat at true scale
- [ ] Golden-set scans produce usable meshes on 8 of 10 objects

### M4 · Polycount and geometry

- [ ] Budget and style picker with live preview and deviation heat map
- [ ] O1, O2, O4, O5 and O10 meet their acceptance criteria
- [ ] Exports: USDZ/USD, glTF/GLB, OBJ, PLY and the project bundle open correctly in Blender, Unreal and AR Quick Look
- [ ] 100K to 5K derivation with UV and 2K bake under 20 s on iPhone 16 Pro
- [ ] MVP build on TestFlight with 20 external testers

### M5 · Offload tiers

- [ ] Mac companion discovered and paired on the local network; runs Apple full detail, Brush splats and large quad remeshes (P5)
- [ ] Server Docker image with COLMAP/GLOMAP, OpenMVS, gsplat and one mesh-from-splat method; HTTPS job API documented (P6)
- [ ] Job router honours per-project allowed tiers and falls back on failure (P7)
- [ ] Uploads resume after a network drop; resubmitting a job never duplicates work (P8)
- [ ] One end-to-end run on NCAD hardware

### M6 · V1 features and release

- [ ] F1 mesh + splat asset, F4 print mode, F6 turntable mode, F7 capture coach
- [ ] F2 reference-object export opens in Cuardach; F3 rig ingest aligns a Canon rig folder with phone shots; F12 hand-off to Cruth
- [ ] O3, O6, O7, O8 and O9 meet their acceptance criteria; STL/3MF export
- [ ] Accessibility, localisation and privacy requirements verified
- [ ] App Store release under the company account; user guide and contributor docs published

## Open questions

- [x] Final name: Macalla (decided 2026-10-25).
- [ ] FBX export: write our own FBX writer, use the proprietary Autodesk SDK (breaks D6 spirit), or drop FBX and rely on USD and glTF?
- [ ] Does Apple's reduced-detail iOS mesh meet the quality bar, or does M3 need an own MVS on device?
- [ ] Which segmentation model for subject masks, and does its licence and weight size fit D6?
- [ ] Should the Mac companion be a separate app or a mode of Cruth's desktop shell (which is Dear ImGui, not SwiftUI)?
- [ ] Server job API: share a schema with Meitheal so NCAD can schedule scans on the same GPU pool?
- [ ] Coverage thresholds (angle step, minimum views per vertex) need tuning on the golden-scan set before they are fixed.
