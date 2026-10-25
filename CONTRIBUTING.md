# Contributing to Macalla

Thanks for helping. Macalla is MIT-licensed and ships on the App Store, so a few rules keep it shippable.

## Build and test

Needs Xcode 27.1 or newer with the iOS 27 simulator runtime (`xcodebuild -downloadPlatform iOS`), XcodeGen, CMake and Ninja (`brew install xcodegen cmake ninja`).

The geometry core comes from [Cruth](https://github.com/Fiavaion/Cruth), checked out next to this repo at `../Cruth` (or set `CRUTH_DIR`) at the commit in `spec/cruth-commit`. `scripts/build-cruth.sh` builds it into `Packages/CruthKit/CruthCore.xcframework`; the other scripts run it when needed. While the Cruth repository is private, outside contributors can work on everything except CruthKit; ask for access in an issue.

```sh
./scripts/ios.sh unit          # package unit tests on the Mac (MacallaKit, CruthKit; swift test)
./scripts/ios.sh test          # unit tests on the Mac, then package and UI tests on an iOS 27 simulator
./scripts/ios.sh build         # app for the simulator; --release for the Release config
./scripts/ios.sh run           # build, boot, install, launch, stream logs
./scripts/ios.sh device        # connected iPhone or iPad; needs Signing.local.xcconfig
bash scripts/check-licences.sh # licence guard, also run in CI
```

To change project settings, edit `project.yml` then `./scripts/ios.sh generate`. `Macalla.xcodeproj` is generated; never edit it.

## Sign-off (DCO), no CLA

Every commit must carry a `Signed-off-by:` line certifying the [Developer Certificate of Origin](https://developercertificate.org/). Use `git commit -s`. If you forgot, `git rebase --signoff main` fixes a branch. CI rejects pull requests with unsigned commits. There is no contributor licence agreement.

## Licences

- Every new `.swift` and `.sh` file starts with an `SPDX-License-Identifier: MIT` comment.
- **No GPL, AGPL, LGPL or non-commercial code in the app binary** (PRD decision D6).

### Adding a dependency

1. Add it only if a task in the current milestone needs it now.
2. Add a row to [`spec/dependencies.md`](spec/dependencies.md): licence as an SPDX identifier, where it runs (`app binary`, `server only` or `build tool`), source URL, and why.
3. A dependency that runs in the app binary must use a licence on the allow-list in that file.
4. Run `bash scripts/check-licences.sh`; it must pass. CI runs it on every push.

## Architecture rules

- **Logic goes in `Packages/MacallaKit`, with tests.** Swift wrappers over Cruth's C API go in `Packages/CruthKit`. Anything testable without a camera (bundle I/O, capture maths, quality gates, job specs) lives in the package with a Swift Testing unit test. The app target in `App/` handles input, AR, rendering and files.
- **Geometry belongs to Cruth.** Decimation, remeshing, UVs, baking and print checks come from Cruth's core; don't reimplement them in Swift.
- Swift 6 language mode with strict concurrency. Fix data-race diagnostics rather than silencing them.
- Privacy: no analytics on scan content, and no network calls except to tiers the user added.
