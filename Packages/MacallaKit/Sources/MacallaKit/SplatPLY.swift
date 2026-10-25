// SPDX-License-Identifier: MIT
import Foundation

/// Reads and writes the binary little-endian PLY written by 3DGS trainers (Brush, gsplat, Inria):
/// `x y z`, optional normals, `f_dc_0…2`, `f_rest_*` (channel-major), `opacity`, `scale_0…2`, `rot_0…3` (w first).
public enum SplatPLY {
    public enum ReadError: Error, Equatable {
        case notPLY
        case unsupportedFormat(String)
        case unsupportedElement(String)
        case unsupportedProperty(String)
        case missingProperty(String)
        case invalidCount(String)
        case truncated
    }

    public enum WriteError: Error, Equatable {
        /// Array lengths disagree with `count`, or `degree` is outside 0–3.
        case inconsistentCloud
    }

    public static func read(_ data: Data) throws -> SplatCloud {
        guard let headerEnd = data.firstRange(of: Data("end_header\n".utf8)) else { throw ReadError.notPLY }
        let header = String(decoding: data[data.startIndex..<headerEnd.lowerBound], as: UTF8.self)
        let lines = header.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
        guard lines.first == "ply" else { throw ReadError.notPLY }

        // Exactly one element, `vertex`: the body is then nothing but vertex rows.
        var count: Int?
        var properties: [String] = []
        for line in lines.dropFirst() {
            let words = line.split(separator: " ").map(String.init)
            switch words.first {
            case "format":
                guard words.count >= 2, words[1] == "binary_little_endian" else { throw ReadError.unsupportedFormat(line) }
            case "element":
                guard count == nil, words.count == 3, words[1] == "vertex" else { throw ReadError.unsupportedElement(line) }
                guard let vertices = Int(words[2]), vertices >= 0 else { throw ReadError.invalidCount(line) }
                count = vertices
            case "property":
                guard count != nil, words.count == 3, words[1] == "float" else { throw ReadError.unsupportedProperty(line) }
                properties.append(words[2])
            default:
                break
            }
        }
        guard let count else { throw ReadError.missingProperty("element vertex") }

        var column: [String: Int] = [:]
        for (index, name) in properties.enumerated() { column[name] = index }
        func index(_ name: String) throws -> Int {
            guard let index = column[name] else { throw ReadError.missingProperty(name) }
            return index
        }
        let restCount = properties.filter { $0.hasPrefix("f_rest_") }.count
        let degree: Int
        switch restCount {
        case 0: degree = 0
        case 9: degree = 1
        case 24: degree = 2
        case 45: degree = 3
        default: throw ReadError.unsupportedProperty("\(restCount) f_rest values")
        }
        let restPerChannel = restCount / 3

        let position = try ["x", "y", "z"].map(index)
        let scale = try ["scale_0", "scale_1", "scale_2"].map(index)
        let rotation = try ["rot_0", "rot_1", "rot_2", "rot_3"].map(index)
        let opacity = try index("opacity")
        let dc = try ["f_dc_0", "f_dc_1", "f_dc_2"].map(index)
        let rest = try (0..<restCount).map { try index("f_rest_\($0)") }

        let stride = properties.count
        let body = data[headerEnd.upperBound...]
        // Divide rather than multiply, so a hostile vertex count can't overflow.
        guard body.count / (stride * 4) >= count else { throw ReadError.truncated }

        var cloud = SplatCloud(positions: [], scales: [], rotations: [], opacities: [], harmonics: [], degree: degree)
        cloud.positions.reserveCapacity(count * 3)
        cloud.scales.reserveCapacity(count * 3)
        cloud.rotations.reserveCapacity(count * 4)
        cloud.opacities.reserveCapacity(count)
        cloud.harmonics.reserveCapacity(count * cloud.coefficientsPerSplat * 3)

        body.withUnsafeBytes { raw in
            var row = [Float](repeating: 0, count: stride)
            for splat in 0..<count {
                row.withUnsafeMutableBytes { $0.copyMemory(from: UnsafeRawBufferPointer(rebasing: raw[(splat * stride * 4)..<((splat + 1) * stride * 4)])) }
                for i in 0..<row.count { row[i] = Float(bitPattern: UInt32(littleEndian: row[i].bitPattern)) }
                cloud.positions += position.map { row[$0] }
                cloud.scales += scale.map { row[$0] }
                let (w, x, y, z) = (row[rotation[0]], row[rotation[1]], row[rotation[2]], row[rotation[3]])
                let length = (w * w + x * x + y * y + z * z).squareRoot()
                cloud.rotations += length > 0 ? [x / length, y / length, z / length, w / length] : [0, 0, 0, 1]
                cloud.opacities.append(row[opacity])
                cloud.harmonics += dc.map { row[$0] }
                // f_rest is all red coefficients, then green, then blue; interleave to RGB per coefficient.
                for coefficient in 0..<restPerChannel {
                    for channel in 0..<3 { cloud.harmonics.append(row[rest[channel * restPerChannel + coefficient]]) }
                }
            }
        }
        return cloud
    }

    public static func write(_ cloud: SplatCloud) throws(WriteError) -> Data {
        guard cloud.isConsistent else { throw .inconsistentCloud }
        let restPerChannel = cloud.coefficientsPerSplat - 1
        var names = ["x", "y", "z", "f_dc_0", "f_dc_1", "f_dc_2"]
        names += (0..<(restPerChannel * 3)).map { "f_rest_\($0)" }
        names += ["opacity", "scale_0", "scale_1", "scale_2", "rot_0", "rot_1", "rot_2", "rot_3"]

        var header = "ply\nformat binary_little_endian 1.0\nelement vertex \(cloud.count)\n"
        for name in names { header += "property float \(name)\n" }
        header += "end_header\n"

        var values: [Float] = []
        values.reserveCapacity(cloud.count * names.count)
        let perSplat = cloud.coefficientsPerSplat * 3
        for splat in 0..<cloud.count {
            values += cloud.positions[(splat * 3)..<(splat * 3 + 3)]
            let sh = cloud.harmonics[(splat * perSplat)..<((splat + 1) * perSplat)]
            values += sh.prefix(3)
            for channel in 0..<3 {
                for coefficient in 1...max(restPerChannel, 1) where restPerChannel > 0 {
                    values.append(sh[sh.startIndex + coefficient * 3 + channel])
                }
            }
            values.append(cloud.opacities[splat])
            values += cloud.scales[(splat * 3)..<(splat * 3 + 3)]
            let r = cloud.rotations[(splat * 4)..<(splat * 4 + 4)]
            values += [r[r.startIndex + 3], r[r.startIndex], r[r.startIndex + 1], r[r.startIndex + 2]]
        }

        var data = Data(header.utf8)
        values.withUnsafeBufferPointer { buffer in
            for value in buffer {
                withUnsafeBytes(of: value.bitPattern.littleEndian) { data.append(contentsOf: $0) }
            }
        }
        return data
    }
}
