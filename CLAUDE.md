# Macalla: notes for Claude Code

Macalla is a free, MIT-licensed iPhone and iPad app that turns a walk around an object into a textured mesh at a chosen polycount, plus a Gaussian splat of the same capture. Photos stay in AR where they were taken ("photo ghosts"), coverage is shown live, and processing runs on the device by default, with optional offload to the user's own Mac or server. It is the capture front end to Cruth (`../Cruth`), whose C++ geometry core it will link as an XCFramework.

- Requirements: @docs/PRD.md (requirement IDs like C2, P3, O1, F5 and decisions D1–D12 are referenced everywhere; milestones M0–M6 close only when every box is ticked)
- Evidence behind the decisions: `docs/RESEARCH.md` (read the section you need; don't load it whole)
- Decisions: `docs/adr/`. ADRs marked "proposed — pending spike" may still be overturned by an M0 spike.

# Success Metric

A first-time user gets a usable textured mesh of a 10–50 cm object in under 10 minutes, start to finish, on a recent iPhone, offline (PRD Goal 1). This is the gate for the MVP (end of M4). Feature count and coverage % are not the measure. `Tests/MacallaUITests/LaunchSmokeTests.swift` walks this path and grows with each milestone.

**Scope freeze:** current work is M0 only (foundations and spikes). M1 onwards is deferred, not "maybe". Add a dependency only when an in-scope task needs it now, and only if it passes D6 (no GPL, AGPL or non-commercial code in the app binary).

## Layout

```
App/Sources/              SwiftUI app (iOS/iPadOS 27); UI, ARKit, RealityKit, camera only
App/Sources/Spikes/       Debug-only M0 spike screens (ADR 0002, 0003); delete each once its ADR is decided
Packages/MacallaKit/      platform-neutral logic (project bundle, splat PLY, capture maths), tested headless
Packages/CruthKit/        thin Swift wrapper over Cruth's C API; CruthCore.xcframework is built, not committed
Tests/MacallaUITests/     XCUITest smoke tests in the simulator
project.yml               XcodeGen spec; Macalla.xcodeproj is generated and git-ignored, never edit it
Signing.xcconfig          includes the git-ignored Signing.local.xcconfig for device builds
scripts/ios.sh            generate / build / run / unit / test / device / open / clean
scripts/build-cruth.sh    builds CruthCore.xcframework (iOS, simulator, macOS) from ../Cruth
scripts/check-licences.sh D6 licence guard (allow-list, licence markers, SPDX headers)
spec/                     dependencies.md (allow-list), cruth-commit (pinned Cruth commit)
spikes/                   throwaway spike work outside the app (Brush build)
docs/                     PRD, research, ADRs
notes/                    session continuity (status, TODOs, lessons)
```

## Build and test

```sh
./scripts/build-cruth.sh       # CruthCore.xcframework from ../Cruth (~20 s; ios.sh runs it if missing)
./scripts/ios.sh unit          # package unit tests on the Mac (swift test, ~1 s)
./scripts/ios.sh test          # unit tests on the Mac, then package + UI tests on an iOS 27 simulator
./scripts/ios.sh build         # app for the simulator; --release for the Release config
./scripts/ios.sh run           # build, boot, install, launch, stream logs
./scripts/ios.sh device        # connected iPhone or iPad; needs Signing.local.xcconfig
./scripts/ios.sh device -- -spike splats   # Debug build (spikes are Debug-only); results print here
bash scripts/check-licences.sh # licence guard, as CI runs it
```

- Xcode 27.1 or newer with the iOS 27 simulator runtime (`xcodebuild -downloadPlatform iOS`). The script only picks iOS 27+ simulators.
- Cruth must be checked out at `../Cruth` (or `CRUTH_DIR`). After changing Cruth, rebuild the XCFramework and update `spec/cruth-commit` once Macalla passes against it.
- **Splats are device-only:** the iOS 27.1 simulator SDK has no `GaussianSplatComponent`, so splat code is behind `#if !targetEnvironment(simulator)` and can't be covered by simulator tests. `PhotogrammetrySession` compiles in the simulator but reports unsupported.
- To change project settings, edit `project.yml` then `./scripts/ios.sh generate`.

# Testing

- Runner: Swift Testing in `Packages/*/Tests` (`./scripts/ios.sh unit` on the Mac; the app scheme runs them in the simulator too), XCTest UI tests in `Tests/MacallaUITests` (`./scripts/ios.sh test`).
- Scope a run: `swift test --filter ProjectBundleTests` inside a package; `./scripts/ios.sh test -only-testing:MacallaUITests/LaunchSmokeTests`.
- The sample bundle `Packages/MacallaKit/Tests/MacallaKitTests/Fixtures/Teapot.macalla` is the schema's reference; change it with the types.
- Depth: unit tests for every package module plus the smoke test. The smoke test is the release gate; don't chase coverage.

## Rules

- **Logic goes in MacallaKit, not the app.** Anything testable without a camera (bundle I/O, shutter novelty, quality gates, coverage maths, job specs) lives in the package with a unit test. The app target handles input, AR, rendering and files.
- **Geometry belongs to Cruth.** Decimation, remeshing, retopology, UVs, baking and print checks come from Cruth's core (D4); don't reimplement them in Swift.
- **Licences:** MIT; every new source file starts with an `SPDX-License-Identifier: MIT` comment. A new dependency goes in `spec/dependencies.md` with its licence, and must pass D6.
- **Commits:** sign off with `git commit -s` (DCO).
- **Swift 6 language mode** with strict concurrency. Fix data-race diagnostics; don't silence them with `@unchecked Sendable` or `nonisolated(unsafe)` without a comment saying why it is safe.
- **Privacy (P11):** no analytics on scan content, no network calls except to tiers the user added.

## Change Boundaries

Ask before editing these:
- `.github/` and CI configuration (when they exist)
- `spec/dependencies.md` and the licence allow-list (D6)
- `docs/PRD.md`'s binding decisions table: change only by agreement, per its own rule
- the project bundle schema (`ProjectBundle` and the types it validates): bump `ProjectManifest.currentVersion` on any breaking change
- `spec/cruth-commit`: bump only after the full test suite passes against the new Cruth commit

Keep diffs surgical: change only what the task needs; no drive-by refactors.

# Token & Context Rules

- Read the section of a large doc you need, not the whole file. `docs/RESEARCH.md` is about 28 KB.
- Don't paste build logs; filter them (`grep -E "error|warning:|BUILD|TEST"`).
- Prefer the scripts over hand-written `xcodebuild` lines; they encode the destination and paths.

# Dev & Bug-Fix Discipline

- **Foundation first:** the core interaction is seen working (simulator or device) before anything is built on it. Green tests are not done; observed behaviour is.
- **Bug fixes:** reproduce first with a failing test (MacallaKit) or a UI test step, fix, then show it passing.
- **No technical debt in critical paths:** delete old code rather than commenting it out; no parallel code paths. "TODO", "TEMPORARY" or "DEFERRED" in a critical path means stop and fix it. Any accepted deferral goes in `TECHNICAL_DEBT.md` with its cost.
- **Spikes before hard-to-reverse choices:** pre-register the decision rule in the ADR before measuring.
- Risky or wide diffs get a fresh-context review against the milestone's acceptance criteria before they are called done.

# Session continuity

- `notes/CURRENT_STATUS.md`: what works, what's broken, the next three tasks. Read it first; rewrite it at session end.
- `notes/TODOs.md`: the task board.
- `notes/lessons.md`: lessons ledger; tag the insight inline as `LESSON-{ARCH|BUG|PERF|API|UI|TEST|BUILD}-NNN`.
- `TECHNICAL_DEBT.md`: accepted deferrals, costed.

# Slash Commands

No project-local commands. The global `/start`, `/end`, `/test`, `/todos`, `/lessons` and `/release` work here.
