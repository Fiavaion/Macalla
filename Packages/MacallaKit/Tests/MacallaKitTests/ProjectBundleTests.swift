// SPDX-License-Identifier: MIT
import Foundation
import Testing
@testable import MacallaKit

@Suite struct ProjectBundleTests {
    /// A writable copy of Fixtures/Teapot.macalla, so tests can break it.
    private func sampleCopy() throws -> ProjectBundle {
        let fixture = try #require(Bundle.module.url(forResource: "Fixtures/Teapot", withExtension: ProjectBundle.pathExtension))
        let copy = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
            .appending(path: "Teapot.\(ProjectBundle.pathExtension)")
        try FileManager.default.createDirectory(at: copy.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: fixture, to: copy)
        return ProjectBundle(root: copy)
    }

    @Test func sampleBundleIsValid() throws {
        let bundle = try sampleCopy()
        #expect(bundle.validate() == [])
    }

    @Test func sampleBundleDecodesToExpectedValues() throws {
        let bundle = try sampleCopy()
        let session = try BundleJSON.decode(CaptureSession.self, from: Data(contentsOf: bundle.session))
        #expect(session.passes.map(\.flipped) == [false, true])
        #expect(session.scaleSource == .lidar)

        let rejected = try BundleJSON.decode(Shot.self, from: Data(contentsOf: bundle.shotsDirectory.appending(path: "0002.json")))
        #expect(rejected.status == .rejected && rejected.rejection == .blur)

        let spec = try BundleJSON.decode(DerivedSpec.self, from: Data(contentsOf: bundle.derivedSpec(preset: "game-prop-5k")))
        #expect(spec.budget == .faces(5000))
        #expect(spec.style == .allQuads)
    }

    @Test func budgetEncodesAsPlainValues() throws {
        #expect(String(decoding: try BundleJSON.encode([DerivedSpec.Budget.faces(5000), .dense]), as: UTF8.self)
            .filter { !$0.isWhitespace } == #"[5000,"dense"]"#)
        #expect(throws: DecodingError.self) { try BundleJSON.decode([DerivedSpec.Budget].self, from: Data("[0]".utf8)) }
    }

    @Test func reportsMissingStillAndDeclaredMask() throws {
        let bundle = try sampleCopy()
        let shot = try BundleJSON.decode(Shot.self, from: Data(contentsOf: bundle.shotsDirectory.appending(path: "0001.json")))
        try FileManager.default.removeItem(at: bundle.still(shot))
        try FileManager.default.removeItem(at: bundle.mask(shot))
        #expect(bundle.validate().map(\.path) == ["capture/shots/0001.heic", "capture/shots/0001.mask.png"])
    }

    @Test func reportsInconsistentShot() throws {
        let bundle = try sampleCopy()
        let url = bundle.shotsDirectory.appending(path: "0001.json")
        var shot = try BundleJSON.decode(Shot.self, from: Data(contentsOf: url))
        shot.passID = 9
        shot.rejection = .motion
        try BundleJSON.encode(shot).write(to: url)
        let problems = bundle.validate().map(\.problem)
        #expect(problems.contains("unknown pass 9"))
        #expect(problems.contains("rejection reason must be set exactly when status is rejected"))
    }

    @Test func reportsWrongCoverageGrid() throws {
        let bundle = try sampleCopy()
        var coverage = try BundleJSON.decode(Coverage.self, from: Data(contentsOf: bundle.coverage))
        coverage.elevationCells = 4
        try BundleJSON.encode(coverage).write(to: bundle.coverage)
        #expect(bundle.validate().map(\.description) == ["capture/coverage.json: cellCounts has 36 values, expected 48"])
    }

    @Test func reportsMissingManifestAndUnknownVersion() throws {
        let bundle = try sampleCopy()
        var manifest = try ProjectManifest.decode(from: Data(contentsOf: bundle.manifest))
        manifest.version = 2
        try BundleJSON.encode(manifest).write(to: bundle.manifest)
        #expect(bundle.validate().first?.problem.hasPrefix("invalid") == true)

        try FileManager.default.removeItem(at: bundle.manifest)
        #expect(bundle.validate().map(\.description) == ["manifest.json: missing"])
    }

    @Test func reportsHostileCoverageGridWithoutCrashing() throws {
        let bundle = try sampleCopy()
        var coverage = try BundleJSON.decode(Coverage.self, from: Data(contentsOf: bundle.coverage))
        coverage.azimuthCells = 4_611_686_018_427_387_904
        coverage.elevationCells = 4
        try BundleJSON.encode(coverage).write(to: bundle.coverage)
        #expect(bundle.validate().map(\.problem) == ["azimuthCells and elevationCells must be positive and small"])
    }

    @Test func reportsNonPositiveShotIdAndPadsLargeIds() throws {
        let bundle = try sampleCopy()
        let url = bundle.shotsDirectory.appending(path: "0001.json")
        var shot = try BundleJSON.decode(Shot.self, from: Data(contentsOf: url))
        #expect(shot.fileStem == "0001")
        shot.id = 4_294_967_297
        #expect(shot.fileStem == "4294967297")
        shot.id = -1
        try BundleJSON.encode(shot).write(to: url)
        #expect(bundle.validate().map(\.problem).contains("id must be positive"))
    }

    @Test func reportsDeriveJobWithUnknownPreset() throws {
        let bundle = try sampleCopy()
        let url = bundle.job(id: "derive-9f2c4e1b-game-prop-5k")
        var job = try BundleJSON.decode(ProcessingJob.self, from: Data(contentsOf: url))
        #expect(job.log.count == 3)
        job.parameters = ["preset": "hero"]
        try BundleJSON.encode(job).write(to: url)
        #expect(bundle.validate().map(\.problem) == ["preset hero has no derived/hero/spec.json"])
    }
}
