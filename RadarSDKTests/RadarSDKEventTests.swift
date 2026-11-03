//
//  RadarSDKEventTests.swift
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
    struct RadarSDKEventTests {
        private let fixture = RadarSDKTestFixture()

        /// Mocks a track response and the given `/v1/events` response for `logConversion`.
        private func mockConversion(eventsResource: String) throws {
            fixture.apiHelperMock.mockStatus = .success
            fixture.permissionsHelperMock.mockLocationAuthorizationStatus = .authorizedWhenInUse
            fixture.locationManagerMock.mockLocation = RadarSDKTestResources.manhattanLocation()
            fixture.apiHelperMock.setMockResponse(
                try RadarSDKTestResources.jsonDictionary(fromResource: "track"),
                forMethod: "https://api.radar.io/v1/track"
            )
            fixture.apiHelperMock.setMockResponse(
                try RadarSDKTestResources.jsonDictionary(fromResource: eventsResource),
                forMethod: "https://api.radar.io/v1/events"
            )
        }

        private func logConversion(revenue: NSNumber? = nil, metadata: [String: Any]?) async -> (RadarStatus, RadarEvent?) {
            await awaitCompletion { resume in
                let completion: @Sendable (RadarStatus, RadarEvent?) -> Void = { status, event in
                    resume((status, event))
                }
                if let revenue {
                    Radar.logConversion(name: "conversion4", revenue: revenue, metadata: metadata, completionHandler: completion)
                } else {
                    Radar.logConversion(name: "conversion4", metadata: metadata, completionHandler: completion)
                }
            }
        }

        // The verification calls have no completion handler; these check they don't crash.

        @Test("acceptEventId sends without a verified place")
        func acceptEventId() throws {
            fixture.apiHelperMock.mockStatus = .success
            fixture.apiHelperMock.mockResponse = try RadarSDKTestResources.jsonDictionary(fromResource: "events_verification")
            Radar.acceptEventId("eventId", verifiedPlaceId: nil)
        }

        @Test("acceptEventId sends with a verified place")
        func acceptEventIdVerifiedPlaceId() throws {
            fixture.apiHelperMock.mockStatus = .success
            fixture.apiHelperMock.mockResponse = try RadarSDKTestResources.jsonDictionary(fromResource: "events_verification")
            Radar.acceptEventId("eventId", verifiedPlaceId: "verifiedPlaceId")
        }

        @Test("rejectEventId sends")
        func rejectEvent() throws {
            fixture.apiHelperMock.mockStatus = .success
            fixture.apiHelperMock.mockResponse = try RadarSDKTestResources.jsonDictionary(fromResource: "events_verification")
            Radar.rejectEventId("eventId")
        }

        @Test("logConversion returns the event with its metadata")
        func logConversion() async throws {
            try mockConversion(eventsResource: "conversion_event")

            let (status, event) = await logConversion(metadata: ["foo": "bar"])

            #expect(status == .success)
            let metadata = try #require(event).metadata
            #expect(metadata["foo"] as? String == "bar")
        }

        @Test("logConversion with revenue adds it to the metadata")
        func logConversionRevenue() async throws {
            try mockConversion(eventsResource: "conversion_event")

            let (status, event) = await logConversion(revenue: 0.2, metadata: ["foo": "bar"])

            #expect(status == .success)
            let metadata = try #require(event).metadata
            #expect(metadata["foo"] as? String == "bar")
            #expect(metadata["revenue"] as? Double == 0.2)
        }

        @Test("logConversion fails when the response has no event")
        func logConversionStatusOkButEventIsNilFails() async throws {
            try mockConversion(eventsResource: "conversion_event_nil_event")

            let (status, event) = await logConversion(metadata: nil)

            #expect(status == .errorServer)
            #expect(event == nil)
        }
    }
}
