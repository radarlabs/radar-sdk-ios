//
//  RadarTripIntegrationTestSupport.swift
//  RadarSDK
//
//  Created by Alan Charles on 8/31/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

@testable import RadarSDK

enum RadarTripIntegrationTestSupport {
    static func resetState() {
        RadarSettings.tripOptions = nil
        RadarSettings.trip = nil
        RadarSettings.previousTrackingOptions = nil
        RadarSettings.tracking = false
        RadarSettings.trackingOptions = nil
    }

    static func previousTrackingOptionsEqual(
        to options: RadarTrackingOptions
    ) -> Bool {
        RadarSettings.previousTrackingOptions?.isEqual(options) == true
    }

    static func hasPreviousTrackingOptions() -> Bool {
        RadarSettings.previousTrackingOptions != nil
    }

    static func storeMultiLegTrip() {
        RadarSettings.trip = RadarTrip(
            object: multiLegTripDictionary()
        )
    }

    static func storeMultiLegTripAndOptions() {
        storeMultiLegTrip()
        RadarSettings.tripOptions = RadarTripOptions(
            externalId: "order-456",
            destinationGeofenceTag: "store",
            destinationGeofenceExternalId: "store-1"
        )
    }

    static func configureMultiLegTripResponse() {
        let apiHelperMock = RadarAPIHelperMock()
        apiHelperMock.mockStatus = .success
        apiHelperMock.mockResponse = [
            "trip": multiLegTripDictionary(),
            "leg": RadarTripTestFixtures.leg(
                id: "leg_001",
                status: "completed",
                tag: "store",
                externalId: "store-1"
            ),
        ]
        RadarAPIClient.sharedInstance().apiHelper = apiHelperMock
    }

    private static func multiLegTripDictionary() -> [String: Any] {
        var dictionary = RadarTripTestFixtures.trip()
        dictionary["currentLeg"] = "leg_001"
        dictionary["legs"] = [
            RadarTripTestFixtures.leg(
                id: "leg_001",
                status: "started",
                tag: "store",
                externalId: "store-1"
            ),
            RadarTripTestFixtures.leg(
                id: "leg_002",
                status: "pending",
                tag: "warehouse",
                externalId: "warehouse-1"
            ),
        ]
        return dictionary
    }

    static func lastRequestWasCompletedLegUpdate() -> Bool {
        guard
            let apiHelperMock =
                RadarAPIClient.sharedInstance().apiHelper
                as? RadarAPIHelperMock
        else {
            return false
        }

        return apiHelperMock.lastMethod == "PATCH"
            && apiHelperMock.lastUrl?
                .contains(
                    "/v1/trips/trip_abc123/legs/leg_001"
                ) == true
            && apiHelperMock.lastParams?["status"] as? String
                == "completed"
    }

    static func storeTripWithoutCurrentLeg() {
        RadarSettings.trip = RadarTrip(
            object: RadarTripTestFixtures.trip()
        )
    }

    static func lastRequestWasLegReorder() -> Bool {
        guard
            let apiHelperMock =
                RadarAPIClient.sharedInstance().apiHelper
                as? RadarAPIHelperMock,
            let legIds =
                apiHelperMock.lastParams?["legs"] as? [String]
        else {
            return false
        }

        return apiHelperMock.lastMethod == "PUT"
            && apiHelperMock.lastUrl?
                .contains("/v1/trips/trip_abc123/legs")
                == true
            && legIds == ["leg_002", "leg_001"]
    }
}
