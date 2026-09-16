//
//  RadarRouteMatrix.swift
//  RadarSDK
//
//  Copyright © 2021 Radar Labs, Inc. All rights reserved.
//

import Foundation

/// Represents routes between multiple origins and destinations.
///
/// Backs the `RadarRouteMatrix` interface declared in `RadarRouteMatrix.h` and
/// `RadarRouteMatrix+Internal.h`, so Objective-C callers are unaffected by the move to Swift.
///
/// - SeeAlso: https://radar.com/documentation/api#matrix
@objc(RadarRouteMatrix)
class RadarRouteMatrix: NSObject {

    /// Rows are origins and columns are destinations. Declared nonnull in
    /// `RadarRouteMatrix+Internal.h`, so a missing matrix is an empty one rather than nil.
    @objc public let matrix: [[RadarRouteObjc]]

    /// Keeps the hand-written Objective-C initializer working after the implementation moved to Swift.
    @objc(initWithMatrix:)
    init(matrix: [[RadarRouteObjc]]) {
        self.matrix = matrix
    }

    /// Parses the `matrix` field of a `/route/matrix` response.
    ///
    /// Rows keep their position so the indexes stay aligned with the request: a row that is not
    /// an array becomes an empty row, and an entry `RadarRoute` cannot parse is dropped. The
    /// Objective-C implementation instead raised an exception on either input, because it
    /// inserted the nil route straight into an `NSMutableArray`.
    @objc
    convenience init?(object: Any) {
        guard let rows = object as? [Any] else {
            return nil
        }

        self.init(
            matrix: rows.map { row in
                guard let col = row as? [Any] else {
                    return []
                }
                return col.compactMap { RadarRouteObjc(object: $0) }
            }
        )
    }

    /// Returns the route between the specified origin and destination, or nil if either index is
    /// out of range.
    @objc(routeBetweenOriginIndex:destinationIndex:)
    func routeBetween(originIndex: UInt, destinationIndex: UInt) -> RadarRouteObjc? {
        guard originIndex < UInt(matrix.count) else {
            return nil
        }

        let routes = matrix[Int(originIndex)]

        guard destinationIndex < UInt(routes.count) else {
            return nil
        }

        return routes[Int(destinationIndex)]
    }

    @objc
    func arrayValue() -> [[[String: Any]]] {
        matrix.map { routes in routes.map { $0.dictionaryValue() } }
    }
}
