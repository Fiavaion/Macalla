// swift-tools-version: 6.2
// SPDX-License-Identifier: MIT
// Thin Swift wrapper over Cruth's C API (PRD D4). CruthCore.xcframework is built
// by scripts/build-cruth.sh from the Cruth commit pinned in spec/cruth-commit.
import PackageDescription

let package = Package(
    name: "CruthKit",
    platforms: [.iOS("27.0"), .macOS("26.0")],
    products: [
        .library(name: "CruthKit", targets: ["CruthKit"]),
    ],
    targets: [
        .binaryTarget(name: "CruthCore", path: "CruthCore.xcframework"),
        .target(name: "CruthKit", dependencies: ["CruthCore"]),
        .testTarget(name: "CruthKitTests", dependencies: ["CruthKit"]),
    ]
)
