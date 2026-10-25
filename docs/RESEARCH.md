# Macalla — Research

Oct 25, 2026 · @Mark Jones

## Executive summary

Build it as a native Swift capture app over Cruth's shared C++ geometry core, with reconstruction that runs on the device by default and offloads to a Mac or a self-hosted GPU server for heavy jobs. The capture experience is where the app can beat every competitor; reconstruction and geometry can be assembled from permissive open-source parts.

- **The market has no open-source option.** RealityScan Mobile, Polycam, KIRI Engine, Luma and Scaniverse are all closed. Only Scaniverse processes entirely on the device; the rest lean on their own clouds.
- **Nobody leaves the photos in the scene.** RealityScan overlays a live point cloud and Scaniverse shades missing areas, but none shows each shot as an inspectable, deletable frame where it was taken. That is the signature feature.
- **Polycount control is weak everywhere.** Apple offers fixed detail buckets; KIRI's quad-count target is behind a paywall. A free, exact face or quad target with clean topology is a clear gap.
- **Apple's Object Capture is a useful engine, not a foundation.** Its guided capture needs LiDAR and an A14 chip, iOS only builds reduced-detail models, and a recent developer report shows it refusing a new iPhone. Own the capture loop; call Apple's reconstruction as one backend among several.
- **On-device Gaussian splats are proven.** Scaniverse trains splats on iPhone 11 and later, and Brush offers a portable, permissive trainer. Mesh-from-splat methods (PGSR, MILo, TopoSurfel) now rival photogrammetry on benchmarks.
- **Feed-forward models change the preview.** MapAnything (Apache 2.0 weights) and VGGT (commercial weights available) give poses and dense geometry in one pass, which suits instant previews and pose recovery on the server tier.
- **Licensing decides the stack.** Keep GPL/AGPL code (OpenMVS) and the Inria 3DGS reference code out of the App Store binary. COLMAP/GLOMAP (BSD), gsplat (Apache 2.0), meshoptimizer and xatlas (MIT) are safe.

Recommended scope for the MVP: own AR capture with auto-shutter, photo ghosts and coverage feedback; on-device mesh via Apple's engine plus splats via a Brush-class trainer; exact polycount via Cruth's decimator and remesher; offload to Mac and server; USD, glTF, OBJ, FBX and PLY export.

## Competitive landscape

Every serious competitor is closed-source, and only one keeps processing on the phone. The features worth matching are RealityScan's auto capture and live coverage overlay, Scaniverse's on-device splats, and KIRI's quad retopology with a quad-count target.

