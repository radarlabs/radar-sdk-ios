//
//  RadarEventNotificationsTestHelpers.swift
//  RadarSDK
//
//  Created by Alan Charles on 7/20/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

@testable import RadarSDK

let testDateString = "2026-07-20T12:00:00.000Z"

func makeCampaignMetadata(
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

func makeGeofence(
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

func makeBeacon(
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

func makeTrip(
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

func makeEvent(
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
