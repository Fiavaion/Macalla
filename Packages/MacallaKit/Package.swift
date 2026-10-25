// swift-tools-version: 6.2
// SPDX-License-Identifier: MIT
// Platform-neutral logic (project bundle, capture maths, job specs). No ARKit,
// RealityKit or UIKit here, so `swift test` runs it headless on the Mac.
import PackageDescription

let package = Package(
    name: "MacallaKit",
    platforms: [.iOS("27.0"), .macOS("26.0")],
    products: [
        .library(name: "MacallaKit", targets: ["MacallaKit"]),
    ],
    targets: [
        .target(name: "MacallaKit"),
        .testTarget(name: "MacallaKitTests", dependencies: ["MacallaKit"], resources: [.copy("Fixtures")]),
    ]
)
