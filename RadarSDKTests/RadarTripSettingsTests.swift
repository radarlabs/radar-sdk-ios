//
//  RadarTripSettingsTests.swift
//  RadarSDK
//
//  Created by Alan Charles on 8/31/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Testing

@testable import RadarSDK

extension RadarSerializedTests {
    @Suite(.serialized)
    struct RadarTripSettingsTests {

        init() {
            RadarSettings.trip = nil
        }

        @Test("RadarSettings persists multi-leg trips")
        func persistsMultiLegTrip() throws {
            #expect(RadarSettings.trip == nil)

            RadarTripIntegrationTestSupport.storeMultiLegTrip()
            defer {
                RadarSettings.trip = nil
            }

            let trip = try #require(RadarSettings.trip)
            let legs = try #require(trip.legs)

            #expect(trip._id == "trip_abc123")
            #expect(legs.count == 2)
            #expect(trip.currentLegId == "leg_001")

            RadarSettings.trip = nil
            #expect(RadarSettings.trip == nil)
        }
    }
}
