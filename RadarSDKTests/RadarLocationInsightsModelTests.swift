//
//  RadarLocationInsightsModelTests.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

extension RadarSerializedTests {
    @Suite(.serialized)
    struct RadarLocationInsightsModelTests {

        @Test("Parses location insight event types")
        func parsesLocationInsightEventTypes() {
            let cases: [(String, RadarEventType)] = [
                ("user.entered_home", .userEnteredHome),
                ("user.exited_home", .userExitedHome),
                ("user.entered_work", .userEnteredWork),
                ("user.exited_work", .userExitedWork),
                ("user.started_traveling", .userStartedTraveling),
                ("user.stopped_traveling", .userStoppedTraveling),
                ("user.started_commuting", .userStartedCommuting),
                ("user.stopped_commuting", .userStoppedCommuting),
            ]

            for (eventTypeString, eventType) in cases {
                let event = RadarEvent(object: eventDict(type: eventTypeString))

                #expect(event?.type == eventType)
                #expect(event?.dictionaryValue()["type"] as? String == eventTypeString)
            }
        }

        @Test("Parses and serializes user location insights")
        func parsesUserLocationInsights() {
            let user = RadarUser(
                object: userDict(locationInsights: [
                    "atHome": true,
                    "atWork": false,
                    "traveling": true,
                    "commuting": false,
                ]))

            #expect(user?.locationInsights?.atHome == true)
            #expect(user?.locationInsights?.atWork == false)
            #expect(user?.locationInsights?.traveling == true)
            #expect(user?.locationInsights?.commuting == false)

            let serializedLocationInsights = user?.dictionaryValue()["locationInsights"] as? [String: Any]
            #expect(serializedLocationInsights?["atHome"] as? Bool == true)
            #expect(serializedLocationInsights?["atWork"] as? Bool == false)
            #expect(serializedLocationInsights?["traveling"] as? Bool == true)
            #expect(serializedLocationInsights?["commuting"] as? Bool == false)
        }

        @Test("Allows commuting to be omitted from location insights")
        func omitsNilCommuting() {
            let locationInsights = RadarUserLocationInsights(object: [
                "atHome": false,
                "atWork": true,
                "traveling": false,
            ])

            #expect(locationInsights?.atHome == false)
            #expect(locationInsights?.atWork == true)
            #expect(locationInsights?.traveling == false)
            #expect(locationInsights?.commuting == nil)
            #expect(locationInsights?.dictionaryValue()["commuting"] == nil)
        }

        private func eventDict(type: String) -> [String: Any] {
            return [
                "_id": "evt_test",
                "createdAt": "2026-06-26T12:00:00.000Z",
                "actualCreatedAt": "2026-06-26T12:00:00.000Z",
                "live": false,
                "type": type,
                "confidence": 3,
                "location": [
                    "type": "Point",
                    "coordinates": [-73.975365, 40.783825],
                ],
            ]
        }

        private func userDict(locationInsights: [String: Any]) -> [String: Any] {
            return [
                "_id": "user_test",
                "userId": "user-id",
                "deviceId": "device-id",
                "location": [
                    "type": "Point",
                    "coordinates": [-73.975365, 40.783825],
                ],
                "locationInsights": locationInsights,
            ]
        }
    }
}
