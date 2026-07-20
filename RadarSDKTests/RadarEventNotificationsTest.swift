//
//  RadarEventNotificationsTest.swift
//  RadarSDK
//
//  Created by Alan Charles on 7/20/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import Testing
import UserNotifications

@testable import RadarSDK

// MARK: - Test Helpers

private func makeCampaignMetadata(
    notificationText: String = "Hello",
    title: String? = nil,
    subtitle: String? = nil,
    url: String? = nil,
    campaignId: String? = nil,
    campaignType: String = "clientSide",
    campaignMetadata: String? = nil
) -> [String: Any] {
    var meta: [String: Any] = [
        "radar:notificationText": notificationText,
        "radar:campaignType": campaignType,
    ]
    if let title { meta["radar:notificationTitle"] = title }
    if let subtitle { meta["radar:notificationSubtitle"] = subtitle }
    if let url { meta["radar:notificationURL"] = url }
    if let campaignId { meta["radar:campaignId"] = campaignId }
    if let campaignMetadata { meta["radar:campaignMetadata"] = campaignMetadata }
    return meta
}

private let testLocation = CLLocation(latitude: 40.0, longitude: -74.0)
private let testDate = Date(timeIntervalSince1970: 1_000_000)

private func makeGeofence(
    id: String = "geo_1",
    metadata: NSDictionary? = nil
) -> RadarGeofence {
    let coord = RadarCoordinate(coordinate: CLLocationCoordinate2D(latitude: 40.0, longitude: -74.0))!
    let geometry = RadarCircleGeometry(center: coord, radius: 100.0)!
    return RadarGeofence(
        id: id,
        description: "Test Geofence",
        tag: "test",
        externalId: "ext_\(id)",
        metadata: metadata as? [AnyHashable: Any],
        operatingHours: nil,
        geometry: geometry,
        dwellThreshold: nil,
        geofenceStopDetection: nil,
        activeIndoorModelId: nil
    )!
}

private func makeBeacon(
    id: String = "beacon_1",
    metadata: NSDictionary? = nil
) -> RadarBeacon {
    var dict: [String: Any] = [
        "_id": id,
        "description": "Test Beacon",
        "tag": "test",
        "externalId": "ext_\(id)",
        "uuid": "00000000-0000-0000-0000-000000000000",
        "major": "1",
        "minor": "1",
        "geometry": ["coordinates": [-74.0, 40.0]],
    ]
    if let metadata {
        dict["metadata"] = metadata
    }
    return RadarBeacon(object: dict)!
}

private func makeTrip(
    id: String = "trip_1",
    metadata: NSDictionary? = nil
) -> RadarTrip {
    var dict: [String: Any] = [
        "_id": id,
        "externalId": "ext_\(id)",
        "mode": "car",
        "status": "started",
    ]
    if let metadata {
        dict["metadata"] = metadata
    }
    return RadarTrip(object: dict)!
}

private let testDateString = "2026-07-20T12:00:00.000Z"

private func makeEvent(
    type: RadarEventType,
    geofence: RadarGeofence? = nil,
    beacon: RadarBeacon? = nil,
    trip: RadarTrip? = nil,
    metadata: NSDictionary? = nil
) -> RadarEvent {
    var dict: [String: Any] = [
        "_id": "evt_\(UUID().uuidString)",
        "createdAt": testDateString,
        "actualCreatedAt": testDateString,
        "live": false,
        "type": RadarEvent.string(for: type) ?? "unknown",
        "location": ["type": "Point", "coordinates": [-74.0, 40.0]],
    ]
    if let geofence { dict["geofence"] = geofence.dictionaryValue() }
    if let beacon { dict["beacon"] = beacon.dictionaryValue() }
    if let trip { dict["trip"] = trip.dictionaryValue() }
    if let metadata { dict["metadata"] = metadata }
    return RadarEvent(object: dict)!
}

