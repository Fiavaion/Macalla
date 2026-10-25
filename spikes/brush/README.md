# Spike: Brush on iOS (ADR 0001)

Groundwork for [ADR 0001](../../docs/adr/0001-brush-splat-training-on-device.md): build Brush's training library for iOS on Metal, and leave the on-device measurement as a single command.

**Status (2026-10-25):** builds for `aarch64-apple-ios` and `aarch64-apple-ios-sim` without patching Brush. Trains on Mac Metal through the same C entry point. The iOS Simulator can't train because its Metal lacks indirect dispatch. iPhone 16 Pro and iPad Pro M4 have not been measured yet.

## Pin

| What | Version |
|---|---|
| Brush | `1388f74c6fe0236f68ee4915564bf00e9d2e3747` (2026-10-03, "Improve viewer rendering and training efficiency (#556)") |
| burn, cubecl, wgpu fork | as locked in Brush's `Cargo.lock`. `macalla-brush-ffi/Cargo.lock` starts from that lockfile, and the same revisions were checked |
| Rust | 1.99.1 stable (Homebrew `rustup`, keg-only at `/opt/homebrew/opt/rustup/bin`) |
| Xcode | 27.1 |

## Licences (D6)

- Brush is Apache-2.0 (`LICENSE`, workspace `license = "Apache-2.0"`). Upstream runs `cargo deny` with a permissive allow-list (`deny.toml`).
- The iOS dependency graph has 600 crates (`cargo tree -p brush-c --target aarch64-apple-ios`, normal and build deps). It contains no GPL, AGPL or non-commercial crate. Almost all are MIT and/or Apache-2.0; the rest are BSD, ISC, Zlib, Unicode-3.0, BSL-1.0, CDLA-Permissive-2.0 or Unlicense.
- **MPL-2.0 (weak, file-level copyleft):** `buildid` and `colored` (through burn/cubecl), and `indent` and `option-ext` (through rerun). MPL code can ship in an MIT app as long as those files' sources stay available. Check them against the D6 allow-list in `spec/dependencies.md`.
- burn, cubecl and wgpu (Brush uses a fork, `ArthurBrussee/wgpu`, branch `fix/webgpu-errors-v30.0.1`) are MIT OR Apache-2.0.

## iOS support in Brush

Brush has no iOS target, iOS app or iOS CI. Its targets are macOS, Windows, Linux, Android and web. It does ship a C FFI crate, `apps/brush-c` (`train_and_save(dataset, options, callback, user_data)`, with a per-step progress callback). The training library is `crates/brush-process` (`create_process_with_device`), which sits on `brush-train`, `brush-render` and `brush-dataset`.

## What it took (no Brush source patched)

| # | Problem | Fix here | Upstream fix (not applied) |
|---|---|---|---|
| 1 | `rfd` 0.17 (file dialogs) has no iOS backend, and `crates/rrfd` pulls it in for every non-wasm, non-Android target. Error: `the trait bound FileDialog: AsyncFilePickerDialogImpl is not satisfied` (12 errors in `rfd`). | `rfd-ios-stub/`: a no-op crate with the four `AsyncFileDialog` calls `rrfd` makes. `macalla-brush-ffi` substitutes it through `[patch.crates-io]`. | In `crates/rrfd`, treat `target_os = "ios"` like Android. One `cfg` change in `Cargo.toml` and in `lib.rs`. |
| 2 | At runtime, `brush-c` panics: `No possible adapter … requested_backends: Backends(VULKAN), supported_backends: Backends(METAL)`. cubecl's `AutoGraphicsApi::chain()` maps only `target_os = "macos"` to Metal; every other OS gets `[Vulkan, Dx12, Gl]`. | `macalla-brush-ffi/` calls `burn_wgpu::init_setup_async::<Metal>` itself, then `brush_process::create_process_with_device`. | cubecl `crates/cubecl-wgpu/src/graphics.rs`: `any(target_os = "macos", target_os = "ios")`. |
| 3 | `strip` on the static archive turns hidden Rust symbols into duplicate globals, and the link fails. | The archive is not stripped; the app links with `-dead_strip`. | n/a |
| 4 | iOS Simulator: `Downlevel flags INDIRECT_EXECUTION are required but not supported on the device`. | None. This is a simulator limit; A17 Pro and M4 support indirect dispatch. On-device runs only. | n/a |

