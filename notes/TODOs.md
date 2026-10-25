# TODOs

## Backlog (M0 · Foundations and spikes)

- [ ] ADR 0003: run the splat spike on the iPhone 13 (30 fps bar) and an iPhone 16 Pro (60 fps bar) with `spike.ply` = the 420,979-splat `panther` scan (`../Macalla-data/panther.ply`), chunks of 250,000; then decide (leaning: RealityKit + chunking + per-device splat budget)
- [ ] ADR 0002: real-photo capture of a small object (60–100 photos) → `Documents/spike-images` on device → `-spike photogrammetry`; repeat on reference devices for 3 golden objects
- [ ] ADR 0001: real-photo capture → COLMAP poses on the Mac → `spikes/brush/run-device.sh` on iPhone 16 Pro / iPad Pro M4 (lego is unusable: Brush ends at ~5,500 splats, LESSON-TEST-001)
- [ ] Brush without `rerun`/`re_analytics` (P11) before ADR 0001 can be a go: [brush#561](https://github.com/ArthurBrussee/brush/pull/561) open; until merged, build from the `Fiavaion/brush` `optional-rerun` branch
- [ ] Follow upstream: [cubecl#1930](https://github.com/tracel-ai/cubecl/pull/1930), [brush#561](https://github.com/ArthurBrussee/brush/pull/561), iOS fixes offered on [brush#27](https://github.com/ArthurBrussee/brush/issues/27)
- [ ] Re-pin `spec/cruth-commit` once Cruth's `claude/lucid-franklin-mrpthk` branch merges to `main` (checked 2026-10-25: not merged)
- [ ] CruthKit decimation test on a physical device (runs in the scheme; only simulator and Mac so far)

## In Progress

## Ready for Review

## Done (recent, rolling)

- [x] 2026-10-25 ADR 0003 measured on iPad Pro M1 (extra device): splat cap 262,144 per resource, chunking, 16-byte buffers, real scan 33.7 fps mean / 18.0 worst
- [x] 2026-10-25 ADR 0001–0003 thresholds confirmed by the product owner
- [x] 2026-10-25 Upstream: cubecl#1930 and brush#561 opened, brush#27 commented
- [x] 2026-10-25 CI green on GitHub (Cruth made public; `xcode-27` runner)
- [x] 2026-10-25 Project bundle schema v1 + sample bundle + validator (M0)
- [x] 2026-10-25 Cruth core as XCFramework, CruthKit wrapper, decimation test on Mac and simulator (M0)
- [x] 2026-10-25 Licence allow-list and guard, CI workflow, CONTRIBUTING.md (M0)
- [x] 2026-10-25 Spike tooling: splat and photogrammetry screens, Brush iOS build and device runner
- [x] 2026-10-25 Fresh-context review: 2 blockers, 4 high, 4 medium, 6 low found and fixed
- [x] 2026-10-25 Public repo on GitHub, MIT + DCO
- [x] 2026-10-25 Project bootstrap
