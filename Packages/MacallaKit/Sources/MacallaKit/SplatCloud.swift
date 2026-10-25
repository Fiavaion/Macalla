// SPDX-License-Identifier: MIT
import Foundation

/// Gaussian splats as flat arrays, in the stored (pre-activation) form of the
/// standard 3DGS PLY: log scales, logit opacities, spherical-harmonic coefficients.
public struct SplatCloud: Equatable, Sendable {
    /// x, y, z per splat.
    public var positions: [Float]
    /// Log scale x, y, z per splat.
    public var scales: [Float]
    /// Unit quaternion x, y, z, w per splat (simd order; the PLY stores w first).
    public var rotations: [Float]
    /// Logit opacity per splat.
    public var opacities: [Float]
    /// Coefficient-major, RGB-interleaved: c0.r c0.g c0.b c1.r … per splat, `coefficientsPerSplat × 3` values.
    public var harmonics: [Float]
    /// Spherical-harmonic degree, 0–3.
    public var degree: Int

    public var count: Int { opacities.count }
    public var coefficientsPerSplat: Int { (degree + 1) * (degree + 1) }

    /// Degree in 0–3 and every array sized for `count` splats.
    public var isConsistent: Bool {
        (0...3).contains(degree)
            && positions.count == count * 3 && scales.count == count * 3 && rotations.count == count * 4
            && harmonics.count == count * coefficientsPerSplat * 3
    }

    public init(positions: [Float], scales: [Float], rotations: [Float], opacities: [Float], harmonics: [Float], degree: Int) {
        self.positions = positions
        self.scales = scales
        self.rotations = rotations
        self.opacities = opacities
        self.harmonics = harmonics
        self.degree = degree
    }

    /// The cloud centred on the origin and uniformly scaled so its extent fits `size` metres.
    /// Bounds come from the 1st–99th percentile per axis, so a few stray floaters don't shrink the subject.
    public func fitted(toSize size: Float) -> SplatCloud {
        guard count > 0 else { return self }
        var low = [Float](repeating: 0, count: 3), high = low
        for axis in 0..<3 {
            let values = Swift.stride(from: axis, to: positions.count, by: 3).map { positions[$0] }.sorted()
            low[axis] = values[values.count / 100]
            high[axis] = values[values.count - 1 - values.count / 100]
        }
        let extent = (0..<3).map { high[$0] - low[$0] }.max() ?? 0
        guard extent > 0 else { return self }
        let factor = size / extent
        let logFactor = log(factor)
        var result = self
        for index in positions.indices {
            let axis = index % 3
            result.positions[index] = (positions[index] - (low[axis] + high[axis]) / 2) * factor
        }
        result.scales = scales.map { $0 + logFactor }
        return result
    }

    /// Consecutive pieces of at most `maxCount` splats, in order (renderers cap splats per resource).
    public func chunks(maxCount: Int) -> [SplatCloud] {
        precondition(maxCount > 0, "chunk size must be positive")
        let perSplatSH = coefficientsPerSplat * 3
        return stride(from: 0, to: count, by: maxCount).map { start in
            let end = Swift.min(start + maxCount, count)
            return SplatCloud(
                positions: Array(positions[(start * 3)..<(end * 3)]),
                scales: Array(scales[(start * 3)..<(end * 3)]),
                rotations: Array(rotations[(start * 4)..<(end * 4)]),
                opacities: Array(opacities[start..<end]),
                harmonics: Array(harmonics[(start * perSplatSH)..<(end * perSplatSH)]),
                degree: degree
            )
        }
    }

    /// Converts a linear RGB colour in 0…1 to the degree-0 coefficient the PLY stores.
    public static func dcCoefficient(forColor value: Float) -> Float {
        (value - 0.5) / 0.282_094_79
    }

    /// A deterministic cloud of `count` small splats on a sphere shell, coloured by
    /// direction, for render benchmarks (ADR 0003) without needing a trained scan.
    public static func benchmarkSphere(count: Int, radius: Float = 0.15) -> SplatCloud {
        var cloud = SplatCloud(positions: [], scales: [], rotations: [], opacities: [], harmonics: [], degree: 0)
        cloud.positions.reserveCapacity(count * 3)
        cloud.scales.reserveCapacity(count * 3)
        cloud.rotations.reserveCapacity(count * 4)
        cloud.opacities.reserveCapacity(count)
        cloud.harmonics.reserveCapacity(count * 3)
        // Fibonacci sphere: even coverage, no randomness, so runs are comparable.
        let goldenAngle = Float.pi * (3 - Float(5).squareRoot())
        // Splats shrink as the count grows, but never below 2 mm: RealityKit drops sub-pixel splats,
        // so a 500K shell of 0.5 mm splats renders nothing at all and "measures" an empty scene.
        let splatScale = log(max(radius * 2.5 / Float(count).squareRoot(), 0.002))
        for index in 0..<count {
            let y = 1 - 2 * (Float(index) + 0.5) / Float(count)
            let ring = (1 - y * y).squareRoot()
            let theta = goldenAngle * Float(index)
            let direction = [cos(theta) * ring, y, sin(theta) * ring]
            cloud.positions += direction.map { $0 * radius }
            cloud.scales += [splatScale, splatScale, splatScale]
            cloud.rotations += [0, 0, 0, 1]
            cloud.opacities.append(2) // sigmoid(2) ≈ 0.88
            cloud.harmonics += direction.map { dcCoefficient(forColor: 0.5 + 0.45 * $0) }
        }
        return cloud
    }
}
