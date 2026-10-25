// SPDX-License-Identifier: MIT
import Foundation
import Testing
@testable import MacallaKit

@Suite struct ProjectManifestTests {
    @Test func roundTripsThroughJSON() throws {
        let manifest = ProjectManifest(
            device: "iPhone17,1",
            osVersion: "27.0",
            createdAt: Date(timeIntervalSince1970: 1_793_000_000),
            allowedTiers: [.device, .mac],
            targetPresets: ["ar-web", "game-prop"]
        )
        let decoded = try ProjectManifest.decode(from: manifest.encoded())
        #expect(decoded == manifest)
    }

    @Test func writesStableSortedKeys() throws {
        let manifest = ProjectManifest(device: "iPad16,3", osVersion: "27.0", createdAt: Date(timeIntervalSince1970: 0))
        let json = try #require(String(data: manifest.encoded(), encoding: .utf8))
        #expect(json.contains("\"createdAt\" : \"1970-01-01T00:00:00Z\""))
        #expect(json.range(of: "allowedTiers")!.lowerBound < json.range(of: "version")!.lowerBound)
    }

    @Test func rejectsUnknownVersion() {
        let json = Data("""
        {"version": 2, "device": "x", "osVersion": "27.0", "createdAt": "2026-10-25T00:00:00Z",
         "allowedTiers": ["device"], "targetPresets": []}
        """.utf8)
        #expect(throws: ProjectManifest.DecodingFailure.unsupportedVersion(2)) {
            try ProjectManifest.decode(from: json)
        }
    }
}
