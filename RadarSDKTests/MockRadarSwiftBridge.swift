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

    func updateTrackingFromInitialize() {
        updateTrackingFromInitializeCallCount += 1
        callOrder.append("updateTrackingFromInitialize")
    }

    func logOpenedAppConversion() {}
    func geofenceIds() -> [String]? { nil }
    func beaconIds() -> [String]? { nil }
    func placeId() -> String? { nil }
    var mockLastLocation: CLLocation?
    func lastLocation() -> CLLocation? { mockLastLocation }
    func isStopped() -> Bool { false }
    func getTripOptions() -> RadarTripOptions? { nil }
    func logCampaignConversion(name: String, metadata: [String: Any], campaign: String?) {}
    func createEvent(dict: [String: Any]) -> RadarEvent? { nil }
    func createUser(dict: [String: Any]) -> RadarUser? { nil }
    func createGeofence(dict: [String: Any]) -> RadarGeofence? { nil }
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
    func handleLocation(_ location: CLLocation, source: RadarLocationSource) {
        lastHandledLocation = location
        lastHandledSource = source
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
