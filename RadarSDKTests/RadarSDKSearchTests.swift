//
//  RadarSDKSearchTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import Testing

@testable import RadarSDK

extension RadarSerializedTests {
    @Suite(.serialized)
    @MainActor
    struct RadarSDKSearchTests {
        private let fixture = RadarSDKTestFixture()

        private func mockDeviceLocation() {
            fixture.permissionsHelperMock.mockLocationAuthorizationStatus = .authorizedWhenInUse
            fixture.locationManagerMock.mockLocation = RadarSDKTestResources.manhattanLocation()
        }

        private func mockNoPermission() {
            fixture.permissionsHelperMock.mockLocationAuthorizationStatus = .notDetermined
            fixture.locationManagerMock.mockLocation = nil
        }

        private func mockNoLocation() {
            fixture.permissionsHelperMock.mockLocationAuthorizationStatus = .authorizedWhenInUse
            fixture.locationManagerMock.mockLocation = nil
        }

        private func mockResponse(_ resource: String) throws {
            fixture.apiHelperMock.mockStatus = .success
            fixture.apiHelperMock.mockResponse = try RadarSDKTestResources.jsonDictionary(fromResource: resource)
        }

        // MARK: - getContext

        private func getContext(
            location: CLLocation? = nil,
            afterCall: () -> Void = {}
        ) async -> (RadarStatus, CLLocation?, RadarContext?) {  // swiftlint:disable:this large_tuple
            await awaitCompletion { resume in
                let completion: @Sendable (RadarStatus, CLLocation?, RadarContext?) -> Void = { status, location, context in
                    resume((status, location, context))
                }
                if let location {
                    Radar.getContext(location: location, completionHandler: completion)
                } else {
                    Radar.getContext(completionHandler: completion)
                }
                afterCall()
            }
        }

        @Test("getContext fails without location permission")
        func getContextErrorPermissions() async {
            mockNoPermission()
            let (status, _, _) = await getContext()
            #expect(status == .errorPermissions)
        }

        @Test("getContext fails when no location arrives")
        func getContextErrorLocation() async {
            mockNoLocation()
            let (status, _, _) = await getContext { fixture.simulateLocationTimeout() }
            #expect(status == .errorLocation)
        }

        @Test("getContext returns the context for the device location")
        func getContextSuccess() async throws {
            mockDeviceLocation()
            try mockResponse("context")

            let (status, location, context) = await getContext()

            #expect(status == .success)
            #expect(location == fixture.locationManagerMock.mockLocation)
            expectContextOk(context)
        }

        @Test("getContext(location:) works without location permission")
        func getContextLocationSuccess() async throws {
            fixture.permissionsHelperMock.mockLocationAuthorizationStatus = .notDetermined
            try mockResponse("context")

            let (status, _, context) = await getContext(location: RadarSDKTestResources.manhattanLocation())

            #expect(status == .success)
            expectContextOk(context)
        }

        // MARK: - searchPlaces

        private func searchPlacesForWalmart(afterCall: () -> Void = {}) async -> (RadarStatus, CLLocation?, [RadarPlace]?) {  // swiftlint:disable:this large_tuple
            await awaitCompletion { resume in
                Radar.searchPlaces(
                    radius: 1000, chains: ["walmart"], categories: nil, groups: nil, countryCodes: nil, limit: 100
                ) { status, location, places in
                    resume((status, location, places))
                }
                afterCall()
            }
        }

        @Test("searchPlaces fails without location permission")
        func searchPlacesErrorPermissions() async {
            mockNoPermission()
            let (status, _, _) = await searchPlacesForWalmart()
            #expect(status == .errorPermissions)
        }

        @Test("searchPlaces fails when no location arrives")
        func searchPlacesErrorLocation() async {
            mockNoLocation()
            let (status, _, _) = await searchPlacesForWalmart { fixture.simulateLocationTimeout() }
            #expect(status == .errorLocation)
        }

        @Test("searchPlaces by chain returns places")
        func searchPlacesChainsSuccess() async throws {
            mockDeviceLocation()
            try mockResponse("search_places")

            let (status, location, places) = await searchPlacesForWalmart()

            #expect(status == .success)
            #expect(location != nil)
            expectPlacesOk(places)
        }

        @Test("searchPlaces by chain and chain metadata returns the chain metadata")
        func searchPlacesChainsAndMetadataSuccess() async throws {
            mockDeviceLocation()
            try mockResponse("search_places_chain_metadata")

            let (status, location, places) = await awaitCompletion { resume in
                Radar.searchPlaces(
                    radius: 1000, chains: ["walmart"], chainMetadata: ["orderActive": "true"],
                    categories: nil, groups: nil, countryCodes: nil, limit: 100
                ) { status, location, places in
                    resume((status, location, places))
                }
            }

            #expect(status == .success)
            #expect(location != nil)
            let foundPlaces = try #require(places)
            #expect(foundPlaces.count == 2)
            #expect(foundPlaces.first?.chain?.metadata?["orderActive"] as? String == "true")
        }

        @Test("searchPlaces(near:) by category works without location permission")
        func searchPlacesNearCategoriesSuccess() async throws {
            fixture.permissionsHelperMock.mockLocationAuthorizationStatus = .notDetermined
            try mockResponse("search_places")

            let (status, location, places) = await awaitCompletion { resume in
                Radar.searchPlaces(
                    near: RadarSDKTestResources.manhattanLocation(), radius: 1000, chains: nil,
                    categories: ["restaurant"], groups: nil, countryCodes: nil, limit: 100
                ) { status, location, places in
                    resume((status, location, places))
                }
            }

            #expect(status == .success)
            #expect(location != nil)
            expectPlacesOk(places)
        }

        // MARK: - searchGeofences

        private func searchGeofencesNearDevice(afterCall: () -> Void = {}) async -> RadarStatus {
            await awaitCompletion { resume in
                Radar.searchGeofences(
                    near: nil, radius: 1000, tags: nil, metadata: nil, limit: 100, includeGeometry: false
                ) { status, _, _ in
                    resume(status)
                }
                afterCall()
            }
        }

        @Test("searchGeofences fails without location permission")
        func searchGeofencesErrorPermissions() async {
            mockNoPermission()
            #expect(await searchGeofencesNearDevice() == .errorPermissions)
        }

        @Test("searchGeofences fails when no location arrives")
        func searchGeofencesErrorLocation() async {
            mockNoLocation()
            #expect(await searchGeofencesNearDevice { fixture.simulateLocationTimeout() } == .errorLocation)
        }

        @Test("searchGeofences returns geofences with their geometry and hours")
        func searchGeofencesSuccess() async throws {
            mockDeviceLocation()
            try mockResponse("search_geofences")

            let (status, location, geofences) = await awaitCompletion { resume in
                Radar.searchGeofences { status, location, geofences in
                    resume((status, location, geofences))
                }
            }

            #expect(status == .success)
            #expect(location != nil)
            expectGeofencesOk(geofences)
            let geofence = try #require(geofences?.first)
            let geofenceDict = geofence.dictionaryValue()
            #expect(geofenceDict["geometryCenter"] != nil)
            #expect(geofenceDict["geometryRadius"] != nil)
            #expect(geofenceDict["operatingHours"] != nil)
        }
    }
}
