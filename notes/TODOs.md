# TODOs

## Backlog (M0 · Foundations and spikes)

- [ ] Spike: Brush on iPhone 16 Pro and iPad Pro M4, iterations/s and peak memory → ADR 0001 (runner ready in `spikes/brush`)
- [ ] Brush without `rerun`/`re_analytics` (P11) before ADR 0001 can be a go: [brush#561](https://github.com/ArthurBrussee/brush/pull/561) open; until merged, build from the `Fiavaion/brush` `optional-rerun` branch
- [ ] Spike: `PhotogrammetrySession` on the three reference devices, 3 golden objects → ADR 0002 (screen ready)
- [ ] Spike: RealityKit 500K splats, 60 s, iPhone 13 and iPhone 16 Pro → ADR 0003 (screen ready); confirm quaternion order and SH colour on device
- [ ] Re-pin `spec/cruth-commit` once Cruth's branch merges to `main`
- [ ] Follow upstream: [cubecl#1930](https://github.com/tracel-ai/cubecl/pull/1930), [brush#561](https://github.com/ArthurBrussee/brush/pull/561), iOS fixes offered on [brush#27](https://github.com/ArthurBrussee/brush/issues/27)

## In Progress

## Ready for Review

## Done (recent, rolling)

- [x] 2026-10-25 CI green on GitHub (Cruth made public; `xcode-27` runner)
- [x] 2026-10-25 Project bundle schema v1 + sample bundle + validator (M0)
- [x] 2026-10-25 Cruth core as XCFramework, CruthKit wrapper, decimation test on Mac and simulator (M0; device run pending)
- [x] 2026-10-25 Licence allow-list and guard, CI workflow, CONTRIBUTING.md (M0)
- [x] 2026-10-25 Spike tooling: splat and photogrammetry screens, Brush iOS build and device runner
- [x] 2026-10-25 Fresh-context review: 2 blockers, 4 high, 4 medium, 6 low found and fixed
- [x] 2026-10-25 Public repo on GitHub, MIT + DCO
- [x] 2026-10-25 Project bootstrap