None of these touches Brush's licence. The stub and the wrapper are our own MIT code.

## Files

| Path | What |
|---|---|
| `macalla-brush-ffi/` | Rust staticlib exporting `macalla_brush_train(dataset, iterations, out_ply, progress, user_data)`. Metal is set explicitly. `progress(iter, total, iters_per_sec, user_data)` fires on every step. |
| `include/macalla_brush.h`, `include/module.modulemap` | C header, and the Swift module `MacallaBrush`. |
| `rfd-ios-stub/` | No-op `rfd` for iOS (problem 1). |
| `build-ios.sh` | Clones or checks out Brush at the pin, builds both iOS targets, and writes `build/MacallaBrush.xcframework` (about 550 MB unstripped). |
| `runner/` | XcodeGen spec and SwiftUI app. At launch it trains the bundled `Dataset/` once and prints `BRUSH iter …` lines and `BRUSH RESULT {json}`, which has iterations/s, wall seconds, peak `phys_footprint` and the memory limit. It also writes `Documents/brush-spike-result.json`. It requests `com.apple.developer.kernel.increased-memory-limit`. |
| `run-device.sh` | Builds the XCFramework if missing, bundles a dataset, then builds, installs and launches on the connected device with `--console`. |
| `smoke/smoke.c` | Command-line harness for the same API. It links against the macOS build to give a Mac baseline. |

`brush-src/`, `target/`, `build/` and the generated runner files are git-ignored.

## Verified on this Mac

- `./build-ios.sh`: both targets pass and the XCFramework is written.
- The runner builds for `generic/platform=iOS` (Release, Swift 6, unsigned). Executable size: 140 MB.
- `macalla-brush-ffi` built for `aarch64-apple-darwin` and linked with `smoke/smoke.c`: 1,000 iterations on Brush's one-image test dataset, exit 0, wrote a 54 KB `.ply`. That dataset is too small for the it/s figure to mean anything.

## To finish the spike on device

1. Connect and unlock the iPhone 16 Pro, trust this Mac and enable Developer Mode. `../../Signing.local.xcconfig` must set `DEVELOPMENT_TEAM`. The memory entitlement needs a paid team. If signing rejects it, delete that line from `runner/project.yml` and record that the run went without it.
2. Get the 300-shot golden capture as a Nerfstudio `transforms.json` folder (ARKit poses converted to camera-to-world matrices, plus images) or as a COLMAP folder.
3. `./run-device.sh /path/to/golden 7000`. Keep the device unlocked with the app in the foreground until `BRUSH RESULT` prints. If the console stops with no result, the process was killed; check jetsam in Settings > Privacy > Analytics.
4. Repeat on the iPad Pro M4, or set `BRUSH_DEVICE=<udid>` to pick a device. Record it/s, wall time and peak memory for both devices in the ADR. **Go** needs the iPad 7,000-iteration run under 15 minutes (≈ 7.8 it/s or better) and no memory kill on either device.

## If it fails on device

Use the ADR's no-go path: splats on Mac and server only. The same `macalla-brush-ffi` builds for `aarch64-apple-darwin` today, so the Mac companion path is already proven. Fixing a device-only failure (a Metal feature gap in cubecl kernels, or a memory blow-up) would mean upstream work in cubecl or Brush. Estimate: days to weeks, with no guarantee.

## Open points for Macalla

- **Binary size and privacy:** `brush-process` always depends on `brush-rerun` → `rerun` 0.36, which brings in Arrow, `re_analytics` and `re_auth`. That probably accounts for much of the 140 MB (not measured), and an analytics crate in the binary needs a P11 review even if it never runs. Upstream fix: make `brush-rerun` an optional feature of `brush-process`.
- Brush tracks burn's `main` branch, so every pin bump needs `build-ios.sh` re-run and the runner rebuilt.
- ADR 0001 says "ARKit poses as priors". Brush takes the poses in `transforms.json` as given; check whether it refines them.
