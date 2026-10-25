# TODOs

## Backlog (M0 · Foundations and spikes)

- [ ] Public repo on GitHub, MIT + DCO, `CONTRIBUTING.md`
- [ ] CI: build the iOS app, run `swift test` and the UI smoke test
- [ ] Licence allow-list in `spec/dependencies.md` and a CI check that fails on GPL, AGPL or non-commercial dependencies (D6)
- [ ] Cruth core as an XCFramework; a Swift call decimates a test mesh on device (D4)
- [ ] Spike: Brush on iOS/Metal, iterations/s on iPhone 16 Pro and iPad Pro M4 → ADR 0001
- [ ] Spike: `PhotogrammetrySession` support and quality on the three reference devices → ADR 0002
- [ ] Spike: RealityKit iOS 27 splat rendering, 500K splats at ≥30 fps → ADR 0003
- [ ] Project bundle schema v1 complete (`session.json`, shot JSON, `spec.json`, `jobs/`), validated against a sample bundle. `manifest.json` is done.

## In Progress

## Ready for Review

## Done (recent, rolling)

- [x] 2026-10-25 Project bootstrap: CLAUDE.md, XcodeGen app, MacallaKit with `ProjectManifest`, smoke test, ADRs 0001–0003 (proposed)
