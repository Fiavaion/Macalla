// SPDX-License-Identifier: MIT
import CruthCore

/// A mesh owned by Cruth's core. Operations run synchronously on the caller's
/// thread and can take seconds on dense meshes, so call them off the main actor.
public final class GeometryDocument {
    private let handle: OpaquePointer

    private init(handle: OpaquePointer) {
        self.handle = handle
    }

    deinit {
        cruth_document_destroy(handle)
    }

    /// A quad sphere with 6·4^levels faces, for tests and smoke checks.
    public static func sphere(levels: Int32, radius: Float) throws(CruthError) -> GeometryDocument {
        var document: OpaquePointer?
        try check(cruth_document_create_sphere(levels, radius, &document))
        return GeometryDocument(handle: document!)
    }

    /// Loads a mesh file (OBJ or PLY, whatever Cruth's `mesh_io` reads).
    public static func load(path: String) throws(CruthError) -> GeometryDocument {
        var document: OpaquePointer?
        try check(cruth_document_load(path, &document))
        return GeometryDocument(handle: document!)
    }

    public var vertexCount: Int { cruth_document_vertex_count(handle) }
    public var triangleCount: Int { cruth_document_triangle_count(handle) }

    /// Quadric edge-collapse decimation to a triangle budget (PRD O1).
    public func decimate(toTriangles target: Int) throws(CruthError) {
        guard target > 0 else { throw CruthError(status: "invalid argument", message: "triangle budget must be positive, got \(target)") }
        try Self.check(cruth_document_decimate(handle, UInt64(target)))
    }

    public static var coreVersion: String { String(cString: cruth_version()) }

    private static func check(_ status: CruthStatus) throws(CruthError) {
        guard status != CRUTH_OK else { return }
        throw CruthError(
            status: String(cString: cruth_status_string(status)),
            message: String(cString: cruth_last_error())
        )
    }
}

public struct CruthError: Error, Equatable, CustomStringConvertible {
    public let status: String
    public let message: String

    public var description: String { message.isEmpty ? status : "\(status): \(message)" }
}
