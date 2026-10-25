// SPDX-License-Identifier: MIT
// M0 spike for ADR 0002: does Apple's on-device PhotogrammetrySession (reduced detail)
// finish a golden-set capture in under 6 minutes with a usable textured mesh?
// Input: the photos in Documents/spike-images (copy them in with the Files app or Finder).
// Output: Documents/spike-output.usdz, opened from the Files app to judge quality.
// Debug builds only. Delete this folder once ADR 0002 is decided.
#if DEBUG
import os
import RealityKit
import SwiftUI

struct PhotogrammetrySpikeView: View {
    @State private var run = PhotogrammetryRun()

    var body: some View {
        List {
            Section("Input") {
                LabeledContent("Supported on this device", value: PhotogrammetrySession.isSupported ? "Yes" : "No")
                    .accessibilityIdentifier("spike.supported")
                LabeledContent("Images in Documents/spike-images", value: "\(run.imageCount)")
            }
            Section("Run") {
                Button(run.isRunning ? "Reconstructing…" : "Reconstruct (reduced detail)") {
                    Task { await run.start() }
                }
                .disabled(run.isRunning || run.imageCount == 0 || !PhotogrammetrySession.isSupported)
                .accessibilityIdentifier("spike.reconstruct")
                if run.isRunning {
                    ProgressView(value: run.progress)
                        .accessibilityLabel("Reconstruction progress")
                }
                ForEach(run.lines, id: \.self) { Text($0).font(.callout.monospacedDigit()) }
            }
        }
        .navigationTitle("Photogrammetry spike")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { run.countImages() }
    }
}

@MainActor @Observable
final class PhotogrammetryRun {
    private(set) var imageCount = 0
    private(set) var isRunning = false
    private(set) var progress = 0.0
    private(set) var lines: [String] = []

    private let input = URL.documentsDirectory.appending(path: "spike-images", directoryHint: .isDirectory)
    private let output = URL.documentsDirectory.appending(path: "spike-output.usdz")
    private let log = Logger(subsystem: "org.macalla.app", category: "spike.photogrammetry")

    func countImages() {
        try? FileManager.default.createDirectory(at: input, withIntermediateDirectories: true)
        let files = (try? FileManager.default.contentsOfDirectory(atPath: input.path(percentEncoded: false))) ?? []
        imageCount = files.filter { ["heic", "jpg", "jpeg", "png"].contains(($0 as NSString).pathExtension.lowercased()) }.count
    }

    func start() async {
        isRunning = true
        progress = 0
        lines = []
        defer { isRunning = false }
        try? FileManager.default.removeItem(at: output)

        let clock = ContinuousClock()
        let started = clock.now
        do {
            var configuration = PhotogrammetrySession.Configuration()
            configuration.isObjectMaskingEnabled = true
            let session = try PhotogrammetrySession(input: input, configuration: configuration)
            try session.process(requests: [.modelFile(url: output, detail: .reduced)])
            for try await event in session.outputs {
                switch event {
                case .requestProgress(_, let fraction):
                    progress = fraction
                case .requestError(_, let error):
                    report("error: \(error.localizedDescription)")
                case .requestComplete:
                    let seconds = (clock.now - started).components.seconds
                    let bytes = (try? FileManager.default.attributesOfItem(atPath: output.path(percentEncoded: false))[.size] as? Int) ?? 0
                    report("ADR-0002 RESULT \(deviceModel()): \(imageCount) images, \(seconds) s, "
                        + "\(ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)) USDZ, "
                        + "thermal \(ProcessInfo.processInfo.thermalState.rawValue)")
                    report("Open Documents/spike-output.usdz in Files to judge quality.")
                case .processingComplete:
                    progress = 1
                default:
                    break
                }
            }
        } catch {
            report("error: \(error.localizedDescription)")
        }
    }

    private func report(_ line: String) {
        lines.append(line)
        // stdout reaches the terminal through `ios.sh device` (devicectl --console).
        print(line)
        log.notice("\(line, privacy: .public)")
    }

    private func deviceModel() -> String {
        var info = utsname()
        uname(&info)
        return withUnsafeBytes(of: &info.machine) { String(decoding: $0.prefix { $0 != 0 }, as: UTF8.self) }
    }
}
#endif
