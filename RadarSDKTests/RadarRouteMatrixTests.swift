//
//  RadarRouteMatrixTests.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

// A route payload shaped like an entry of the `/route/matrix` response.
private func routeObject(distance: Double) -> [String: Any] {
    [
        "distance": ["value": distance, "text": "\(distance) m"],
        "duration": ["value": distance / 100, "text": "\(distance / 100) min"],
        "geometry": [
            "type": "LineString",
            "coordinates": [[-87.656036, 41.947746], [-87.657, 41.948]],
        ],
    ]
}

// Two origins by two destinations, the shape `Radar.getMatrix` requests.
private func matrixObject() -> [[[String: Any]]] {
    [
        [routeObject(distance: 100), routeObject(distance: 200)],
        [routeObject(distance: 300), routeObject(distance: 400)],
    ]
}

private func makeRoute(distance: Double) -> RadarRouteObjc {
    RadarRouteObjc(
        route: RadarRoute(
            distance: RadarRoute.Distance(value: distance, text: "\(distance) m"),
            duration: RadarRoute.Duration(value: 1, text: "1 min"),
            geometry: nil
        )
    )
}

@Suite
struct RadarRouteMatrixTests {

    // MARK: - initWithMatrix:
    @Test
    func storesTheMatrixItWasGiven() {
        let matrix = RadarRouteMatrix(matrix: [[makeRoute(distance: 100)], [makeRoute(distance: 200)]])

        #expect(matrix.matrix.count == 2)
        #expect(matrix.matrix[0][0].distance.value == 100)
        #expect(matrix.matrix[1][0].distance.value == 200)
    }

    // MARK: - initWithObject:
    @Test
    func parsesFullMatrix() throws {
        let matrix = try #require(RadarRouteMatrix(object: matrixObject()))

        #expect(matrix.matrix.count == 2)
        #expect(matrix.matrix[0].count == 2)
        #expect(matrix.matrix[1].count == 2)
        #expect(matrix.matrix[0][0].distance.value == 100)
        #expect(matrix.matrix[0][1].distance.value == 200)
        #expect(matrix.matrix[1][0].distance.value == 300)
        #expect(matrix.matrix[1][1].distance.value == 400)
        #expect(matrix.matrix[0][0].duration.value == 1)
        #expect(matrix.matrix[0][0].geometry?.coordinates.count == 2)
    }

    @Test
    func rejectsNonArray() {
        #expect(RadarRouteMatrix(object: "not an array") == nil)
        #expect(RadarRouteMatrix(object: ["matrix": []]) == nil)
        #expect(RadarRouteMatrix(object: NSNull()) == nil)
    }

    // `RadarAPIClient` treats a nil matrix as a server error, so an empty `matrix` field has to
    // keep parsing into an empty — not nil — matrix the way the Objective-C version did.
    @Test
    func emptyArrayParsesIntoAnEmptyMatrix() throws {
        let matrix = try #require(RadarRouteMatrix(object: [Any]()))
        #expect(matrix.matrix.isEmpty)
        #expect(matrix.arrayValue().isEmpty)
        #expect(matrix.routeBetween(originIndex: 0, destinationIndex: 0) == nil)
    }

    @Test
    func rowsOfDifferentLengthsAreKept() throws {
        let matrix = try #require(
            RadarRouteMatrix(object: [[routeObject(distance: 100)], [], [routeObject(distance: 200), routeObject(distance: 300)]])
        )