// MARK: - extractCampaignContent Tests

@Suite("RadarEventNotifications - extractCampaignContent")
struct ExtractCampaignContentTests {
    
    @Test("returns nil for nil metadata")
    func nilMetadata() {
        let result = RadarEventNotifications.extractCampaignContent(from: nil, identifier: "test_id")
        #expect(result == nil)
    }

    @Test("returns nil for nil metadata with nil identifier (no crash)")
    func nilMetadataNilIdentifier() {
        let result = RadarEventNotifications.extractCampaignContent(from: nil, identifier: nil)
        #expect(result == nil)
    }

    @Test("returns nil when notificationText is missing")
    func missingNotificationText() {
        let meta: [AnyHashable: Any] = ["radar:campaignType": "clientSide"]
        let result = RadarEventNotifications.extractCampaignContent(from: meta, identifier: "test_id")
        #expect(result == nil)
    }
    
    @Test("returns nil when campaignType is missing")
    func missingCampaignType() {
        let meta: [AnyHashable: Any] = ["radar:notificationText": "Hello"]
        let result = RadarEventNotifications.extractCampaignContent(from: meta, identifier: "test_id")
        #expect(result == nil)
    }
    
    @Test("returns nil for unrecognized campaignType")
    func unrecognizedCampaignType() {
        let meta = makeCampaignMetadata(campaignType: "serverSide") as [AnyHashable: Any]
        let result = RadarEventNotifications.extractCampaignContent(from: meta, identifier: "test_id")
        #expect(result == nil)
    }
    
    @Test("returns content for clientSide campaign", arguments: ["clientSide", "eventBased"])
    func validCampaignTypes(campaignType: String) {
        let meta = makeCampaignMetadata(
            notificationText: "Welcome!",
            campaignType: campaignType
        ) as [AnyHashable: Any]

        let content = RadarEventNotifications.extractCampaignContent(from: meta, identifier: "test_id")
        #expect(content != nil)
        #expect(content?.body == "Welcome!")
    }
    
    @Test("sets title when present")
    func setsTitle() {
        let meta = makeCampaignMetadata(
            notificationText: "Body",
            title: "My Title"
        ) as [AnyHashable: Any]

        let content = RadarEventNotifications.extractCampaignContent(from: meta, identifier: "test_id")
        #expect(content?.title == "My Title")
    }
    
    @Test("sets subtitle when present")
    func setsSubtitle() {
        let meta = makeCampaignMetadata(
            notificationText: "Body",
            subtitle: "My Subtitle"
        ) as [AnyHashable: Any]

        let content = RadarEventNotifications.extractCampaignContent(from: meta, identifier: "test_id")
        #expect(content?.subtitle == "My Subtitle")
    }
    
    @Test("omits title and subtitle when absent")
    func omitsTitleAndSubtitle() {
        let meta = makeCampaignMetadata(notificationText: "Body") as [AnyHashable: Any]
        let content = RadarEventNotifications.extractCampaignContent(from: meta, identifier: "test_id")
        #expect(content?.title == "")
        #expect(content?.subtitle == "")
    }
    
    @Test("populates URL in userInfo")
    func populatesURL() {
        let meta = makeCampaignMetadata(
            url: "https://example.com/deep"
        ) as [AnyHashable: Any]

        let content = RadarEventNotifications.extractCampaignContent(from: meta, identifier: "test_id")
        #expect(content?.userInfo["url"] as? String == "https://example.com/deep")
    }
    
    @Test("populates campaignId in userInfo")
    func populatesCampaignId() {
        let meta = makeCampaignMetadata(
            campaignId: "camp_42"
        ) as [AnyHashable: Any]

        let content = RadarEventNotifications.extractCampaignContent(from: meta, identifier: "test_id")
        #expect(content?.userInfo["campaignId"] as? String == "camp_42")
    }
    
