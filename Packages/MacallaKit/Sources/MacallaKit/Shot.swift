// SPDX-License-Identifier: MIT
import Foundation

/// `capture/shots/NNNN.json`: one still and everything needed to reproject it,
/// score it and explain a rejection. Rejected shots are kept on disk (PRD, "Data model").
public struct Shot: Codable, Equatable, Sendable {
    public var id: Int
    public var passID: Int
    public var capturedAt: Date
    /// Camera-to-world 4×4 matrix from ARKit, column-major (16 values). Passed to every backend as a prior (D12).
    public var pose: [Float]
    public var intrinsics: Intrinsics
    public var exposure: Exposure
    public var scores: Scores
    public var status: Status
    public var rejection: Rejection?
    public var hasDepth: Bool
    public var hasMask: Bool

    public init(
        id: Int, passID: Int, capturedAt: Date, pose: [Float], intrinsics: Intrinsics, exposure: Exposure,
        scores: Scores, status: Status, rejection: Rejection? = nil, hasDepth: Bool, hasMask: Bool
    ) {
        self.id = id
        self.passID = passID
        self.capturedAt = capturedAt
        self.pose = pose
        self.intrinsics = intrinsics
        self.exposure = exposure
        self.scores = scores
        self.status = status
        self.rejection = rejection
        self.hasDepth = hasDepth
        self.hasMask = hasMask
    }

    /// Zero-padded file stem shared by the still, depth, mask and thumbnail: `0001`. Ids are positive.
    public var fileStem: String {
        let digits = String(id)
        return String(repeating: "0", count: max(0, 4 - digits.count)) + digits
    }

    /// Pinhole intrinsics in pixels of the full-resolution still.
    public struct Intrinsics: Codable, Equatable, Sendable {
        public var fx, fy, cx, cy: Float
        public var width, height: Int

        public init(fx: Float, fy: Float, cx: Float, cy: Float, width: Int, height: Int) {
            self.fx = fx
            self.fy = fy
            self.cx = cx
            self.cy = cy
            self.width = width
            self.height = height
        }
    }

    public struct Exposure: Codable, Equatable, Sendable {
        public var durationSeconds: Double
        public var iso: Float
        public var lensPosition: Float

        public init(durationSeconds: Double, iso: Float, lensPosition: Float) {
            self.durationSeconds = durationSeconds
            self.iso = iso
            self.lensPosition = lensPosition
        }
    }

    /// Quality-gate inputs (PRD C2, C3), stored so the coach (F7) can rank shots later.
    public struct Scores: Codable, Equatable, Sendable {
        /// Sharpness relative to the session's running median; 1 is median.
        public var sharpness: Float
        /// Gyro rate at capture, radians per second.
        public var motion: Float
        /// Fraction of subject pixels clipped to white.
        public var highlightClip: Float
        /// Smallest angle to any earlier kept shot, degrees.
        public var noveltyDegrees: Float

        public init(sharpness: Float, motion: Float, highlightClip: Float, noveltyDegrees: Float) {
            self.sharpness = sharpness
            self.motion = motion
            self.highlightClip = highlightClip
            self.noveltyDegrees = noveltyDegrees
        }
    }

    public enum Status: String, Codable, Sendable {
        case kept, rejected
    }

    public enum Rejection: String, Codable, Sendable {
        case blur, motion, highlights, tooClose, outOfBox, deletedByUser
    }
}
