//
//  MockRadarSwiftBridge.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import UserNotifications

@testable import RadarSDK

final class MockRadarSwiftBridge: NSObject, RadarSwiftBridgeProtocol, @unchecked Sendable {
    var flushStatus: RadarStatus = .success
    private(set) var lastFlushedReplays: [[AnyHashable: Any]]?
    private(set) var flushReplaysCallCount = 0
    private(set) var stopIndoorTrackingCallCount = 0
    private(set) var updateTrackingCallCount = 0
    private(set) var updateTrackingFromInitializeCallCount = 0
    private(set) var callOrder: [String] = []

    func flushReplaysRequest(
        _ replays: [[AnyHashable: Any]],
        completionHandler: ((RadarStatus, [AnyHashable: Any]?) -> Void)?
    ) {
        lastFlushedReplays = replays
        completionHandler?(flushStatus, nil)
    }

    func flushReplays() {
        flushReplaysCallCount += 1
        callOrder.append("flushReplays")
    }

    func stopIndoorTracking() {
        stopIndoorTrackingCallCount += 1
        callOrder.append("stopIndoorTracking")
    }

    func updateTracking() {
        updateTrackingCallCount += 1
        callOrder.append("updateTracking")
    }

    // Called from `updateTrackingFromInitialize()`, so a test can route it to a specific manager.
    var onUpdateTrackingFromInitialize: (() -> Void)?

    func updateTrackingFromInitialize() {
        updateTrackingFromInitializeCallCount += 1
        callOrder.append("updateTrackingFromInitialize")
        onUpdateTrackingFromInitialize?()
    }

    func logOpenedAppConversion() {}
    func geofenceIds() -> [String]? { nil }
    func beaconIds() -> [String]? { nil }
    func placeId() -> String? { nil }
    var mockLastLocation: CLLocation?
    func lastLocation() -> CLLocation? { mockLastLocation }
    var mockStopped = false
    func isStopped() -> Bool { mockStopped }
    func getTripOptions() -> RadarTripOptions? { nil }
    func logCampaignConversion(name: String, metadata: [String: Any], campaign: String?) {}
    var createEventHandler: (([String: Any]) -> RadarEvent?)?
    func createEvent(dict: [String: Any]) -> RadarEvent? { createEventHandler?(dict) }
    func createUser(dict: [String: Any]) -> RadarUser? { nil }
    var createGeofenceHandler: (([String: Any]) -> RadarGeofence?)?
    func createGeofence(dict: [String: Any]) -> RadarGeofence? { createGeofenceHandler?(dict) }
    var createPlaceHandler: (([String: Any]) -> RadarPlace?)?
    func createPlace(dict: [String: Any]) -> RadarPlace? { createPlaceHandler?(dict) }
    var createRegionHandler: (([String: Any]) -> RadarRegion?)?
    func createRegion(dict: [String: Any]) -> RadarRegion? { createRegionHandler?(dict) }
    var mockIsForeground = false
    func isForeground() -> Bool { mockIsForeground }
    func didReceiveEvents(_ events: [RadarEvent], user: RadarUser) {}
    private(set) var lastClientLocation: CLLocation?
    private(set) var lastClientLocationSource: RadarLocationSource?
    func didUpdateClientLocation(_ location: CLLocation, stopped: Bool, source: RadarLocationSource) {
        lastClientLocation = location
        lastClientLocationSource = source
    }
    private(set) var lastHandledLocation: CLLocation?
    private(set) var lastHandledSource: RadarLocationSource?
    private(set) var lastHandledBeacons: [RadarBeacon]?
    var onHandledLocation: (() -> Void)?

    func handleLocation(_ location: CLLocation, source: RadarLocationSource) {
        lastHandledLocation = location
        lastHandledSource = source
        onHandledLocation?()
    }

    func handleLocation(_ location: CLLocation, source: RadarLocationSource, beacons: [RadarBeacon]?) {
        lastHandledLocation = location
        lastHandledSource = source
        lastHandledBeacons = beacons
        onHandledLocation?()
    }
    func radarUser() -> RadarUser? { nil }
    private(set) var lastFailStatus: RadarStatus?
    func didFail(status: RadarStatus) { lastFailStatus = status }

    func createBeacon(uuid: String, major: String, minor: String, rssi: Int) -> RadarBeacon {
        RadarBeacon()
    }

    func createBeacon(fromRegion region: CLBeaconRegion) -> RadarBeacon {
        RadarBeacon()
    }

    func setRssi(_ rssi: Int, onBeacon beacon: RadarBeacon) {}

    func extractContent(fromMetadata metadata: [AnyHashable: Any]?, identifier: String?) -> UNMutableNotificationContent? {
        nil
    }

    func updateClientSideCampaigns(withPrefix prefix: String, notificationRequests: [UNNotificationRequest]) {}
}
