//
//  RadarSDKTrackingTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import Testing

@testable import RadarSDK

/// Counts completion handler calls, which the SDK may make from any thread.
private final class CallbackCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    func increment() -> Int {
        lock.lock()
        defer { lock.unlock() }
        count += 1
        return count
    }
}

extension RadarSerializedTests {
    @Suite(.serialized)
    @MainActor
    struct RadarSDKTrackingTests {
        private let fixture = RadarSDKTestFixture()

        /// Calls `getLocation`, then runs `afterCall` before waiting, like the Objective-C tests did.
        private func getLocation(afterCall: () -> Void = {}) async -> (RadarStatus, CLLocation?) {
            await awaitCompletion { resume in
                Radar.getLocation { status, location, _ in
                    resume((status, location))
                }
                afterCall()
            }
        }

        /// Calls `trackOnce`, then runs `afterCall` before waiting, like the Objective-C tests did.
        private func trackOnce(
            location: CLLocation? = nil,
            afterCall: () -> Void = {}
        ) async -> (RadarStatus, CLLocation?, [RadarEvent]?, RadarUser?) {  // swiftlint:disable:this large_tuple
            await awaitCompletion { resume in
                let completion: @Sendable (RadarStatus, CLLocation?, [RadarEvent]?, RadarUser?) -> Void = { status, location, events, user in
                    resume((status, location, events, user))
                }
                if let location {
                    Radar.trackOnce(location: location, completionHandler: completion)
                } else {
                    Radar.trackOnce(completionHandler: completion)
                }
                afterCall()
            }
        }

        private func expectStartTracking(_ options: RadarTrackingOptions, sourceLocation: SourceLocation = #_sourceLocation) {
            fixture.permissionsHelperMock.mockLocationAuthorizationStatus = .authorizedWhenInUse

            Radar.stopTracking()
            Radar.startTracking(trackingOptions: options)

            #expect(Radar.getTrackingOptions() == options, sourceLocation: sourceLocation)
            #expect(Radar.isTracking(), sourceLocation: sourceLocation)
        }

        // MARK: - getLocation

        @Test("getLocation fails without location permission")
        func getLocationErrorPermissions() async {
            fixture.permissionsHelperMock.mockLocationAuthorizationStatus = .notDetermined
            fixture.locationManagerMock.mockLocation = nil

            let (status, _) = await getLocation()

            #expect(status == .errorPermissions)
        }

        @Test("getLocation fails when no location arrives")
        func getLocationErrorLocation() async {
            fixture.permissionsHelperMock.mockLocationAuthorizationStatus = .authorizedWhenInUse
            fixture.locationManagerMock.mockLocation = nil

            let (status, _) = await getLocation { fixture.simulateLocationTimeout() }

            #expect(status == .errorLocation)
        }

        @Test("getLocation returns the device location")
        func getLocationSuccess() async {
            fixture.permissionsHelperMock.mockLocationAuthorizationStatus = .authorizedWhenInUse
            fixture.locationManagerMock.mockLocation = RadarSDKTestResources.manhattanLocation()

            let (status, location) = await getLocation()

            #expect(status == .success)
            #expect(location == fixture.locationManagerMock.mockLocation)
        }

        // MARK: - trackOnce

        @Test("trackOnce fails without location permission")
        func trackOnceErrorPermissions() async {
            fixture.permissionsHelperMock.mockLocationAuthorizationStatus = .notDetermined
            fixture.locationManagerMock.mockLocation = nil

            let (status, _, _, _) = await trackOnce()

            #expect(status == .errorPermissions)
        }

        @Test("trackOnce fails when no location arrives")
        func trackOnceErrorLocation() async {
            fixture.permissionsHelperMock.mockLocationAuthorizationStatus = .authorizedWhenInUse
            fixture.locationManagerMock.mockLocation = nil

            let (status, _, _, _) = await trackOnce { fixture.simulateLocationTimeout() }

            #expect(status == .errorLocation)
        }

