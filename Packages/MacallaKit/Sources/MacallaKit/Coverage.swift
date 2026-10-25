// SPDX-License-Identifier: MIT
import Foundation

/// `capture/coverage.json`: the view-sphere dome (PRD C8) and per-vertex counts
/// for the surface heat map (C9). The dome is an equal-angle grid around the box centre.
public struct Coverage: Codable, Equatable, Sendable {
    public var angleStepDegrees: Float
    public var azimuthCells: Int
    public var elevationCells: Int
    /// Kept shots per cell, row-major by elevation (bottom up), `azimuthCells × elevationCells` values.
    public var cellCounts: [Int]
    /// Kept shots seeing each vertex of `capture/arkit-mesh.usdc`, or nil without a scene mesh.
    public var vertexCounts: [Int]?

    public init(angleStepDegrees: Float, azimuthCells: Int, elevationCells: Int, cellCounts: [Int], vertexCounts: [Int]? = nil) {
        self.angleStepDegrees = angleStepDegrees
        self.azimuthCells = azimuthCells
        self.elevationCells = elevationCells
        self.cellCounts = cellCounts
        self.vertexCounts = vertexCounts
    }
}
