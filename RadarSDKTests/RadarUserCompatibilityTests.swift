//
//  RadarUserCompatibilityTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import ObjectiveC
import Testing

@testable import RadarSDK

// RadarUser behavior that doesn't parse bridge-built models, so it needs no global bridge.
@Suite("RadarUserCompatibilityTests")
struct RadarUserCompatibilityTests {

    private func baseUserObject() -> [String: Any] {
        [
            "_id": "user-id",
            "location": ["type": "Point", "coordinates": [-73.9906, 40.7356]],
        ]
    }

    @Test("Returns nil for a non-dictionary object")
    func rejectsNonDictionary() {
        #expect(RadarUser(object: "user") == nil)
        #expect(RadarUser(object: [baseUserObject()]) == nil)
        #expect(RadarUserLocationInsights(object: 1) == nil)
    }

    @Test("Parses activity types and location sources")
    func parsesEnumStrings() throws {
        let activityTypes: [(String, RadarActivityType)] = [
            ("unknown", .unknown), ("car", .car), ("bike", .bike), ("foot", .foot), ("run", .run),
            ("stationary", .stationary),
        ]
        for (string, activityType) in activityTypes {
            var object = baseUserObject()
            object["activityType"] = string
            #expect(RadarUser(object: object)?.activityType == activityType)
        }

        let sources: [(String, RadarLocationSource)] = [
            ("FOREGROUND_LOCATION", .foregroundLocation), ("BACKGROUND_LOCATION", .backgroundLocation),
            ("MANUAL_LOCATION", .manualLocation), ("GEOFENCE_ENTER", .geofenceEnter),
            ("GEOFENCE_EXIT", .geofenceExit), ("VISIT_ARRIVAL", .visitArrival),
            ("VISIT_DEPARTURE", .visitDeparture), ("MOCK_LOCATION", .mockLocation),
        ]
        for (string, source) in sources {
            var object = baseUserObject()
            object["source"] = string
            #expect(RadarUser(object: object)?.source == source)
        }
    }

    @Test("Keeps public zero-value initializers")
    func zeroValueInitializers() {
        let user = RadarUser()
        #expect(user._id.isEmpty)
        #expect(user.activityType == .unknown)
        #expect(user.altitude == 0)
        #expect(user.geofences == nil)

        let insights = RadarUserLocationInsights()
        #expect(!insights.atHome)
        #expect(!insights.atWork)
        #expect(!insights.traveling)
        #expect(insights.commuting == nil)
    }

    @Test("Location insights parse booleans leniently and serialize commuting only when set")
    func locationInsights() throws {
        let insights = try #require(
            RadarUserLocationInsights(object: [
                "atHome": "yes", "atWork": 1, "traveling": false, "commuting": true,
            ]))

        #expect(!insights.atHome)
        #expect(insights.atWork)
        #expect(!insights.traveling)
        #expect(insights.commuting == true)

        let dict = insights.dictionaryValue()
        #expect(dict["atHome"] as? Bool == false)
        #expect(dict["atWork"] as? Bool == true)
        #expect(dict["traveling"] as? Bool == false)
        #expect(dict["commuting"] as? Bool == true)
    }

    @Test("Keeps the Objective-C runtime names and selectors")
    func objcContract() throws {
        let userClass: AnyClass = try #require(NSClassFromString("RadarUser"))
        #expect(ObjectIdentifier(userClass) == ObjectIdentifier(RadarUser.self))
        for selector in ["initWithObject:", "dictionaryValue", "_id", "__description", "activityType", "source"] {
            let responds = userClass.instancesRespond(to: NSSelectorFromString(selector))
            #expect(responds, "\(selector)")
        }

        let insightsClass: AnyClass = try #require(NSClassFromString("RadarUserLocationInsights"))
        #expect(ObjectIdentifier(insightsClass) == ObjectIdentifier(RadarUserLocationInsights.self))
        for selector in ["initWithObject:", "dictionaryValue", "atHome", "atWork", "traveling", "commuting"] {
            let responds = insightsClass.instancesRespond(to: NSSelectorFromString(selector))
            #expect(responds, "\(selector)")
        }
    }
}
