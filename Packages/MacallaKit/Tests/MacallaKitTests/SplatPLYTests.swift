// SPDX-License-Identifier: MIT
import Foundation
import Testing
@testable import MacallaKit

@Suite struct SplatPLYTests {
    @Test func roundTripsDegreeZero() throws {
        let cloud = SplatCloud.benchmarkSphere(count: 100)
        #expect(try SplatPLY.read(try SplatPLY.write(cloud)) == cloud)
    }

    @Test func roundTripsDegreeThreeWithInterleavedHarmonics() throws {
        let count = 3
        let perSplat = 16 * 3
        let cloud = SplatCloud(
            positions: (0..<(count * 3)).map(Float.init),
            scales: Array(repeating: -4, count: count * 3),
            rotations: Array([0, 0, 0, 1].map(Float.init) + [0, 1, 0, 0] + [0.6, 0, 0.8, 0]),
            opacities: [0, 1, 2],
            harmonics: (0..<(count * perSplat)).map(Float.init),
            degree: 3
        )
        let data = try SplatPLY.write(cloud)
        #expect(String(decoding: data.prefix(2000), as: UTF8.self).contains("property float f_rest_44\n"))
        #expect(try SplatPLY.read(data) == cloud)
    }

    @Test func readsChannelMajorRestAndWFirstRotation() throws {
        // One degree-1 splat written by hand in trainer layout.
        var header = "ply\nformat binary_little_endian 1.0\nelement vertex 1\n"
        let names = ["x", "y", "z", "nx", "ny", "nz", "f_dc_0", "f_dc_1", "f_dc_2"] + (0..<9).map { "f_rest_\($0)" }
            + ["opacity", "scale_0", "scale_1", "scale_2", "rot_0", "rot_1", "rot_2", "rot_3"]
        for name in names { header += "property float \(name)\n" }
        header += "end_header\n"
        // f_rest: R1 R2 R3 G1 G2 G3 B1 B2 B3 = 11 12 13 21 22 23 31 32 33; rot w=2 (unnormalised), x=y=z=0.
        let values: [Float] = [1, 2, 3, 0, 0, 0, 0.1, 0.2, 0.3, 11, 12, 13, 21, 22, 23, 31, 32, 33, 0.5, -3, -3, -3, 2, 0, 0, 0]
        var data = Data(header.utf8)
        for value in values { withUnsafeBytes(of: value.bitPattern.littleEndian) { data.append(contentsOf: $0) } }

        let cloud = try SplatPLY.read(data)
        #expect(cloud.degree == 1)
        #expect(cloud.positions == [1, 2, 3])
        #expect(cloud.harmonics == [0.1, 0.2, 0.3, 11, 21, 31, 12, 22, 32, 13, 23, 33])
        #expect(cloud.rotations == [0, 0, 0, 1])
    }

    @Test func rejectsAsciiAndTruncatedFiles() throws {
        #expect(throws: SplatPLY.ReadError.unsupportedFormat("format ascii 1.0")) {
            try SplatPLY.read(Data("ply\nformat ascii 1.0\nend_header\n".utf8))
        }
        var data = try SplatPLY.write(.benchmarkSphere(count: 4))
        data.removeLast(4)
        #expect(throws: SplatPLY.ReadError.truncated) { try SplatPLY.read(data) }
    }

    @Test func fittedCentresAndScalesPositionsAndSplatSizes() {
        var cloud = SplatCloud.benchmarkSphere(count: 1000, radius: 2)
        for index in Swift.stride(from: 0, to: cloud.positions.count, by: 3) { cloud.positions[index] += 10 }
        let fitted = cloud.fitted(toSize: 0.3)
        let xs = Swift.stride(from: 0, to: fitted.positions.count, by: 3).map { fitted.positions[$0] }
        #expect(abs((xs.max()! + xs.min()!) / 2) < 0.01)
        #expect(xs.max()! - xs.min()! < 0.32)
        // Splat sizes shrink by the same factor as positions (log scale shifted by log(factor)).
        #expect(abs(exp(fitted.scales[0]) / exp(cloud.scales[0]) - 0.3 / 4) < 0.01)
        #expect(fitted.harmonics == cloud.harmonics && fitted.rotations == cloud.rotations)
    }

    @Test func chunksPartitionTheCloudInOrder() {
        let cloud = SplatCloud.benchmarkSphere(count: 10)
        let parts = cloud.chunks(maxCount: 4)
        #expect(parts.map(\.count) == [4, 4, 2])
        #expect(parts.allSatisfy { $0.isConsistent })
        #expect(parts.flatMap(\.positions) == cloud.positions)
        #expect(parts.flatMap(\.harmonics) == cloud.harmonics)
        #expect(cloud.chunks(maxCount: 10).count == 1)
    }

    @Test func benchmarkSphereKeepsSplatsAboveTwoMillimetres() {
        let large = SplatCloud.benchmarkSphere(count: 500_000)
        #expect(large.scales.allSatisfy { exp($0) >= 0.002 - 1e-6 })
        let small = SplatCloud.benchmarkSphere(count: 2_000)
        #expect(exp(small.scales[0]) > 0.008)
    }

    @Test func benchmarkSphereHasRequestedCountAndValidColours() {
        let cloud = SplatCloud.benchmarkSphere(count: 1000)
        #expect(cloud.count == 1000 && cloud.positions.count == 3000 && cloud.harmonics.count == 3000)
        let colours = cloud.harmonics.map { 0.5 + 0.282_094_79 * $0 }
        #expect(colours.allSatisfy { (0...1).contains($0) })
    }

    @Test(arguments: [
        ("element vertex -5", SplatPLY.ReadError.invalidCount("element vertex -5")),
        ("element vertex 9223372036854775807", SplatPLY.ReadError.truncated),
        ("element face 1", SplatPLY.ReadError.unsupportedElement("element face 1")),
        ("element vertex 1\nproperty uchar x", SplatPLY.ReadError.unsupportedProperty("property uchar x")),
    ])
    func rejectsHostileHeaders(element: String, expected: SplatPLY.ReadError) {
        var header = "ply\nformat binary_little_endian 1.0\n\(element)\n"
        if !element.contains("property") {
            for name in ["x", "y", "z", "f_dc_0", "f_dc_1", "f_dc_2", "opacity", "scale_0", "scale_1", "scale_2", "rot_0", "rot_1", "rot_2", "rot_3"] {
                header += "property float \(name)\n"
            }
        }
        let data = Data((header + "end_header\n").utf8) + Data(count: 64)
        #expect(throws: expected) { try SplatPLY.read(data) }
    }

    @Test func rejectsHeaderWithoutEnd() {
        #expect(throws: SplatPLY.ReadError.notPLY) { try SplatPLY.read(Data("ply\nformat binary_little_endian 1.0\n".utf8)) }
    }

    @Test func refusesToWriteInconsistentCloud() {
        var cloud = SplatCloud.benchmarkSphere(count: 2)
        cloud.positions.removeLast()
        #expect(throws: SplatPLY.WriteError.inconsistentCloud) { try SplatPLY.write(cloud) }
        cloud = .benchmarkSphere(count: 2)
        cloud.degree = -1
        #expect(throws: SplatPLY.WriteError.inconsistentCloud) { try SplatPLY.write(cloud) }
    }
}
