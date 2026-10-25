# Macalla

A free, open-source iPhone and iPad app that turns a walk around an object into a textured mesh at the polycount you choose, plus a Gaussian splat of the same capture. Every photo stays in AR where it was taken, coverage is shown live, and processing runs on your device, or on your own Mac or server if you choose. No accounts, no vendor cloud.

- Product requirements: [docs/PRD.md](docs/PRD.md)
- Research and stack rationale: [docs/RESEARCH.md](docs/RESEARCH.md)
- Decisions: [docs/adr/](docs/adr/)

## Status: M0, foundations and spikes

Nothing is usable yet. The app launches to an empty projects screen; the project bundle manifest is in place.

## Build

Needs macOS, Xcode 27.1 or newer with the iOS 27 simulator runtime, and XcodeGen (`brew install xcodegen`).

```sh
./scripts/ios.sh test    # unit tests on the Mac, then UI smoke tests in the simulator
./scripts/ios.sh run     # build and launch in the simulator
```

## Contributing

MIT licence. Sign off every commit (`git commit -s`) to certify the [Developer Certificate of Origin](https://developercertificate.org/). No GPL, AGPL or non-commercial dependencies in the app, so it can ship on the App Store.
