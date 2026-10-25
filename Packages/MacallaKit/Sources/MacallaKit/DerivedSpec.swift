// SPDX-License-Identifier: MIT
import Foundation

/// `derived/<preset-id>/spec.json`: how a derived mesh was made from the dense one.
/// Spec plus `sourceHash` makes every derived output reproducible and cacheable (D11).
public struct DerivedSpec: Codable, Equatable, Sendable {
    public var budget: Budget
    public var style: TopologyStyle
    public var maps: [BakedMap]
    public var mapResolution: Int
    public var lodCount: Int
    /// SHA-256 of `recon/dense.usdc`, hex.
    public var sourceHash: String

    public init(budget: Budget, style: TopologyStyle, maps: [BakedMap], mapResolution: Int, lodCount: Int, sourceHash: String) {
        self.budget = budget
        self.style = style
        self.maps = maps
        self.mapResolution = mapResolution
        self.lodCount = lodCount
        self.sourceHash = sourceHash
    }

    /// Encoded as the string `"dense"` or a face count, so other tiers read it without Swift's enum layout.
    public enum Budget: Codable, Equatable, Sendable {
        case dense
        case faces(Int)

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let faces = try? container.decode(Int.self) {
                guard faces > 0 else {
                    throw DecodingError.dataCorruptedError(in: container, debugDescription: "face budget must be positive")
                }
                self = .faces(faces)
            } else if try container.decode(String.self) == "dense" {
                self = .dense
            } else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "expected \"dense\" or a face count")
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .dense: try container.encode("dense")
            case .faces(let faces): try container.encode(faces)
            }
        }
    }

    public enum TopologyStyle: String, Codable, Sendable {
        case triangles, quadDominant, allQuads
    }

    public enum BakedMap: String, Codable, Sendable {
        case color, normal, ambientOcclusion, displacement
    }
}
