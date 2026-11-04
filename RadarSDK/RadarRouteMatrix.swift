//
//  RadarRouteMatrix.swift
//  RadarSDK
//
//  Copyright © 2021 Radar Labs, Inc. All rights reserved.
//

import Foundation

/// Represents routes between multiple origins and destinations.
///
/// - SeeAlso: https://radar.com/documentation/api#matrix
@objc(RadarRouteMatrix)
@objcMembers
public final class RadarRouteMatrix: NSObject {
    // Declared for Objective-C in RadarRouteMatrix+Internal.h.
    let matrix: [[RadarRoute]]

    override init() {
        matrix = []
        super.init()
    }

    init(matrix: [[RadarRoute]]) {
        self.matrix = matrix
        super.init()
    }

    // Keeps the Objective-C parser declared in RadarRouteMatrix+Internal.h working. A row that
    // isn't an array, or a route that doesn't parse, fails the whole matrix so the indices of
    // the remaining routes stay meaningful.
    @objc(initWithObject:)
    init?(object: Any) {
        guard let rows = object as? [Any] else {
            return nil
        }

        var matrix: [[RadarRoute]] = []
        matrix.reserveCapacity(rows.count)
        for row in rows {
            guard let columns = row as? [Any] else {
                return nil
            }
            var routes: [RadarRoute] = []
            routes.reserveCapacity(columns.count)
            for column in columns {
                guard let route = RadarRoute(object: column) else {
                    return nil
                }
                routes.append(route)
            }
            matrix.append(routes)
        }

        self.matrix = matrix
        super.init()
    }

    /// Returns the route between the specified origin and destination.
    ///
    /// - Parameters:
    ///   - originIndex: The index of the origin.
    ///   - destinationIndex: The index of the destination.
    /// - Returns: The route between the specified origin and destination.
    @objc(routeBetweenOriginIndex:destinationIndex:)
    public func routeBetween(originIndex: Int, destinationIndex: Int) -> RadarRoute? {
        guard matrix.indices.contains(originIndex) else {
            return nil
        }

        let routes = matrix[originIndex]

        guard routes.indices.contains(destinationIndex) else {
            return nil
        }

        return routes[destinationIndex]
    }

    public func arrayValue() -> [[[AnyHashable: Any]]] {
        matrix.map { routes in routes.map { $0.dictionaryValue() } }
    }
}
