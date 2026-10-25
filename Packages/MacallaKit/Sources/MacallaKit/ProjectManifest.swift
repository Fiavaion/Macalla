// SPDX-License-Identifier: MIT
import Foundation

/// `manifest.json` at the root of a `.macalla` project bundle (PRD, "Data model").
/// Every processing tier reads this first, so unknown versions are rejected rather than guessed at.
public struct ProjectManifest: Codable, Equatable, Sendable {
    public static let currentVersion = 1
    public static let fileName = "manifest.json"

    public var version: Int
    public var device: String
    public var osVersion: String
    public var createdAt: Date
    /// Ordered by preference; the job router falls back down this list (PRD P7).
    public var allowedTiers: [ProcessingTier]
    public var targetPresets: [String]

    public init(
        device: String,
        osVersion: String,
        createdAt: Date,
        allowedTiers: [ProcessingTier] = [.device],
        targetPresets: [String] = []
    ) {
        self.version = Self.currentVersion
        self.device = device
        self.osVersion = osVersion
        self.createdAt = createdAt
        self.allowedTiers = allowedTiers
        self.targetPresets = targetPresets
    }

    public enum ProcessingTier: String, Codable, Sendable {
        case device, mac, server
    }

    public enum DecodingFailure: Error, Equatable {
        case unsupportedVersion(Int)
    }

    public static func decode(from data: Data) throws -> ProjectManifest {
        let manifest = try decoder.decode(ProjectManifest.self, from: data)
        guard manifest.version == currentVersion else {
            throw DecodingFailure.unsupportedVersion(manifest.version)
        }
        return manifest
    }

    public func encoded() throws -> Data {
        try Self.encoder.encode(self)
    }

    // Sorted keys and ISO 8601 dates keep manifests diffable and identical across tiers.
    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