        #expect(matrix.matrix.count == 3)
        #expect(matrix.matrix.map(\.count) == [1, 0, 2])
        #expect(matrix.matrix[2][1].distance.value == 300)
    }

    // The Objective-C implementation raised an exception here, because it inserted the nil route
    // that `-[RadarRoute initWithObject:]` returns straight into an `NSMutableArray`.
    @Test
    func dropsEntriesThatCannotBeParsed() throws {
        let matrix = try #require(
            RadarRouteMatrix(object: [[routeObject(distance: 100), ["distance": ["text": "no value"]], "not a route"]])
        )

        #expect(matrix.matrix.count == 1)
        #expect(matrix.matrix[0].count == 1)
        #expect(matrix.matrix[0][0].distance.value == 100)
    }

    // A row that is not an array also raised in Objective-C. Keeping it as an empty row means the
    // remaining origin indexes still line up with the request.
    @Test
    func replacesNonArrayRowsWithEmptyRowsAndKeepsOrder() throws {
        let matrix = try #require(RadarRouteMatrix(object: [[routeObject(distance: 100)], "not a row", [routeObject(distance: 200)]]))

        #expect(matrix.matrix.count == 3)
        #expect(matrix.matrix[1].isEmpty)
        #expect(matrix.routeBetween(originIndex: 0, destinationIndex: 0)?.distance.value == 100)
        #expect(matrix.routeBetween(originIndex: 1, destinationIndex: 0) == nil)
        #expect(matrix.routeBetween(originIndex: 2, destinationIndex: 0)?.distance.value == 200)
    }

    // MARK: - routeBetweenOriginIndex:destinationIndex:
    @Test
    func returnsTheRouteAtTheRequestedIndexes() throws {
        let matrix = try #require(RadarRouteMatrix(object: matrixObject()))

        #expect(matrix.routeBetween(originIndex: 0, destinationIndex: 0)?.distance.value == 100)
        #expect(matrix.routeBetween(originIndex: 0, destinationIndex: 1)?.distance.value == 200)
        #expect(matrix.routeBetween(originIndex: 1, destinationIndex: 0)?.distance.value == 300)
        #expect(matrix.routeBetween(originIndex: 1, destinationIndex: 1)?.distance.value == 400)
    }

    @Test
    func returnsNilForOutOfRangeIndexes() throws {
        let matrix = try #require(RadarRouteMatrix(object: matrixObject()))

        #expect(matrix.routeBetween(originIndex: 2, destinationIndex: 0) == nil)
        #expect(matrix.routeBetween(originIndex: 0, destinationIndex: 2) == nil)
        #expect(matrix.routeBetween(originIndex: UInt.max, destinationIndex: UInt.max) == nil)
    }

    // MARK: - arrayValue
    @Test
    func arrayValueMirrorsTheMatrixShape() throws {
        let matrix = try #require(RadarRouteMatrix(object: matrixObject()))
        let array = matrix.arrayValue()

        #expect(array.count == 2)
        #expect(array[0].count == 2)
        #expect(array[1].count == 2)

        let first = array[0][0]
        #expect((first["distance"] as? [String: Any])?["value"] as? Double == 100)
        #expect((first["duration"] as? [String: Any])?["text"] as? String == "1.0 min")
        let geometry = try #require(first["geometry"] as? [String: Any])
        #expect(geometry["type"] as? String == "LineString")
        #expect(geometry["coordinates"] as? [[Double]] == [[-87.656036, 41.947746], [-87.657, 41.948]])

        #expect((array[1][1]["distance"] as? [String: Any])?["value"] as? Double == 400)
    }

    @Test
    func arrayValueRoundTripsBackIntoAMatrix() throws {
        let original = try #require(RadarRouteMatrix(object: matrixObject()))
        let reparsed = try #require(RadarRouteMatrix(object: original.arrayValue()))

        #expect(reparsed.matrix.count == original.matrix.count)
        #expect(reparsed.matrix[0].map(\.distance.value) == original.matrix[0].map(\.distance.value))
        #expect(reparsed.matrix[1].map(\.duration.text) == original.matrix[1].map(\.duration.text))
        #expect(reparsed.matrix[0][0].geometry?.coordinates.count == 2)
    }

    @Test
    func arrayValueBridgesToTheNestedNSArrayTheHeaderPromises() throws {
        let matrix = try #require(RadarRouteMatrix(object: matrixObject()))
        let bridged = matrix.arrayValue() as NSArray

        let rows = try #require(bridged as? [[[String: Any]]])
        #expect(rows.count == 2)
        #expect(bridged.firstObject is NSArray)
        #expect((bridged.firstObject as? NSArray)?.firstObject is NSDictionary)
    }

    // MARK: - Objective-C compatibility
    @Test
    func objcRuntimeNameResolvesToTheSwiftClass() {
        #expect(NSClassFromString("RadarRouteMatrix") == RadarRouteMatrix.self)
    }

    // Every selector `RadarRouteMatrix.h` and `RadarRouteMatrix+Internal.h` promise. A missing one
    // is an unrecognized-selector crash at runtime, not a compile error, since Objective-C callers
    // only see the headers.
    @Test
    func objcHeaderContractIsImplemented() throws {
        let cls = try #require(NSClassFromString("RadarRouteMatrix") as? NSObject.Type)

        for selector in ["initWithObject:", "initWithMatrix:", "matrix", "routeBetweenOriginIndex:destinationIndex:", "arrayValue"] {
            #expect(
                cls.instancesRespond(to: NSSelectorFromString(selector)),
                "-[RadarRouteMatrix \(selector)] is declared in a header but not implemented"
            )
        }
    }

    // `RadarAPIClient.m` calls `-initWithObject:` through the runtime, so drive the same path an
    // Objective-C caller takes rather than the Swift initializer.
    @Test
    func objcAllocInitWithObjectParsesTheMatrix() throws {
        let cls = try #require(NSClassFromString("RadarRouteMatrix") as? NSObject.Type)
        let allocated = try #require((cls as AnyObject).perform(NSSelectorFromString("alloc"))?.takeUnretainedValue())

        let initialized = allocated.perform(NSSelectorFromString("initWithObject:"), with: matrixObject())?.takeRetainedValue()
        let matrix = try #require(initialized as? RadarRouteMatrix)

        #expect(matrix.matrix.count == 2)
        #expect(matrix.routeBetween(originIndex: 1, destinationIndex: 1)?.distance.value == 400)
    }

    @Test
    func objcInitWithObjectReturnsNilForNonArray() throws {
        let cls = try #require(NSClassFromString("RadarRouteMatrix") as? NSObject.Type)
        let allocated = try #require((cls as AnyObject).perform(NSSelectorFromString("alloc"))?.takeUnretainedValue())

        let initialized = allocated.perform(NSSelectorFromString("initWithObject:"), with: "not an array")?.takeRetainedValue()
        #expect(initialized == nil)
    }

    // `matrix` is typed `NSArray<NSArray<RadarRoute *> *> *` in `RadarRouteMatrix+Internal.h`, so
    // KVC has to hand back nested arrays of the `RadarRoute` runtime class.
    @Test
    func objcMatrixPropertyBridgesToNestedArraysOfRadarRoute() throws {
        let matrix = try #require(RadarRouteMatrix(object: matrixObject()))
        let rows = try #require(matrix.value(forKey: "matrix") as? [[AnyObject]])

        #expect(rows.count == 2)
        let route = try #require(rows[0][0] as? NSObject)
        #expect(type(of: route) == NSClassFromString("RadarRoute"))
        #expect(route.value(forKeyPath: "distance.value") as? Double == 100)
    }
}