    @Test("always includes registeredAt in userInfo")
    func includesRegisteredAt() {
        let meta = makeCampaignMetadata() as [AnyHashable: Any]
        let content = RadarEventNotifications.extractCampaignContent(from: meta, identifier: "test_id")
        #expect(content?.userInfo["registeredAt"] as? String != nil)
    }
    
    @Test("sets identifier in userInfo")
    func setsIdentifier() {
        let meta = makeCampaignMetadata() as [AnyHashable: Any]
        let content = RadarEventNotifications.extractCampaignContent(from: meta, identifier: "test_id")
        #expect(content?.userInfo["identifier"] as? String == "test_id")
    }
    
    @Test("extracts geofenceId from radar_geofence_ prefix")
    func extractsGeofenceId() {
        let meta = makeCampaignMetadata() as [AnyHashable: Any]
        let content = RadarEventNotifications.extractCampaignContent(from: meta, identifier: "radar_geofence_abc123")
        #expect(content?.userInfo["geofenceId"] as? String == "abc123")
    }
    
    @Test("does not set geofenceId for non-geofence identifiers")
    func noGeofenceIdForOtherPrefixes() {
        let meta = makeCampaignMetadata() as [AnyHashable: Any]
        let content = RadarEventNotifications.extractCampaignContent(from: meta, identifier: "radar_beacon_abc123")
        #expect(content?.userInfo["geofenceId"] == nil)
    }
    
    @Test("no identifier or geofenceId when identifier is nil")
    func nilIdentifier() {
        let meta = makeCampaignMetadata() as [AnyHashable: Any]
        let content = RadarEventNotifications.extractCampaignContent(from: meta, identifier: nil)
        #expect(content?.userInfo["identifier"] == nil)
        #expect(content?.userInfo["geofenceId"] == nil)
    }
    
    @Test("parses valid campaignMetadata JSON")
    func parsesValidCampaignMetadataJSON() {
        let json = "{\"promo\": \"summer2026\", \"discount\": 20}"
        let meta = makeCampaignMetadata(campaignMetadata: json) as [AnyHashable: Any]
        let content = RadarEventNotifications.extractCampaignContent(from: meta, identifier: "test_id")

        let parsed = content?.userInfo["campaignMetadata"] as? [String: Any]
        #expect(parsed?["promo"] as? String == "summer2026")
        #expect(parsed?["discount"] as? Int == 20)
    }
    
    @Test("ignores invalid campaignMetadata JSON")
    func ignoresInvalidCampaignMetadataJSON() {
        let meta = makeCampaignMetadata(campaignMetadata: "not valid json{{{") as [AnyHashable: Any]
        let content = RadarEventNotifications.extractCampaignContent(from: meta, identifier: "test_id")
        #expect(content?.userInfo["campaignMetadata"] == nil)
    }
    
    @Test("preserves original metadata keys in userInfo")
    func preservesOriginalMetadata() {
        var meta = makeCampaignMetadata() as [AnyHashable: Any]
        meta["customKey"] = "customValue"
        let content = RadarEventNotifications.extractCampaignContent(from: meta, identifier: "test_id")
        #expect(content?.userInfo["customKey"] as? String == "customValue")
    }
}

// MARK: - isCampaign Tests

@Suite("RadarEventNotifications - isCampaign")
struct isCampaignTests {
    @Test("clientSide is a campaign")
    func clientSide() {
        #expect(RadarEventNotifications.isCampaign(["radar:campaignType": "clientSide"]))
    }

    @Test("eventBased is a campaign")
    func eventBased() {
        #expect(RadarEventNotifications.isCampaign(["radar:campaignType": "eventBased"]))
    }

    @Test("missing campaignType is not a campaign")
    func missingType() {
        #expect(!RadarEventNotifications.isCampaign(["other": "value"]))
    }

    @Test("unrecognized campaignType is not a campaign")
    func unrecognizedType() {
        #expect(!RadarEventNotifications.isCampaign(["radar:campaignType": "serverSide"]))
    }