        @Test("trackOnce returns the parsed events and user")
        func trackOnceSuccess() async throws {
            fixture.permissionsHelperMock.mockLocationAuthorizationStatus = .authorizedWhenInUse
            fixture.locationManagerMock.mockLocation = RadarSDKTestResources.manhattanLocation()
            fixture.apiHelperMock.mockStatus = .success
            fixture.apiHelperMock.mockResponse = try RadarSDKTestResources.jsonDictionary(fromResource: "track")

            let (status, location, events, user) = await trackOnce()

            #expect(status == .success)
            #expect(location == fixture.locationManagerMock.mockLocation)
            expectEventsOk(events)
            // The first event in the fixture has an altitude, so check it's parsed.
            #expect(events?.first?.location.altitude != -1)
            #expect(events?.last?.location.altitude == -1)
            expectUserOk(user)
            #expect(user?.location.altitude != -1)
        }

        @Test("trackOnce(location:) tracks without location permission")
        func trackOnceLocationSuccess() async throws {
            fixture.permissionsHelperMock.mockLocationAuthorizationStatus = .notDetermined
            fixture.apiHelperMock.mockStatus = .success
            fixture.apiHelperMock.mockResponse = try RadarSDKTestResources.jsonDictionary(fromResource: "track")

            let (status, _, events, user) = await trackOnce(location: RadarSDKTestResources.manhattanLocation())

            #expect(status == .success)
            expectEventsOk(events)
            expectUserOk(user)
        }

        // MARK: - startTracking / stopTracking

        @Test("startTracking does nothing without location permission")
        func startTrackingErrorPermissions() {
            fixture.permissionsHelperMock.mockLocationAuthorizationStatus = .notDetermined
            fixture.locationManagerMock.mockLocation = nil

            Radar.stopTracking()
            Radar.startTracking(trackingOptions: .presetEfficient)

            #expect(!Radar.isTracking())
        }

        @Test("startTracking stores the continuous preset")
        func startTrackingContinuous() {
            expectStartTracking(.presetContinuous)
        }

        @Test("startTracking stores the responsive preset")
        func startTrackingResponsive() {
            expectStartTracking(.presetResponsive)
        }

        @Test("startTracking stores the efficient preset")
        func startTrackingEfficient() {
            expectStartTracking(.presetEfficient)
        }

        @Test("startTracking stores custom options")
        func startTrackingCustom() {
            let options = RadarTrackingOptions.presetEfficient
            options.desiredAccuracy = .low
            let now = Date()
            options.startTrackingAfter = now
            options.stopTrackingAfter = now.addingTimeInterval(1000)
            options.syncLocations = .none
            expectStartTracking(options)
        }

        @Test("stopTracking stops tracking")
        func stopTracking() {
            Radar.stopTracking()
            #expect(!Radar.isTracking())
        }

        // MARK: - mockTracking

        // Takes at least 20 seconds: one track per step, one second apart.
        @Test("mockTracking calls back once per route coordinate")
        func mockTracking() async throws {
            fixture.permissionsHelperMock.mockLocationAuthorizationStatus = .notDetermined
            fixture.apiHelperMock.mockStatus = .success
            let routeResponse = try RadarSDKTestResources.jsonDictionary(fromResource: "route_distance")
            fixture.apiHelperMock.mockResponse = routeResponse

            // Fail the track calls so mockTracking skips flushing logs, which can take 10-20 seconds.
            // test_Radar_trackOnce covers the happy path.
            // TODO: mock the log buffer so this can take the success path without flushing.
            fixture.apiHelperMock.setMockStatus(.errorUnknown, forMethod: "https://api.radar.io/v1/track")

            let routes = try #require(routeResponse["routes"] as? [String: Any])
            let car = try #require(routes["car"] as? [String: Any])
            let geometry = try #require(car["geometry"] as? [String: Any])
            let coordinates = try #require(geometry["coordinates"] as? [Any])
            let expectedCallbacks = coordinates.count
            #expect(expectedCallbacks > 0)

            let origin = CLLocation(latitude: 40.78382, longitude: -73.97536)
            let destination = CLLocation(latitude: 40.70390, longitude: -73.98670)

            // Wait for every fixture coordinate so the final track can't leak into the next test.
            let counter = CallbackCounter()
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                Radar.mockTracking(origin: origin, destination: destination, mode: .car, steps: 20, interval: 1) { _, _, _, _ in
                    let callbacks = counter.increment()
                    print("mockTracking completed step \(callbacks)")
                    if callbacks == expectedCallbacks {
                        continuation.resume()
                    }
                }
            }
        }
    }
}
