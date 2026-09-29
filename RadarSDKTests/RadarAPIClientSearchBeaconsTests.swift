//
//  RadarAPIClientSearchBeaconsTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Testing

@testable import RadarSDK

extension RadarSerializedTests {

    @Suite("RadarAPIClient searchBeacons")
    struct RadarAPIClientSearchBeaconsTests {

        private static let location = CLLocation(latitude: 43.03, longitude: -87.93)

        private static func isSearchBeacons(_ request: URLRequest) -> Bool {
            request.url?.path == "/v1/search/beacons"
        }

        @Test("searchBeacons returns beacons and meta beacon UUIDs")
        func searchBeacons_success_parsesBeaconsAndUUIDs() async throws {
            let session = MockURLSession()
            session.on(
                Self.isSearchBeacons,
                [
                    "meta": ["code": 200, "settings": ["beacons": ["uuids": ["2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6", ""]]]],
                    "beacons": [
                        [
                            "_id": "beacon-1", "type": "ibeacon", "uuid": "2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6",
                            "major": "1", "minor": "2",
                        ]
                    ],
                ],
                statusCode: 200
            )

            Radar.initialize(publishableKey: "prj_test_pk_radar_sdk_ios")
            let apiClient = RadarAPIClient(apiHelper: RadarAPIHelper(session: session))

            let response = try await apiClient.searchBeacons(near: Self.location, radius: 1000, limit: 10)

            #expect(response.beacons.map { $0.id } == ["beacon-1"])
            #expect(response.uuids == ["2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6"])
        }

        @Test("searchBeacons throws bad request on a 400 instead of returning no beacons")
        func searchBeacons_badRequest_throws() async throws {
            let session = MockURLSession()
            session.on(
                Self.isSearchBeacons,
                ["meta": ["code": 400, "error": "Bad request"]],
                statusCode: 400
            )

            Radar.initialize(publishableKey: "prj_test_pk_radar_sdk_ios")
            let apiClient = RadarAPIClient(apiHelper: RadarAPIHelper(session: session))

            let error = await #expect(throws: RadarError.self) {
                _ = try await apiClient.searchBeacons(near: Self.location, radius: 1000, limit: 10)
            }
            #expect(error?.status == RadarStatus.errorBadRequest)
        }
    }
}
