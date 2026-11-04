//
//  RadarSDKGeocodeTests.swift
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
    struct RadarSDKGeocodeTests {
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

        // MARK: - autocomplete / geocode

        @Test("autocomplete returns addresses")
        func autocompleteSuccess() async throws {
            try mockResponse("search_autocomplete")

            let (status, addresses) = await awaitCompletion { resume in
                Radar.autocomplete(
                    query: "brooklyn roasting", near: CLLocation(latitude: 40.78382, longitude: -73.97536),
                    layers: ["place"], limit: 10, country: "US"
                ) { status, addresses in
                    resume((status, addresses))
                }
            }

            #expect(status == .success)
            expectAddressesOk(addresses)
        }

        private func geocode(_ query: String) async -> (RadarStatus, [RadarAddress]?) {
            await awaitCompletion { resume in
                Radar.geocode(address: query) { status, addresses in
                    resume((status, addresses))
                }
            }
        }

        @Test("geocode passes through a server error")
        func geocodeError() async {
            fixture.permissionsHelperMock.mockLocationAuthorizationStatus = .authorizedWhenInUse
            fixture.apiHelperMock.mockStatus = .errorServer

            let (status, addresses) = await geocode("20 jay street brooklyn")

            #expect(status == .errorServer)
            #expect(addresses == nil)
        }

        @Test("geocode returns addresses")
        func geocodeSuccess() async throws {
            fixture.permissionsHelperMock.mockLocationAuthorizationStatus = .authorizedWhenInUse
            try mockResponse("geocode")

            let (status, addresses) = await geocode("20 jay st brooklyn")

            #expect(status == .success)
            expectAddressesOk(addresses)
        }

        // MARK: - reverseGeocode

        private func reverseGeocode(
            location: CLLocation? = nil,
            afterCall: () -> Void = {}
        ) async -> (RadarStatus, [RadarAddress]?) {
            await awaitCompletion { resume in
                let completion: @Sendable (RadarStatus, [RadarAddress]?) -> Void = { status, addresses in
                    resume((status, addresses))
                }
                if let location {
                    Radar.reverseGeocode(location: location, completionHandler: completion)
                } else {
                    Radar.reverseGeocode(completionHandler: completion)
                }
                afterCall()
            }
        }

        @Test("reverseGeocode fails without location permission")
        func reverseGeocodeErrorPermissions() async {
            mockNoPermission()

            let (status, addresses) = await reverseGeocode()

            #expect(status == .errorPermissions)
            #expect(addresses == nil)
        }

        @Test("reverseGeocode fails when no location arrives")
        func reverseGeocodeErrorLocation() async {
            mockNoLocation()

            let (status, addresses) = await reverseGeocode { fixture.simulateLocationTimeout() }

            #expect(status == .errorLocation)
            #expect(addresses == nil)
        }

        @Test("reverseGeocode returns addresses for the device location")
        func reverseGeocodeSuccess() async throws {
            mockDeviceLocation()
            try mockResponse("geocode")

            let (status, addresses) = await reverseGeocode()

            #expect(status == .success)
            expectAddressesOk(addresses)
        }

        @Test("reverseGeocode(location:) passes through a server error")
        func reverseGeocodeLocationError() async {
            fixture.permissionsHelperMock.mockLocationAuthorizationStatus = .authorizedWhenInUse
            fixture.apiHelperMock.mockStatus = .errorServer

            let (status, addresses) = await reverseGeocode(location: CLLocation(latitude: 40.78382, longitude: -73.97536))

            #expect(status == .errorServer)
            #expect(addresses == nil)
        }

        @Test("reverseGeocode(location:) returns addresses")
        func reverseGeocodeLocationSuccess() async throws {
            fixture.permissionsHelperMock.mockLocationAuthorizationStatus = .authorizedWhenInUse
            try mockResponse("geocode")

            let (status, addresses) = await reverseGeocode(location: CLLocation(latitude: 40.78382, longitude: -73.97536))

            #expect(status == .success)
            expectAddressesOk(addresses)
        }

        // MARK: - ipGeocode

        private func ipGeocode() async -> (RadarStatus, RadarAddress?, Bool, Error?) {  // swiftlint:disable:this large_tuple
            await awaitCompletion { resume in
                Radar.ipGeocode { (status: RadarStatus, address: RadarAddress?, proxy: Bool, error: Error?) in
                    resume((status, address, proxy, error))
                }
            }
        }

        @Test("ipGeocode passes through a server error")
        func ipGeocodeError() async {
            fixture.permissionsHelperMock.mockLocationAuthorizationStatus = .authorizedWhenInUse
            fixture.apiHelperMock.mockStatus = .errorServer

            let (status, address, proxy, _) = await ipGeocode()

            #expect(status == .errorServer)
            #expect(address == nil)
            #expect(!proxy)
        }

        @Test("ipGeocode returns the address and proxy flag")
        func ipGeocodeSuccess() async throws {
            fixture.permissionsHelperMock.mockLocationAuthorizationStatus = .authorizedWhenInUse
            try mockResponse("geocode_ip")

            let (status, address, proxy, error) = await ipGeocode()

            #expect(status == .success)
            expectAddressOk(address)
            #expect(address?.dma != nil)
            #expect(address?.dmaCode != nil)
            #expect(proxy)
            #expect(error == nil)
        }

        @Test("ipGeocode passes the network error to the completion handler")
        func ipGeocodeOnCompleteReceivesError() async {
            fixture.permissionsHelperMock.mockLocationAuthorizationStatus = .authorizedWhenInUse
            fixture.apiHelperMock.mockStatus = .errorNetwork
            let mockError = NSError(
                domain: NSURLErrorDomain,
                code: NSURLErrorNotConnectedToInternet,
                userInfo: [NSLocalizedDescriptionKey: "simulated network failure"]
            )
            fixture.apiHelperMock.mockError = mockError

            let (status, _, _, error) = await ipGeocode()

            #expect(status == .errorNetwork)
            #expect(error as NSError? == mockError)
        }

        // Integrators using the legacy three-argument completion handler must still get callbacks.
        @Test("ipGeocode still calls the legacy three-argument completion handler")
        func ipGeocodeLegacyThreeArgCallbackStillCalled() async {
            fixture.permissionsHelperMock.mockLocationAuthorizationStatus = .authorizedWhenInUse
            fixture.apiHelperMock.mockStatus = .errorNetwork
            fixture.apiHelperMock.mockError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)

            let status = await awaitCompletion { resume in
                Radar.ipGeocode { (status: RadarStatus, _: RadarAddress?, _: Bool) in
                    resume(status)
                }
            }

            #expect(status == .errorNetwork)
        }

        // MARK: - getDistance

        @Test("getDistance returns routes for the requested modes")
        func getDistanceSuccess() async throws {
            mockDeviceLocation()
            try mockResponse("route_distance")

            let (status, routes) = await awaitCompletion { resume in
                Radar.getDistance(
                    destination: CLLocation(latitude: 40.78382, longitude: -73.97536),
                    modes: [.foot, .car],
                    units: .imperial
                ) { status, routes in
                    resume((status, routes))
                }
            }

            #expect(status == .success)
            expectRoutesOk(routes)
        }
    }
}