    @Test("empty string campaignType is not a campaign")
    func emptyType() {
        #expect(!RadarEventNotifications.isCampaign(["radar:campaignType": ""]))
    }
}

// MARK: - legacyNotificationText Tests

@Suite("RadarEventNotifications - legacyNotifictionText")
struct LegacyNotificationTextTests {
    @Test("geofence entry returns entryNotificationText")
    func geofenceEntry() {
        let metadata: NSDictionary = ["radar:entryNotificationText": "Welcome!"]
        let geofence = makeGeofence(metadata: metadata)
        let event = makeEvent(type: .userEnteredGeofence, geofence: geofence)

        let result = RadarEventNotifications.legacyNotificationText(for: event)
        #expect(result?.1 == "Welcome!")
        #expect(result?.0["radar:entryNotificationText"] as? String == "Welcome!")
    }
    
    @Test("geofence exit returns exitNotificationText")
    func geofenceExit() {
        let metadata: NSDictionary = ["radar:exitNotificationText": "Goodbye!"]
        let geofence = makeGeofence(metadata: metadata)
        let event = makeEvent(type: .userExitedGeofence, geofence: geofence)

        let result = RadarEventNotifications.legacyNotificationText(for: event)
        #expect(result?.1 == "Goodbye!")
    }
    
    @Test("beacon entry returns entryNotificationText")
    func beaconEntry() {
        let metadata: NSDictionary = ["radar:entryNotificationText": "Near beacon!"]
        let beacon = makeBeacon(metadata: metadata)
        let event = makeEvent(type: .userEnteredBeacon, beacon: beacon)

        let result = RadarEventNotifications.legacyNotificationText(for: event)
        #expect(result?.1 == "Near beacon!")
    }
    
    @Test("beacon exit returns exitNotificationText")
    func beaconExit() {
        let metadata: NSDictionary = ["radar:exitNotificationText": "Left beacon!"]
        let beacon = makeBeacon(metadata: metadata)
        let event = makeEvent(type: .userExitedBeacon, beacon: beacon)

        let result = RadarEventNotifications.legacyNotificationText(for: event)
        #expect(result?.1 == "Left beacon!")
    }

    @Test("trip approaching returns approachingNotificationText")
    func tripApproaching() {
        let metadata: NSDictionary = ["radar:approachingNotificationText": "Almost there!"]
        let trip = makeTrip(metadata: metadata)
        let event = makeEvent(type: .userApproachingTripDestination, trip: trip)

        let result = RadarEventNotifications.legacyNotificationText(for: event)
        #expect(result?.1 == "Almost there!")
    }
    
    @Test("trip arrived returns arrivalNotificationText")
    func tripArrived() {
        let metadata: NSDictionary = ["radar:arrivalNotificationText": "You're here!"]
        let trip = makeTrip(metadata: metadata)
        let event = makeEvent(type: .userArrivedAtTripDestination, trip: trip)

        let result = RadarEventNotifications.legacyNotificationText(for: event)
        #expect(result?.1 == "You're here!")
    }
    
    @Test("returns nil when metadata is missing the notification text key")
    func missingTextKey() {
        let metadata: NSDictionary = ["someOtherKey": "value"]
        let geofence = makeGeofence(metadata: metadata)
        let event = makeEvent(type: .userEnteredGeofence, geofence: geofence)

        #expect(RadarEventNotifications.legacyNotificationText(for: event) == nil)
    }
    
    @Test("returns nil for unsupported event types", arguments: [
        RadarEventType.unknown,
        RadarEventType.userEnteredPlace,
        RadarEventType.userStartedTrip,
        RadarEventType.userDwelledInGeofence,
    ])
    func unsupportedEventTypes(type: RadarEventType) {
        let event = makeEvent(type: type)
        #expect(RadarEventNotifications.legacyNotificationText(for: event) == nil)
    }
}
