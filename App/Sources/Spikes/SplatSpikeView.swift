// SPDX-License-Identifier: MIT
// M0 spike for ADR 0003: can RealityKit render a 500K-splat cloud at 30 fps on
// iPhone 13 and 60 fps on iPhone 16 Pro, in AR, sustained for 60 s?
// Debug device builds only: the iOS 27.1 simulator SDK has no Gaussian splat API.
// Delete this folder once ADR 0003 is decided.
#if DEBUG && !targetEnvironment(simulator)
import MacallaKit
import os
import RealityKit
import SwiftUI

struct SplatSpikeView: View {
    let splatCount: Int
    @State private var stats = FrameStats()
    @State private var loadError: String?

    var body: some View {
        RealityView { content in
            content.camera = .spatialTracking
            do {
                // Parsing a 500K-splat PLY takes seconds in Debug; keep it off the main actor.
                let count = splatCount
                let (cloud, source) = try await Task.detached { try Self.loadCloud(count: count) }.value
                // `-splatChunk N` splits the cloud into entities of at most N splats each
                // (RealityKit on iOS 27.1 draws nothing for one resource above 262,144 splats).
                let chunk = UserDefaults.standard.integer(forKey: "splatChunk")
                let entity = Entity()
                for part in cloud.chunks(maxCount: chunk > 0 ? chunk : cloud.count) {
                    entity.addChild(try Self.makeSplatEntity(part))
                }
                // Fixed 0.5 m in front of the camera: always in view, so every frame pays the full splat cost.
                let anchor = AnchorEntity(.camera)
                entity.position = [0, 0, -0.5]
                anchor.addChild(entity)
                // An opaque 2 cm cube at the sphere's centre: visible cube but no sphere means splats aren't drawing.
                let marker = ModelEntity(mesh: .generateBox(size: 0.02), materials: [UnlitMaterial(color: .red)])
                marker.position = entity.position
                anchor.addChild(marker)
                content.add(anchor)
                stats.describe(splats: cloud.count, degree: cloud.degree, source: source, chunk: chunk)
            } catch {
                loadError = String(describing: error)
                print("ADR-0003 ERROR \(error)")
            }
            _ = content.subscribe(to: SceneEvents.Update.self) { [stats] event in
                stats.frame(deltaTime: event.deltaTime)
            }
            _ = content.subscribe(to: GaussianSplatEvents.RenderingChanged.self) { [stats] event in
                stats.renderingChanged(status: event.renderingStatus, limited: event.isRenderingLimited)
            }
        }
        .ignoresSafeArea()
        .overlay(alignment: .top) { readout }
        .navigationTitle("Splat spike")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var readout: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(stats.summary)
            Text(stats.liveLine).monospacedDigit()
            if let result = stats.result { Text(result).bold() }
            if let loadError { Text(loadError).foregroundStyle(.red) }
            Button(stats.isMeasuring ? "Measuring…" : "Measure 60 s") { stats.startMeasuring(seconds: 60) }
                .buttonStyle(.borderedProminent)
                .disabled(stats.isMeasuring)
                .accessibilityIdentifier("spike.measure")
        }
        .font(.callout)
        .padding(12)
        .background(.regularMaterial, in: .rect(cornerRadius: 12))
        .padding()
        .accessibilityElement(children: .contain)
    }

    /// Documents/spike.ply if present (copy a trained scan in with Finder or Files), else a synthetic sphere.
    /// A spike.ply that fails to parse is an error, not a silent fallback.
    nonisolated private static func loadCloud(count: Int) throws -> (SplatCloud, String) {
        let file = URL.documentsDirectory.appending(path: "spike.ply")
        guard FileManager.default.fileExists(atPath: file.path(percentEncoded: false)) else {
            return (SplatCloud.benchmarkSphere(count: count), "synthetic sphere")
        }
        // Scans arrive in their capture's units and origin; fit them to 30 cm so they sit in view like the sphere.
        return (try SplatPLY.read(Data(contentsOf: file)).fitted(toSize: 0.3), "spike.ply")
    }

    static func makeSplatEntity(_ cloud: SplatCloud) throws -> Entity {
        func descriptor(_ values: [Float], format: MTLAttributeFormat, floatsPerSplat: Int) throws -> GaussianSplatResource.BufferDescriptor {
            let size = values.count * MemoryLayout<Float>.stride
            // RealityKit rejects buffer capacities that aren't a multiple of 16 bytes (seen at 262,145 splats).
            let buffer = try LowLevelBuffer(descriptor: .init(capacity: (size + 15) / 16 * 16))
            buffer.replaceUnsafeMutableBytes { destination in
                values.withUnsafeBytes { destination.copyMemory(from: $0) }
            }
            buffer.bytesUsed = size
            return .init(buffer: buffer, format: format, stride: floatsPerSplat * MemoryLayout<Float>.stride, offset: 0)
        }
        guard let degree = GaussianSplatResource.SphericalHarmonicDegree(rawValue: UInt8(cloud.degree)) else {
            throw SpikeError.unsupportedDegree(cloud.degree)
        }
        let buffers = try GaussianSplatResource.BufferResource(
            count: cloud.count,
            position: descriptor(cloud.positions, format: .float3, floatsPerSplat: 3),
            scale: descriptor(cloud.scales, format: .float3, floatsPerSplat: 3),
            rotation: descriptor(cloud.rotations, format: .float4, floatsPerSplat: 4),
            opacity: descriptor(cloud.opacities, format: .float, floatsPerSplat: 1),
            sphericalHarmonics: (
                descriptor(cloud.harmonics, format: .float3, floatsPerSplat: cloud.coefficientsPerSplat * 3),
                degree
            )
        )
        let resource = GaussianSplatResource(buffers)
        // The PLY stores log scales and logit opacities; RealityKit applies the activations.
        resource.scaleActivation = .exponential
        resource.opacityActivation = .sigmoid
        let entity = Entity()
        entity.components.set(GaussianSplatComponent(resource))
        return entity
    }

    enum SpikeError: Error {
        case unsupportedDegree(Int)
    }
}

