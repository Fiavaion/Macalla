// SPDX-License-Identifier: MIT
import SwiftUI

/// Launch screen: the list of scans. Empty until capture lands in M1.
struct ProjectsView: View {
    #if DEBUG
    /// `-spike splats [-splatCount N]` or `-spike photogrammetry` opens a spike at launch, for device runs from the terminal.
    @State private var path: [String] = UserDefaults.standard.string(forKey: "spike").map { [$0] } ?? []
    #else
    @State private var path: [String] = []
    #endif

    var body: some View {
        NavigationStack(path: $path) {
            ContentUnavailableView(
                "No scans yet",
                systemImage: "cube.transparent",
                description: Text("Scans you capture will appear here.")
            )
            .accessibilityIdentifier("projects.empty")
            .navigationTitle("Macalla")
            #if DEBUG
            .toolbar {
                Menu("Spikes") {
                    NavigationLink("Splat rendering (ADR 0003)", value: "splats")
                        .accessibilityIdentifier("projects.splatSpike")
                    NavigationLink("Photogrammetry (ADR 0002)", value: "photogrammetry")
                        .accessibilityIdentifier("projects.photogrammetrySpike")
                }
                .accessibilityIdentifier("projects.spikes")
            }
            .navigationDestination(for: String.self) { spike in
                if spike == "photogrammetry" {
                    PhotogrammetrySpikeView()
                } else if spike == "splats" {
                    #if targetEnvironment(simulator)
                    ContentUnavailableView(
                        "Device only",
                        systemImage: "iphone",
                        description: Text("RealityKit has no Gaussian splat API in the simulator. Run this on an iPhone or iPad.")
                    )
                    #else
                    let count = UserDefaults.standard.integer(forKey: "splatCount")
                    SplatSpikeView(splatCount: count > 0 ? count : 500_000)
                    #endif
                }
            }
            #endif
        }
    }
}

#Preview {
    ProjectsView()
}
