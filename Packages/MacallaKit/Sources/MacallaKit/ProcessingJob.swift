// SPDX-License-Identifier: MIT
import Foundation

/// `jobs/<job-id>.json`: one unit of work sent to a tier, with its spec, timings and log
/// (PRD, "Data model"). `id` is derived from `inputHash`, so resubmitting the same inputs
/// and spec finds the existing job instead of duplicating work (PRD P8).
public struct ProcessingJob: Codable, Equatable, Sendable {
    public var id: String
    public var kind: Kind
    public var tier: ProjectManifest.ProcessingTier
    /// The job spec, per kind: `derive` needs `preset` (a directory under `derived/`);
    /// `denseMesh` takes `detail`; `splat` takes `iterations`. Strings, so any tier can read them.
    public var parameters: [String: String]
    /// SHA-256 (hex) over the inputs the job reads plus `kind` and `parameters`.
    public var inputHash: String
    public var state: State
    public var submittedAt: Date
    public var startedAt: Date?
    public var finishedAt: Date?
    public var error: String?
    /// Log lines from the tier, oldest first.
    public var log: [String]

    public init(
        id: String, kind: Kind, tier: ProjectManifest.ProcessingTier, parameters: [String: String] = [:],
        inputHash: String, state: State, submittedAt: Date, startedAt: Date? = nil, finishedAt: Date? = nil,
        error: String? = nil, log: [String] = []
    ) {
        self.id = id
        self.kind = kind
        self.tier = tier
        self.parameters = parameters
        self.inputHash = inputHash
        self.state = state
        self.submittedAt = submittedAt
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.error = error
        self.log = log
    }

    public enum Kind: String, Codable, Sendable {
        case preview, denseMesh, splat, derive
    }

    public enum State: String, Codable, Sendable {
        case queued, running, succeeded, failed
    }
}
