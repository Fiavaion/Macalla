// SPDX-License-Identifier: MIT
import Testing
@testable import CruthKit

@Suite struct GeometryDocumentTests {
    @Test func decimatesSphereToExactBudget() throws {
        let document = try GeometryDocument.sphere(levels: 4, radius: 1)
        #expect(document.triangleCount == 6 * 256 * 2)

        try document.decimate(toTriangles: 500)
        // PRD O1: within ±1% of the target.
        #expect(abs(document.triangleCount - 500) <= 5)
    }

    @Test func rejectsNonPositiveBudget() throws {
        let document = try GeometryDocument.sphere(levels: 2, radius: 1)
        #expect(throws: CruthError.self) { try document.decimate(toTriangles: -1) }
        #expect(throws: CruthError.self) { try document.decimate(toTriangles: 0) }
    }

    @Test func reportsCoreErrors() {
        #expect(throws: CruthError.self) {
            try GeometryDocument.load(path: "/nonexistent/mesh.obj")
        }
    }

    @Test func exposesCoreVersion() {
        #expect(!GeometryDocument.coreVersion.isEmpty)
    }
}
