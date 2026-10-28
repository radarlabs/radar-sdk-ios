//
//  RadarSwiftBridge.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

/// This protocol is defined in both swift and Objective-C and should match, it is implemented in objc and set as the bridge variable in swift during initialize, so swift can call private objc functionality without using module maps.
///
/// usage: RadarSwift.bridge?.<function>()
@objc
protocol RadarSwiftBridgeProtocol {
    func flushReplays()
    func flushReplaysRequest(_ replays: [[AnyHashable: Any]], completionHandler: ((RadarStatus, [AnyHashable: Any]?) -> Void)?)
    func stopIndoorTracking()
    @objc(updateIndoorTrackingWithGeofences:)
    func updateIndoorTracking(geofences: [RadarGeofence]?)
    func updateTrackingFromInitialize()
    func logOpenedAppConversion()
    func geofenceIds() -> [String]?
    func beaconIds() -> [String]?
    func placeId() -> String?
    func lastLocation() -> CLLocation?
    func isStopped() -> Bool
    func setStopped(_ stopped: Bool)
    func setLastLocation(_ location: CLLocation?)
    func lastMovedLocation() -> CLLocation?
    func setLastMovedLocation(_ location: CLLocation?)
    func lastMovedAt() -> Date?
    func setLastMovedAt(_ date: Date)
    func lastFailedStoppedLocation() -> CLLocation?
    func setLastFailedStoppedLocation(_ location: CLLocation?)
    func lastSentAt() -> Date?
    func updateLastSentAt()
    func canExit() -> Bool
    func getTripOptions() -> RadarTripOptions?
    func logCampaignConversion(name: String, metadata: [String: Any], campaign: String?)
    func createEvent(dict: [String: Any]) -> RadarEvent?
    func createUser(dict: [String: Any]) -> RadarUser?
    func createGeofence(dict: [String: Any]) -> RadarGeofence?
    func createPlace(dict: [String: Any]) -> RadarPlace?
    func isForeground() -> Bool
    func didReceiveEvents(_ events: [RadarEvent], user: RadarUser)
    func didUpdateClientLocation(_ location: CLLocation, stopped: Bool, source: RadarLocationSource)
    func handleLocation(_ location: CLLocation, source: RadarLocationSource)
    func handleLocation(_ location: CLLocation, source: RadarLocationSource, beacons: [RadarBeacon]?)
    func updateTracking()
    func radarUser() -> RadarUser?
    func didFail(status: RadarStatus)
    // Calls the Objective-C `RadarAPIClient`, which `sendLocation` still uses to track and search beacons.
    @objc(trackWithLocation:stopped:source:replayed:beacons:indoorLocation:completionHandler:)
    func track(  // swiftlint:disable:this function_parameter_count
        location: CLLocation,
        stopped: Bool,
        source: RadarLocationSource,
        replayed: Bool,
        beacons: [RadarBeacon]?,
        indoorLocation: CLLocation?,
        completionHandler: @escaping (RadarStatus, [RadarEvent]?, RadarUser?, [RadarGeofence]?, RadarConfig?) -> Void
    )
    @objc(searchBeaconsNear:radius:limit:completionHandler:)
    func searchBeacons(
        near location: CLLocation,
        radius: Int32,
        limit: Int32,
        completionHandler: @escaping (RadarStatus, [RadarBeacon]?, [String]?) -> Void
    )
    func createBeacon(uuid: String, major: String, minor: String, rssi: Int) -> RadarBeacon
    func createBeacon(fromRegion region: CLBeaconRegion) -> RadarBeacon
    func setRssi(_ rssi: Int, onBeacon beacon: RadarBeacon)
}

@objc(RadarSwift) @objcMembers
class RadarSwift: NSObject {
    nonisolated(unsafe) static var bridge: RadarSwiftBridgeProtocol?
}