| App | Processing | Outputs | Capture guidance | Polycount / topology control | Cost and terms |
| --- | --- | --- | --- | --- | --- |
| [RealityScan Mobile](https://www.realityscan.com/mobile?lang=en-US) (Epic) | Epic's cloud engine | Textured mesh; Sketchfab upload; device export | Live point cloud over the subject marks covered and missing areas; auto capture; AR preview at true scale | Processing options panel since 1.6; no exact target | Free; EULA lets Epic train on scans unless you opt out ([CG Channel](https://www.cgchannel.com/2025/01/check-out-free-android-and-ios-3d-scanning-app-realityscan-1-6)) |
| [Scaniverse](https://apps.apple.com/us/app/scaniverse-lidar-3d-scanner/id1541433223?uo=4) (Niantic) | Entirely on the device, offline | Splats (PLY), meshes (OBJ, FBX, USDZ, LAS) | Red or shaded overlay where data is missing ([HKU guide](https://aihub.hkuspace.hku.hk/creative-and-production/scaniverse/)) | None beyond mode choice | Free, unlimited; splats need iPhone 11 or later ([forum](https://community.scaniverse.com/t/the-scaniverse-app-should-tell-user-if-splat-scanning-is-not-available-on-their-device/752)) |
| [KIRI Engine](https://kiriengine.app/features/quad-mesh-retopology) | Cloud | Mesh, 3DGS, 3DGS-to-mesh, AI PBR maps | Standard photo guidance | Quad retopology with target quad count and curve ratio, plus texture re-bake ([80.lv](https://80.lv/articles/kiri-engine-released-v2-3)) | Quad export is Pro-only; v4.2 (2026) added 3DGS-to-Mesh 3.0 and a scaling tool ([Radiance Fields](https://radiancefields.com/kiri-engine-4.2-ships-3dgs-to-mesh-3.0)) |
| Polycam | Cloud, 2 to 10 minutes | Mesh (USDZ, OBJ, GLB, FBX), splats | LiDAR, photo, room and splat modes ([Strayspark](https://www.strayspark.studio/blog/photogrammetry-indie-open-worlds-2026)) | Export-time options | Subscription; uploads raise IP and privacy questions |
| Luma AI | Cloud | Splats first, mesh as fallback | Video walk-around | None | Free tier watermarked; Pro about USD 30 a month ([Strayspark](https://www.strayspark.studio/blog/photogrammetry-indie-open-worlds-2026)) |
| Apple Object Capture sample | On device (iOS) or Mac | USDZ, OBJ at fixed detail levels | Bounding box, capture dial, flip prompts ([WWDC23 notes](https://wwdcnotes.com/notes/wwdc23/10191)) | Fixed buckets only | Free sample code; LiDAR and A14 required |

**Gaps to exploit:** no open-source app; no app that leaves each photo in the scene as an inspectable frame; no free, exact polycount or quad-count target; no app that pairs a clean low-poly mesh with a splat of the same capture as one asset; no app that lets you choose where processing runs. RealityScan Mobile 1.8 (November 2025) added automatic background removal and cleanup tools ([CG Channel](https://www.cgchannel.com/tag/ar-guidance)), so masking is now table stakes.

## Apple platform capabilities

Apple supplies a capable reconstruction engine and, since iOS 27, native splat rendering and object tracking, but its guided-capture UI is too closed to host photo ghosts or a custom auto-shutter. Build capture on ARKit and AVFoundation directly; use RealityKit's photogrammetry as one backend.

| API | What it gives | Limits that matter here |
| --- | --- | --- |
| `ObjectCaptureSession` + `ObjectCaptureView` (iOS 17+) | Guided capture state machine, auto bounding box, coverage dial, flip detection, checkpoint data that speeds reconstruction ([WWDC23 notes](https://wwdcnotes.com/notes/wwdc23/10191)) | Needs LiDAR and an A14 or later; the SwiftUI view owns the camera feed, so custom AR overlays are hard |
| `PhotogrammetrySession` | Photos to USDZ or OBJ; can use iPhone stereo depth to recover true size and gravity so models come out upright ([WWDC21](https://developer.apple.com/wwdc21/10076/)) | iOS builds reduced detail only, with diffuse, AO and normal maps; medium, full and raw need a Mac ([WWDC23 notes](https://wwdcnotes.com/notes/wwdc23/10191)) |
| Detail levels | Preview, reduced, medium, full, raw ([Kodeco](https://www.kodeco.com:443/books/apple-augmented-reality-by-tutorials/v2.0/chapters/18-creating-3d-models-with-object-capture)) | Buckets, not a face count: an exact polycount needs our own decimator |
| `isOverCaptureEnabled` | Captures extra data on iPhone for a later Mac reconstruction ([Apple forums](https://developer.apple.com/forums/thread/734811)) | Developers report the guided capture's photos can be worse than plain AVFoundation stills |
| RealityKit splats (iOS 27 / visionOS 27) | Native Gaussian splat rendering ([Apple WWDC26 guide](https://developer.apple.com/wwdc26/guides/visionos/)) | Developer reports of culling bugs in iOS 27 betas ([Apple forums](https://developer.apple.com/forums/tags/realitykit)); keep a fallback Metal renderer |
| ARKit object tracking on iOS 27 | Reference objects work on iOS and visionOS with the same tracking quality ([WWDC26 session 287](https://developer.apple.com/videos/play/wwdc2026/287/)) | Training a reference object can take hours with Extended Training ([UploadVR](https://www.uploadvr.com/visionos-27-announced-apple-vision-pro-wwdc-26/)) |

**Device risk.** A developer reported in 2026 that Object Capture reports "not supported" on an iPhone 18 Pro Max under Xcode 27 ([Apple forums](https://developer.apple.com/forums/tags/realitykit)). Treat Apple's engine as optional and detect support at run time.

**What we use from ARKit directly:** world-tracking poses per frame, LiDAR scene depth and mesh where present, gravity, and high-resolution still capture during an AR session. Those poses become priors for every backend, which is what makes photo ghosts and server-side posed reconstruction possible.

## Auto-capture and coverage feedback

A good auto-shutter fires on new viewpoint, not on time, and refuses frames that will hurt the reconstruction. Coverage is best shown in two layers at once: a view sphere around the object (where have I stood?) and a surface heat map (which parts of the object are seen well enough?).

**Shutter triggers, in order of importance:**

1. **Viewpoint novelty.** Fire when the camera's direction to the object centre has moved a set angle from every kept shot. Around 5 to 10 degrees gives the 60 to 80 percent overlap photogrammetry wants; the angle should tighten for small or glossy objects.
2. **Sharpness gate.** Reject if angular velocity from the gyro is high or a fast Laplacian-variance score on a downscaled frame falls below the session's running median.
3. **Exposure and focus gate.** Reject clipped highlights over the subject mask, and wait for focus to settle; lock white balance and exposure for the session so textures stay consistent.
4. **Subject in frame.** The subject's projected bounding box must fill a set share of the frame and stay inside it.

**Coverage models:**

- **View sphere.** Tessellate a sphere around the bounding box into equal-area cells (a geodesic grid of about 80 to 320 cells). Each cell counts kept shots and their quality. Render it as a translucent dome in AR and a 2D minimap.
- **Surface coverage.** Project kept shots onto the LiDAR mesh (or ARKit feature points on non-LiDAR devices) and count, per vertex, how many views see it at a grazing angle under about 60 degrees. Colour from red (under 3 views) to green (6 or more). This is what RealityScan's live point cloud approximates ([RealityScan](https://www.realityscan.com/mobile?lang=en-US)).
- **Next best view.** Pick the unseen or weak sphere cell nearest the user and show an arrow and target ring. This turns coverage from a report into an instruction.

**Photo ghosts (leaving each image in space):** draw every kept shot as its camera frustum with the photo textured on a quad near the frustum's far end. Fade ghosts with distance and angle so the scene does not clutter; show them full strength when the user stops moving. Tapping a ghost opens the photo with its sharpness and exposure scores, and offers delete or retake. Retake mode shows the ghost as an alignment overlay so the user can match the original pose. No competitor surveyed does this; Apple's capture view shows a dial of shot counts, not the shots ([WWDC23 notes](https://wwdcnotes.com/notes/wwdc23/10191)).

**Performance budget.** Ghost textures should be small thumbnails (about 256 px) in a texture array, with full stills written to disk off the main thread. Keep scoring under one frame time on A15-class phones by running it on a quarter-resolution luma buffer.

## Reconstruction pipelines

Three families now compete, and the app should use all three for different jobs: classic photogrammetry for the final mesh, feed-forward networks for instant previews and pose recovery, and Gaussian splatting for appearance and as a second route to a mesh.

| Family | Representative tools | Strength | Weakness | Role in this app |
| --- | --- | --- | --- | --- |
| SfM + multi-view stereo | Apple `PhotogrammetrySession`; [COLMAP and GLOMAP](https://github.com/colmap/colmap) (BSD); [OpenMVS](https://github.com/cdcseacave/openMVS/blob/master/COPYRIGHT.md) (AGPL) | Accurate, metric with depth priors, mature texturing | Slow at high detail; struggles on shiny or textureless objects | Final mesh: Apple on device and Mac, COLMAP/GLOMAP + OpenMVS on the server |
| Feed-forward geometry | VGGT, π³, [MapAnything](https://arxiv.org/abs/2509.13414v3) | Poses and dense depth in one pass; MapAnything accepts known poses, intrinsics and depth as inputs ([project](https://scour.ing/@2601/p/https://map-anything.github.io)) | Large models; still below optimised SfM on accuracy | Instant preview and pose rescue on Mac and server; on-device later if a distilled model fits |
| Gaussian splatting | [gsplat](https://cdn.jsdelivr.net/npm/gridstamp@1.4.0/THIRD_PARTY_LICENSES.md) (Apache 2.0), [Brush](https://github.com/ArthurBrussee/brush), Scaniverse's on-device trainer | Photoreal appearance, handles fine and fuzzy detail | Not a mesh; files are heavy | Second output; on device via a Brush-class trainer, full quality on server |
| Mesh from splats | PGSR, 2DGS, [MILo](https://arxiv.org/html/2506.24096v2), [TopoSurfel](https://www.emergentmind.com/papers/2608.20687) | MILo extracts meshes with about 10 times fewer vertices; TopoSurfel reports 0.51 mm Chamfer on DTU in 37 minutes | GPU-hours on server hardware | Alternative mesh route for objects photogrammetry fails on |

**Brush is the key on-device enabler.** It is an Apache-2.0 Rust splatting engine built on WebGPU-compatible tech and the Burn ML framework; it trains natively on macOS, Windows, Linux, Android and in the browser, takes COLMAP or Nerfstudio datasets, and supports image masks ([Brush](https://github.com/ArthurBrussee/brush)). The current README lists no iOS target, though wgpu runs on Metal. Its authors report training and rendering generally faster than gsplat, and earlier benchmarks showed SSIM matching or beating the Inria and gsplat references ([trendshift](https://trendshift.io/admin/repository/ask-ai/12209)). An iOS build is an M1 spike, not an assumption.

**ARKit poses help every backend.** Feeding ARKit's per-shot poses and LiDAR depth as priors turns uncalibrated SfM into posed reconstruction: faster, more robust on low-texture objects, and metric. MapAnything explicitly supports posed inputs ([arXiv](https://arxiv.org/pdf/2509.13414v2)).

**Weights licensing.** MapAnything ships Apache 2.0 weights ([arXiv](https://arxiv.org/pdf/2509.13414v2)); VGGT has a separate commercial checkpoint ([Replicate](https://replicate.com/vufinder/map-anything-vggt-1b)). Check each checkpoint, not just the code.

## Geometry processing

Exact polycount is a post-process, not a reconstruction setting: reconstruct dense, then decimate or remesh to the target and bake detail back. Cruth's shared C++ core already plans remesh, retopo and auto-UV, so this app should consume it rather than build a second pipeline.

| Operation | Approach | Library and licence | Runs on |
| --- | --- | --- | --- |
| Decimation to exact triangle count | Quadric error edge collapse that also weighs UVs and normals; lock border and seam vertices | [meshoptimizer](https://pypi.org/project/meshoptimizer/) (MIT); v0.25 added a Regularize flag for more even tessellation ([release](https://github.com/zeux/meshoptimizer/releases/tag/v0.25)) | Device |
| Isotropic remesh | Even triangles at a target edge length, for sculpting or simulation | Cruth core | Device |
| Quad retopology to target quad count | Field-aligned quad remesh (Instant Meshes / QuadriFlow class), with feature-edge and symmetry hints | Cruth core; Blender's own Quad remesh uses QuadriFlow ([Blender manual](https://docs.blender.org/manual/ru/4.4/modeling/meshes/retopology.html)) | Device (small), Mac or server (large) |
| Learned artist-style remesh | Autoregressive mesh generation conditioned on a point cloud: [Meshtron](https://arxiv.org/pdf/2412.09548) (up to 64K faces, density control), [QuadGPT](https://arxiv.org/html/2509.21420v2) (native quad-dominant) | Research code; check each licence | Server, optional |
| UV unwrap and packing | Chart segmentation, parameterisation and atlas packing | [xatlas](https://github.com/ducphamhong/xatlas) (MIT) | Device |
| Baking | Normal, displacement, AO and colour from dense mesh (or splat) to low poly | Own Metal kernels in Cruth core | Device or Mac |
| De-lighting and PBR maps | Single-view diffusion priors fused across views: [RGB↔X](https://arxiv.org/pdf/2503.18461), [SuperMat](https://arxiv.org/pdf/2411.17515v4) (about 3 s per object), [Intrinsic Image Fusion](https://arxiv.org/html/2512.13157v1) (multi-view consistent) | Research code and weights | Server |
| LOD chain | Successive decimation passes, one texture atlas | meshoptimizer | Device |

**How polycount picking should work.** The user picks a target (presets such as 1K, 5K, 20K, 100K faces, or a typed number) and a topology style (triangles, quad-dominant, all quads). The app reconstructs once at high detail, then generates the target as a cheap derived output that can be changed without re-running reconstruction. KIRI's quad remesher exposes target quad count and curve ratio ([80.lv](https://80.lv/articles/kiri-engine-released-v2-3)); matching that, for free, is the baseline.

**Commercial benchmark.** InstaLOD's July 2026 Quad Remesh added adaptive layouts and can simplify existing quad meshes down to their essential loops ([Abstract 3D](https://abstract3d.com/?p=3573)). That second trick, quad-to-quad reduction, is worth copying.

## Hybrid processing architecture

The phone handles capture, previews and moderate jobs offline; a Mac on the same network and a self-hosted GPU server take what the phone cannot, and every tier reads and writes the same project bundle.

&#91;embedded content: hybrid processing · 3 tiers sharing one project bundle\]

- **Device (default).** Works offline and nothing leaves the phone. Scaniverse proves on-device splats and meshes are viable for a free app ([Scaniverse support](https://scaniverse.com/support)).
- **Mac companion.** A small macOS app from the same codebase, found automatically on the local network. It unlocks Apple's medium, full and raw detail, which iOS cannot build.
- **Self-hosted server.** A Docker image any person or institution can run on a Linux GPU box. It is the only tier allowed CUDA-only and AGPL code. NCAD's GPU estate would be one instance, scheduled through Meitheal.
- **No vendor cloud.** The user chooses the tier per project, and uploads go only to servers they have added, which avoids the IP and privacy concerns of cloud-only apps.
- **Bundle and jobs.** HEIC stills, ARKit poses as JSON, depth, masks and USD outputs in one folder; uploads resume after a drop, and jobs are idempotent so a retry never duplicates work.

## Open-source licensing and App Store constraints

Release the app under MIT (matching Cruth) and ship only permissive code in the App Store binary; copyleft and research-only code is acceptable on the self-hosted server, where it runs as a separate program.

| Component | Licence | In the iOS binary? | Note |
| --- | --- | --- | --- |
| [COLMAP / GLOMAP](https://colmap.readthedocs.io/en/latest/license.html) | BSD | Yes | Dependencies are licensed separately and can change the result |
| [meshoptimizer](https://awesome.ecosyste.ms/projects/github.com%2Fzeux%2Fmeshoptimizer) | MIT | Yes |  |
| [xatlas](https://github.com/ducphamhong/xatlas) | MIT | Yes |  |
| [Brush](https://github.com/ArthurBrussee/brush) | Apache 2.0 | Yes |  |
| gsplat | Apache 2.0 | Server only (CUDA) | Permissive replacement for the Inria code ([GridStamp notice](https://cdn.jsdelivr.net/npm/gridstamp@1.4.0/THIRD_PARTY_LICENSES.md)) |
| [Inria 3DGS reference](https://huggingface.co/spaces/jiawei011/dreamgaussian/blob/main/LICENSE_GAUSSIAN_SPLATTING.md) | Research, non-commercial | No | Commercial use needs Inria's consent; avoid entirely, including in derived kernels |
| [OpenMVS](https://github.com/cdcseacave/openMVS/blob/master/COPYRIGHT.md) | AGPL-3.0 | No | Server only; its bundled parts include research-only code (ibfs) and GPL/LGPL CGAL |
| MapAnything weights | Apache 2.0 | Possible later |  |
| VGGT weights | Separate commercial checkpoint | Server | Use the commercial weights only |

**Why no GPL in the binary.** Apple's App Store terms add usage rules the GPL forbids, which is why VLC was pulled in 2011 and why GPLv3 is widely treated as incompatible ([Genbeta](https://www.genbeta.com/windows/pues-no-microsoft-no-ha-cerrado-la-puerta-al-software-libre-en-windows-marketplace)). Some GPLv3 apps do ship today without challenge ([discussion](https://providence.root.sx/post/169521)), but that is tolerance, not permission. Permissive licences remove the question.

**Server tier note.** AGPL's network clause requires offering source to users of a networked service. Because the whole project is already public, running OpenMVS on the server is compliant as long as the server bundle links to its source.

## Novel opportunities beyond a RealityScan clone

The strongest ideas use the fact that this app knows where every photo was taken and what the output is for. Phase is a suggestion for the PRD; ideas marked "later" depend on server models or research code.

| Idea | What it does | Why it is new | Phase |
| --- | --- | --- | --- |
| Photo ghosts as an editable capture graph | Every shot stays in AR as a frustum; tap to inspect scores, delete or retake with an alignment overlay | No competitor surveyed shows shots in place | MVP |
| Next-best-view guidance | Arrow and target ring to the nearest weak coverage cell | Turns a coverage map into an instruction | MVP |
| Output-aware capture | The chosen target (game prop, 3D print, hero asset, splat) sets shot density, gates and required angles | Capture adapts to the intended polycount instead of one fixed recipe | MVP |
| Mesh and splat as one asset | Same capture yields a clean low-poly mesh and a splat aligned in one USD file; optional bake of splat appearance onto the mesh | Competitors offer either, or convert one to the other | V1 |
| Quad-to-quad reduction and LODs | Reduce a quad remesh to fewer loops; emit an LOD chain sharing one atlas | Copies InstaLOD's best trick for free | V1 |
| Flow-guided retopo | Paint curves on the scan to steer edge loops (shared with Cruth's planned curve-painting) | Retopo users get control that one-click remeshers lack | V1 |
| Rig ingest | Import a folder from the NCAD Canon 250D rig or any DSLR and merge it with phone shots; phone ghosts help fill gaps | Unifies phone and studio capture | V1 |
| 3D-print mode | Metric scale from LiDAR or a reference marker, watertight solid, wall-thickness check and repair (Cruth's print tools) | KIRI only just added scaling; nobody checks printability on capture | V1 |
| Scan as a tracking target | Export the scan as an ARKit reference object, now supported on iOS 27 ([WWDC26](https://developer.apple.com/videos/play/wwdc2026/287/)), and hand it to Cuardach for AR hunts | Closes the loop from scan to AR experience | V1 |
| De-lit PBR textures | Server pass that fuses per-view material predictions into albedo, roughness and normal maps | Turns scans into relightable game assets | Later |
| Part segmentation | Split multi-part objects (lid, handle, base) into separate meshes before remeshing | Better topology per part | Later |
| Revisit and diff | Re-scan the same object months later, align, and colour where it changed | Useful for conservation and student work-in-progress | Later |
| Learned artist topology | Meshtron or QuadGPT-class remesh as a server option | Research-grade, but clearly where the field is going | Later |
| Capture coach | After each session, a short critique of weak shots, using the ghost scores | Teaches photogrammetry rather than hiding it | Later |

## Risks and open questions

The largest risk is on-device performance: splat training and reconstruction on a phone are heat- and memory-bound, so the offload tier must be good from the first release, not an afterthought.

| Risk | Likelihood | Mitigation |
| --- | --- | --- |
| Brush does not build or run fast enough on iOS Metal | Medium | M1 spike before committing; fallback is splats on Mac and server only |
| Apple Object Capture unavailable on some devices or changes behaviour | Medium | Run-time capability check; own capture never depends on it; server and Mac backends cover the gap |
| Thermal throttling during long captures with ghosts, scoring and AR | High | Thumbnail ghosts, quarter-res scoring, defer heavy work until capture ends |
| Licence contamination from a dependency | Medium | Licence allow-list in CI (`cargo deny` for Rust, a script for C++ and Swift packages) |
| Shiny, transparent and textureless objects | High | Polarising-filter and powder tips in the coach; splat route; LiDAR depth priors |
| Storage: 200 full-res photos per scan | High | HEIC stills, purge originals after reconstruction unless pinned, export project bundles |
| Learned models too large for the device | High | Keep them server-side; distil only if a clear win appears |

**Open questions**

- [ ] Does Brush compile for iOS with wgpu on Metal, and how many seconds per 1,000 iterations on an A17 Pro and an M4 iPad?
- [ ] Is Apple's reduced-detail iOS reconstruction good enough as the default dense mesh, or should the device run its own MVS?
- [ ] Which iPhones without LiDAR are in scope, and what coverage feedback works on feature points alone?
- [ ] Does RealityKit's iOS 27 splat renderer meet the needs, or is a custom Metal splat renderer required?
- [ ] What job protocol suits the offload tier: plain HTTPS with resumable uploads, or something lighter on the local network?

## Sources

- [RealityScan Mobile product page](https://www.realityscan.com/mobile?lang=en-US)
- [CG Channel: RealityScan 1.6](https://www.cgchannel.com/2025/01/check-out-free-android-and-ios-3d-scanning-app-realityscan-1-6) and [RealityScan Mobile 1.8](https://www.cgchannel.com/tag/ar-guidance)
- [Scaniverse on the App Store](https://apps.apple.com/us/app/scaniverse-lidar-3d-scanner/id1541433223?uo=4) and [Scaniverse device support thread](https://community.scaniverse.com/t/the-scaniverse-app-should-tell-user-if-splat-scanning-is-not-available-on-their-device/752)
- [KIRI Engine quad-mesh retopology](https://kiriengine.app/features/quad-mesh-retopology), [80.lv on KIRI 2.3](https://80.lv/articles/kiri-engine-released-v2-3), [Radiance Fields on KIRI 4.2](https://radiancefields.com/kiri-engine-4.2-ships-3dgs-to-mesh-3.0)
- [Strayspark: photogrammetry for indie open worlds, 2026](https://www.strayspark.studio/blog/photogrammetry-indie-open-worlds-2026)
- [WWDC23 Meet Object Capture for iOS (notes)](https://wwdcnotes.com/notes/wwdc23/10191), [WWDC21 Object Capture](https://developer.apple.com/wwdc21/10076/), [Apple forum on over-capture](https://developer.apple.com/forums/thread/734811), [RealityKit forum tag](https://developer.apple.com/forums/tags/realitykit)
- [Apple WWDC26 visionOS guide](https://developer.apple.com/wwdc26/guides/visionos/), [WWDC26 session 287](https://developer.apple.com/videos/play/wwdc2026/287/), [UploadVR on visionOS 27](https://www.uploadvr.com/visionos-27-announced-apple-vision-pro-wwdc-26/)
- [MapAnything (arXiv)](https://arxiv.org/abs/2509.13414v3), [VGGT commercial weights on Replicate](https://replicate.com/vufinder/map-anything-vggt-1b)
- [Brush](https://github.com/ArthurBrussee/brush)
- [MILo](https://arxiv.org/html/2506.24096v2), [TopoSurfel summary](https://www.emergentmind.com/papers/2608.20687)
- [Meshtron](https://arxiv.org/pdf/2412.09548), [QuadGPT](https://arxiv.org/html/2509.21420v2), [InstaLOD Quad Remesh](https://abstract3d.com/?p=3573)
- [SuperMat](https://arxiv.org/pdf/2411.17515v4), [Intrinsic Image Fusion](https://arxiv.org/html/2512.13157v1), [MuMA on RGB↔X](https://arxiv.org/pdf/2503.18461)
- [COLMAP licence](https://colmap.readthedocs.io/en/latest/license.html), [OpenMVS copyright](https://github.com/cdcseacave/openMVS/blob/master/COPYRIGHT.md), [meshoptimizer v0.25](https://github.com/zeux/meshoptimizer/releases/tag/v0.25), [xatlas](https://github.com/ducphamhong/xatlas), [Inria 3DGS licence](https://huggingface.co/spaces/jiawei011/dreamgaussian/blob/main/LICENSE_GAUSSIAN_SPLATTING.md)
- [Genbeta on GPL and app stores](https://www.genbeta.com/windows/pues-no-microsoft-no-ha-cerrado-la-puerta-al-software-libre-en-windows-marketplace)