/// Frame timing for the spike. Per-second samples so the result reports the worst second, not just the mean.
@MainActor @Observable
final class FrameStats {
    private(set) var summary = "Loading…"
    private(set) var liveLine = ""
    private(set) var result: String?
    private(set) var isMeasuring = false

    private var secondFrames = 0
    private var secondElapsed: TimeInterval = 0
    private var samples: [Double] = []
    private var measureUntil: TimeInterval = 0
    private var clock: TimeInterval = 0
    private var limitedSeconds = 0
    private var renderingStatus = "normal"
    private let log = Logger(subsystem: "org.macalla.app", category: "spike.splats")
    /// `-autoMeasure YES` starts the 60 s measurement after a 5 s warm-up, for unattended device runs.
    private var autoMeasurePending = UserDefaults.standard.bool(forKey: "autoMeasure")

    func describe(splats: Int, degree: Int, source: String, chunk: Int) {
        summary = "\(splats.formatted()) splats, SH degree \(degree), \(source)"
            + (chunk > 0 ? ", chunks of \(chunk.formatted())" : "")
        print("ADR-0003 \(summary)")
        log.notice("\(self.summary, privacy: .public)")
    }

    func startMeasuring(seconds: TimeInterval) {
        samples = []
        limitedSeconds = 0
        result = nil
        isMeasuring = true
        measureUntil = clock + seconds
    }

    func renderingChanged(status: GaussianSplatEvents.RenderingChanged.Status, limited: Bool) {
        renderingStatus = "\(status)\(limited ? ", limited" : "")"
        log.notice("rendering status \(self.renderingStatus, privacy: .public)")
    }

    func frame(deltaTime: TimeInterval) {
        clock += deltaTime
        if autoMeasurePending && clock >= 5 {
            autoMeasurePending = false
            startMeasuring(seconds: 60)
        }
        secondFrames += 1
        secondElapsed += deltaTime
        guard secondElapsed >= 1 else { return }
        let fps = Double(secondFrames) / secondElapsed
        secondFrames = 0
        secondElapsed = 0
        liveLine = String(format: "%.0f fps · rendering %@", fps, renderingStatus)
        guard isMeasuring else { return }
        samples.append(fps)
        if renderingStatus != "normal" { limitedSeconds += 1 }
        if clock >= measureUntil { finish() }
    }

    private func finish() {
        isMeasuring = false
        let mean = samples.reduce(0, +) / Double(max(samples.count, 1))
        let worst = samples.min() ?? 0
        let device = deviceModel()
        result = String(format: "%@: mean %.1f fps, worst second %.1f fps over %d s; %d s reduced quality",
                        device, mean, worst, samples.count, limitedSeconds)
        // stdout reaches the terminal through `ios.sh device` (devicectl --console).
        print("ADR-0003 RESULT \(summary) | \(result ?? "")")
        log.notice("ADR-0003 RESULT \(self.summary, privacy: .public) | \(self.result ?? "", privacy: .public)")
    }

    private func deviceModel() -> String {
        var info = utsname()
        uname(&info)
        return withUnsafeBytes(of: &info.machine) { String(decoding: $0.prefix { $0 != 0 }, as: UTF8.self) }
    }
}
#endif
