//
//  RadarRouteMatrixTests.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

// A route payload shaped like one cell of the `/route/matrix` API response.
private func routeObject(distance: Double, withGeometry: Bool = false) -> [String: Any] {
    var route: [String: Any] = [
        "distance": ["value": distance, "text": "\(distance) m"],
        "duration": ["value": distance / 100, "text": "\(distance / 100) min"],
    ]
    if withGeometry {
        route["geometry"] = [
            "type": "LineString",
            "coordinates": [[-87.656036, 41.947746], [-87.657, 41.948]],
        ]
    }
    return route
}

// Two origins by three destinations, with distances 11...13 and 21...23.
private func matrixObject() -> [[[String: Any]]] {
    [
        [routeObject(distance: 11), routeObject(distance: 12), routeObject(distance: 13)],
        [routeObject(distance: 21), routeObject(distance: 22), routeObject(distance: 23, withGeometry: true)],
    ]
}

@Suite
struct RadarRouteMatrixTests {

    // MARK: - initWithObject:

    @Test
    func parsesRowsAndColumnsInOrder() throws {
        let matrix = try #require(RadarRouteMatrix(object: matrixObject()))

        #expect(matrix.matrix.count == 2)
        #expect(matrix.matrix.map(\.count) == [3, 3])
        #expect(matrix.matrix[0].map(\.distance.value) == [11, 12, 13])
        #expect(matrix.matrix[1].map(\.distance.value) == [21, 22, 23])
        #expect(matrix.matrix[1][2].geometry.coordinates?.count == 2)
    }

    @Test
    func parsesFoundationArrays() throws {
        let object = NSArray(array: matrixObject().map { NSArray(array: $0) })
        let matrix = try #require(RadarRouteMatrix(object: object))
        #expect(matrix.matrix.map(\.count) == [3, 3])
    }

    @Test
    func parsesEmptyMatrixAndEmptyRows() throws {
        let empty = try #require(RadarRouteMatrix(object: [Any]()))
        #expect(empty.matrix.isEmpty)
        #expect(empty.arrayValue().isEmpty)

        let emptyRow = try #require(RadarRouteMatrix(object: [[Any]()]))
        #expect(emptyRow.matrix.count == 1)
        #expect(emptyRow.matrix[0].isEmpty)
    }

    @Test
    func rejectsNonArrayObject() {
        let objects: [Any] = ["matrix", ["routes": [Any]()], NSNull(), 42]
        for object in objects {
            #expect(RadarRouteMatrix(object: object) == nil)
        }
    }

    @Test
    func rejectsRowThatIsNotAnArray() {
        let object: [Any] = [[routeObject(distance: 11)], routeObject(distance: 21)]
        #expect(RadarRouteMatrix(object: object) == nil)
    }

    @Test
    func rejectsRouteThatDoesNotParse() {
        let object: [Any] = [[routeObject(distance: 11), ["distance": "far"]]]
        #expect(RadarRouteMatrix(object: object) == nil)
    }

    // MARK: - routeBetween(originIndex:destinationIndex:)

    @Test
    func returnsRouteAtIndices() throws {
        let matrix = try #require(RadarRouteMatrix(object: matrixObject()))

        #expect(matrix.routeBetween(originIndex: 0, destinationIndex: 0)?.distance.value == 11)
        #expect(matrix.routeBetween(originIndex: 0, destinationIndex: 2)?.distance.value == 13)
        #expect(matrix.routeBetween(originIndex: 1, destinationIndex: 1)?.distance.value == 22)
    }

    @Test
    func returnsNilForOutOfRangeIndices() throws {
        let matrix = try #require(RadarRouteMatrix(object: matrixObject()))

        #expect(matrix.routeBetween(originIndex: 2, destinationIndex: 0) == nil)
        #expect(matrix.routeBetween(originIndex: 0, destinationIndex: 3) == nil)
        #expect(matrix.routeBetween(originIndex: -1, destinationIndex: 0) == nil)
        #expect(matrix.routeBetween(originIndex: 0, destinationIndex: -1) == nil)
        #expect(RadarRouteMatrix().routeBetween(originIndex: 0, destinationIndex: 0) == nil)
    }

    // MARK: - arrayValue

    @Test
    func arrayValueSerializesEachRouteInOrder() throws {
        let object = matrixObject()
        let matrix = try #require(RadarRouteMatrix(object: object))
        let array = matrix.arrayValue()

        #expect(array.count == 2)
        #expect(array.map(\.count) == [3, 3])
        for (row, routes) in array.enumerated() {
            for (column, route) in routes.enumerated() {
                #expect(NSDictionary(dictionary: route) == NSDictionary(dictionary: object[row][column]))
            }
        }
    }

    @Test
    func arrayValueRoundTripsThroughInitWithObject() throws {
        let matrix = try #require(RadarRouteMatrix(object: matrixObject()))
        let reparsed = try #require(RadarRouteMatrix(object: matrix.arrayValue()))
        #expect(NSArray(array: reparsed.arrayValue()) == NSArray(array: matrix.arrayValue()))
    }

    // MARK: - Objective-C compatibility

    @Test
    func keepsObjectiveCRuntimeNameAndSelectors() throws {
        #expect(NSStringFromClass(RadarRouteMatrix.self) == "RadarRouteMatrix")
        #expect(RadarRouteMatrix.instancesRespond(to: NSSelectorFromString("initWithObject:")))
        #expect(RadarRouteMatrix.instancesRespond(to: NSSelectorFromString("matrix")))
        #expect(RadarRouteMatrix.instancesRespond(to: NSSelectorFromString("routeBetweenOriginIndex:destinationIndex:")))
        #expect(RadarRouteMatrix.instancesRespond(to: NSSelectorFromString("arrayValue")))
    }

    @Test
    func plainInitBuildsEmptyMatrix() {
        let matrix = RadarRouteMatrix()
        #expect(matrix.matrix.isEmpty)
        #expect(matrix.arrayValue().isEmpty)
    }
}
