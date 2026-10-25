// SPDX-License-Identifier: MIT
import Foundation

/// A `.macalla` project bundle on disk: its fixed layout and a structural validator.
/// The layout is the contract every tier reads and writes (PRD, "Data model").
public struct ProjectBundle: Sendable {
    public static let pathExtension = "macalla"

    public let root: URL

    public init(root: URL) {
        self.root = root
    }

    public var manifest: URL { root.appending(path: ProjectManifest.fileName) }
    public var session: URL { root.appending(path: "capture/session.json") }
    public var shotsDirectory: URL { root.appending(path: "capture/shots", directoryHint: .isDirectory) }
    public var coverage: URL { root.appending(path: "capture/coverage.json") }
    public var sceneMesh: URL { root.appending(path: "capture/arkit-mesh.usdc") }
    public var denseMesh: URL { root.appending(path: "recon/dense.usdc") }
    public var splat: URL { root.appending(path: "recon/splat.ply") }
    public var refinedCameras: URL { root.appending(path: "recon/cameras.json") }
    public var derivedDirectory: URL { root.appending(path: "derived", directoryHint: .isDirectory) }
    public var jobsDirectory: URL { root.appending(path: "jobs", directoryHint: .isDirectory) }

    public func shotMetadata(_ shot: Shot) -> URL { shotsDirectory.appending(path: "\(shot.fileStem).json") }
    public func still(_ shot: Shot) -> URL { shotsDirectory.appending(path: "\(shot.fileStem).heic") }
    public func depth(_ shot: Shot) -> URL { shotsDirectory.appending(path: "\(shot.fileStem).depth.tiff") }
    public func mask(_ shot: Shot) -> URL { shotsDirectory.appending(path: "\(shot.fileStem).mask.png") }
    public func thumbnail(_ shot: Shot) -> URL { shotsDirectory.appending(path: "\(shot.fileStem).thumb.jpg") }
    public func derivedSpec(preset: String) -> URL { derivedDirectory.appending(path: "\(preset)/spec.json") }
    public func derivedMesh(preset: String) -> URL { derivedDirectory.appending(path: "\(preset)/mesh.usdc") }
    public func job(id: String) -> URL { jobsDirectory.appending(path: "\(id).json") }

    /// A problem found by `validate()`, with the bundle-relative path it concerns.
    public struct Issue: Equatable, Sendable, CustomStringConvertible {
        public let path: String
        public let problem: String
        public var description: String { "\(path): \(problem)" }
    }

    /// Checks the bundle's structure: every JSON file decodes and is internally consistent,
    /// and every file a shot claims to have exists. It does not open images or meshes.
    public func validate() -> [Issue] {
        var issues: [Issue] = []
        let files = FileManager.default

        func load<T: Decodable>(_ type: T.Type, _ url: URL, required: Bool = true) -> T? {
            guard let data = try? Data(contentsOf: url) else {
                if required { issues.append(issue(url, "missing")) }
                return nil
            }
            do {
                return try BundleJSON.decode(type, from: data)
            } catch {
                issues.append(issue(url, "does not decode: \(error)"))
                return nil
            }
        }

        func requireFile(_ url: URL, _ why: String) {
            if !files.fileExists(atPath: url.path(percentEncoded: false)) { issues.append(issue(url, "missing (\(why))")) }
        }

        if let data = try? Data(contentsOf: manifest) {
            do {
                _ = try ProjectManifest.decode(from: data)
            } catch {
                issues.append(issue(manifest, "invalid: \(error)"))
            }
        } else {
            issues.append(issue(manifest, "missing"))
        }

        let session = load(CaptureSession.self, self.session)
        if let session {
            if session.gravity.count != 3 { issues.append(issue(self.session, "gravity needs 3 values")) }
            let box = session.boundingBox
            if box.center.count != 3 || box.extents.count != 3 || box.rotation.count != 4 {
                issues.append(issue(self.session, "boundingBox needs center[3], extents[3], rotation[4]"))
            }
            if session.passes.isEmpty { issues.append(issue(self.session, "no passes")) }
        }
        let passIDs = Set(session?.passes.map(\.id) ?? [])

        let shotFiles = (try? files.contentsOfDirectory(at: shotsDirectory, includingPropertiesForKeys: nil)) ?? []
        let shotJSON = shotFiles.filter { $0.pathExtension == "json" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
        if shotJSON.isEmpty { issues.append(issue(shotsDirectory, "no shots")) }
        for url in shotJSON {
            guard let shot = load(Shot.self, url) else { continue }
            if shot.id <= 0 { issues.append(issue(url, "id must be positive")) }
            if url.lastPathComponent != "\(shot.fileStem).json" { issues.append(issue(url, "file name does not match id \(shot.id)")) }
            if shot.pose.count != 16 { issues.append(issue(url, "pose needs 16 values")) }
            if session != nil && !passIDs.contains(shot.passID) { issues.append(issue(url, "unknown pass \(shot.passID)")) }
            if (shot.status == .rejected) != (shot.rejection != nil) {
                issues.append(issue(url, "rejection reason must be set exactly when status is rejected"))
            }
            requireFile(still(shot), "still")
            requireFile(thumbnail(shot), "ghost thumbnail")
            if shot.hasDepth { requireFile(depth(shot), "hasDepth is true") }
            if shot.hasMask { requireFile(mask(shot), "hasMask is true") }
        }

        if let coverage = load(Coverage.self, coverage, required: false) {
            let (cells, overflow) = coverage.azimuthCells.multipliedReportingOverflow(by: coverage.elevationCells)
            if coverage.azimuthCells <= 0 || coverage.elevationCells <= 0 || overflow {
                issues.append(issue(self.coverage, "azimuthCells and elevationCells must be positive and small"))
            } else if coverage.cellCounts.count != cells {
                issues.append(issue(self.coverage, "cellCounts has \(coverage.cellCounts.count) values, expected \(cells)"))
            }
        }

        let presets = (try? files.contentsOfDirectory(at: derivedDirectory, includingPropertiesForKeys: nil)) ?? []
        for preset in presets where preset.hasDirectoryPath {
            _ = load(DerivedSpec.self, derivedSpec(preset: preset.lastPathComponent))
        }

        let jobs = (try? files.contentsOfDirectory(at: jobsDirectory, includingPropertiesForKeys: nil)) ?? []
        for url in jobs where url.pathExtension == "json" {
            guard let job = load(ProcessingJob.self, url) else { continue }
            if url.deletingPathExtension().lastPathComponent != job.id { issues.append(issue(url, "file name does not match id \(job.id)")) }
            if job.kind == .derive {
                if let preset = job.parameters["preset"] {
                    if !presets.contains(where: { $0.lastPathComponent == preset }) {
                        issues.append(issue(url, "preset \(preset) has no derived/\(preset)/spec.json"))
                    }
                } else {
                    issues.append(issue(url, "derive job needs a preset parameter"))
                }
            }
        }

        return issues
    }

    private func issue(_ url: URL, _ problem: String) -> Issue {
        let base = root.standardizedFileURL.path(percentEncoded: false)
        var path = url.standardizedFileURL.path(percentEncoded: false)
        if path.hasPrefix(base) { path.removeFirst(base.count) }
        return Issue(path: path.trimmingCharacters(in: CharacterSet(charactersIn: "/")), problem: problem)
    }
}
