// SPDX-License-Identifier: MIT
import Foundation

/// `capture/session.json`: everything about the capture that is not per shot.
/// Vectors are plain arrays so non-Swift tiers (the Python server) read them directly.
public struct CaptureSession: Codable, Equatable, Sendable {
    public var boundingBox: BoundingBox
    /// Unit vector in ARKit world space, pointing down.
    public var gravity: [Float]
    public var scaleSource: ScaleSource
    public var passes: [Pass]
    public var locks: Locks

    public init(boundingBox: BoundingBox, gravity: [Float], scaleSource: ScaleSource, passes: [Pass], locks: Locks) {
        self.boundingBox = boundingBox
        self.gravity = gravity
        self.scaleSource = scaleSource
        self.passes = passes
        self.locks = locks
    }

    /// The subject box placed on a surface (PRD C1), in ARKit world space, metres.
    public struct BoundingBox: Codable, Equatable, Sendable {
        public var center: [Float]
        public var extents: [Float]
        /// Quaternion x, y, z, w; rotation about gravity only in practice.
        public var rotation: [Float]

        public init(center: [Float], extents: [Float], rotation: [Float]) {
            self.center = center
            self.extents = extents
            self.rotation = rotation
        }
    }

    public enum ScaleSource: String, Codable, Sendable {
        /// ARKit world tracking without LiDAR: metric, but drifts a few percent.
        case arkit
        case lidar
        /// A distance the user typed in (PRD O10, F4).
        case measured
    }

    /// One walk around the object; a flip starts a new pass (PRD C12, F5).
    public struct Pass: Codable, Equatable, Sendable {
        public var id: Int
        public var flipped: Bool

        public init(id: Int, flipped: Bool) {
            self.id = id
            self.flipped = flipped
        }
    }

    public struct Locks: Codable, Equatable, Sendable {
        public var exposure: Bool
        public var whiteBalance: Bool
        public var focus: Bool

        public init(exposure: Bool, whiteBalance: Bool, focus: Bool) {
            self.exposure = exposure
            self.whiteBalance = whiteBalance
            self.focus = focus
        }
    }
}
