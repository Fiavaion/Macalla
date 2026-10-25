// SPDX-License-Identifier: MIT
import SwiftUI

/// Launch screen: the list of scans. Empty until capture lands in M1.
struct ProjectsView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "No scans yet",
                systemImage: "cube.transparent",
                description: Text("Scans you capture will appear here.")
            )
            .accessibilityIdentifier("projects.empty")
            .navigationTitle("Macalla")
        }
    }
}

#Preview {
    ProjectsView()
}
