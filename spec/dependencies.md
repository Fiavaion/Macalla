# Dependency allow-list

PRD decision D6: no GPL, AGPL, LGPL or non-commercial code in the App Store binary. A dependency may be added only once it has a row here with its licence (SPDX identifier), where it runs, and why it is needed. `scripts/check-licences.sh` runs in CI and fails if any row whose "Runs in" column is `app binary` has a licence outside the list below.

Columns: "Runs in" is one of `app binary`, `server only` or `build tool`. Keep the Licence column to a single SPDX identifier (put caveats in Use).

| Dependency | Licence | Runs in | Source | Status and use |
| --- | --- | --- | --- | --- |
| Cruth core | MIT | app binary | https://github.com/Fiavaion/Cruth | Built as an XCFramework by `scripts/build-cruth.sh` from the commit in `spec/cruth-commit`: decimation, remeshing, UVs, baking, print checks (D4) |
| QuadriFlow | BSD-3-Clause | app binary | https://github.com/hjwdzh/QuadriFlow | Vendored in Cruth (patched: no Boost, no external SAT, no `exit()`); quad remesh |
| LEMON | BSL-1.0 | app binary | https://lemon.cs.elte.hu/ | Vendored in Cruth (header subset, no LP back-ends); min-cost flow for QuadriFlow |
| Eigen | MPL-2.0 | app binary | https://gitlab.com/libeigen/eigen | Vendored in Cruth (`Eigen/` only, `EIGEN_MPL2_ONLY`); linear algebra for QuadriFlow |
| MikkTSpace | Zlib | app binary | https://github.com/mmikk/MikkTSpace | Vendored in Cruth (unmodified); tangent basis for normal maps |
| OpenSubdiv | Apache-2.0 | app binary | https://github.com/PixarAnimationStudios/OpenSubdiv | Planned in Cruth; Catmull-Clark subdivision |
| geometry-central | MIT | app binary | https://github.com/nmwsharp/geometry-central | Planned in Cruth; BFF parameterisation |
| libigl (core only) | MPL-2.0 | app binary | https://github.com/libigl/libigl | Planned in Cruth; LSCM and ARAP; never `igl/copyleft/` |
| OpenUSD | Apache-2.0 | app binary | https://github.com/PixarAnimationStudios/OpenUSD | Planned in Cruth; scene and project format |
| Brush | Apache-2.0 | app binary | https://github.com/ArthurBrussee/brush | Pending ADR 0001 and the M0 spike: on-device Gaussian splat training (D9, P3). Pinned `1388f74c` in `spikes/brush`. Transitive crates checked 2026-10-25: MIT/Apache plus four MPL-2.0 (`buildid`, `colored`, `indent`, `option-ext`); `rerun`/`re_analytics` must be removed before shipping (P11) |
| COLMAP | BSD-3-Clause | server only | https://github.com/colmap/colmap | Planned (V1): structure from motion on the user's server (D8, P6) |
| GLOMAP | BSD-3-Clause | server only | https://github.com/colmap/glomap | Planned (V1): global structure from motion on the user's server (D8, P6) |
| OpenMVS | AGPL-3.0-only | server only | https://github.com/cdcseacave/openMVS | Planned (V1): dense mesh on the user's server. AGPL is allowed here only because it never ships in the app binary (D8) |
| gsplat | Apache-2.0 | server only | https://github.com/nerfstudio-project/gsplat | Planned (V1): splat training on the user's server (D9, P6) |

## Allowed licences for the app binary

- MIT
- BSD-2-Clause
- BSD-3-Clause
- Apache-2.0
- Zlib (zlib licence)
- MPL-2.0 (file-level copyleft only: modified MPL files are published, the rest of the app is unaffected)
- ISC
- BSL-1.0 (Boost)
- Unlicense

## Forbidden in app binary

- GPL (any version), AGPL, LGPL (the App Store cannot ship them)
- Any non-commercial or research-only licence (CC-BY-NC and similar, including some research model weights)
- Any licence with a network-use, field-of-use or attribution-to-endorse restriction not listed above
- Code with no licence

Server-only components run in the user's own Docker image and are not distributed in the app, so the forbidden list does not apply to them. They must still be listed here.

## Rejected

CGAL (GPL algorithms), Qt (LGPL), RetopoFlow (GPL), OpenVDB on iOS (too heavy).
