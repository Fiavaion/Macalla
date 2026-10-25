# Lessons ledger

Tag the insight inline at the point it happens (`LESSON-BUILD-001: …`), then add the fuller entry here. The global `/lessons` folds inline tags into this file.

## BUILD

- **LESSON-BUILD-001** (2026-10-25): Xcode 27.1 ships without the iOS 27 simulator runtime; only 26.5 was installed. With an iOS 27 deployment target nothing runs in the simulator until `xcodebuild -downloadPlatform iOS` has run. `scripts/ios.sh` refuses older runtimes with that hint.
