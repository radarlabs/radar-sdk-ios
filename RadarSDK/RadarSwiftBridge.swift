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
    func updateTrackingFromInitialize()
    func logOpenedAppConversion()
    func geofenceIds() -> [String]?
    func beaconIds() -> [String]?
    func placeId() -> String?
    func lastLocation() -> CLLocation?
    func isStopped() -> Bool
    func getTripOptions() -> RadarTripOptions?
    func logCampaignConversion(name: String, metadata: [String: Any], campaign: String?)
    func createEvent(dict: [String: Any]) -> RadarEvent?
    func createUser(dict: [String: Any]) -> RadarUser?
    func createGeofence(dict: [String: Any]) -> RadarGeofence?
    func isForeground() -> Bool
    func didReceiveEvents(_ events: [RadarEvent], user: RadarUser)
    func didUpdateClientLocation(_ location: CLLocation, stopped: Bool, source: RadarLocationSource)
    func handleLocation(_ location: CLLocation, source: RadarLocationSource)
    func handleLocation(_ location: CLLocation, source: RadarLocationSource, beacons: [RadarBeacon]?)
    func updateTracking()
    func radarUser() -> RadarUser?
    func didFail(status: RadarStatus)
    func createBeacon(uuid: String, major: String, minor: String, rssi: Int) -> RadarBeacon
    func createBeacon(fromRegion region: CLBeaconRegion) -> RadarBeacon
    func setRssi(_ rssi: Int, onBeacon beacon: RadarBeacon)

    // track request state
    func regionIds() -> [String]?
    func setGeofenceIds(_ geofenceIds: [String]?)
    func setPlaceId(_ placeId: String?)
    func setRegionIds(_ regionIds: [String]?)
    func setBeaconIds(_ beaconIds: [String]?)
    func setCanExit(_ canExit: Bool)
    func setRadarUser(_ user: RadarUser?)
    func setLastFailedStoppedLocation(_ location: CLLocation?)
    func setRegisteredNotifications(_ registeredNotifications: [[AnyHashable: Any]]?)
    func lastMotionActivityData() -> [AnyHashable: Any]?
    func lastRelativeAltitudeData() -> [AnyHashable: Any]?
    func motionAuthorizationString() -> String?
    func altitudeAdjustments() -> [[AnyHashable: Any]]?
    func setAltitudeAdjustments(_ altitudeAdjustments: [[AnyHashable: Any]]?)
    func restartPreviousTrackingOptions()
    func events(fromObject object: Any) -> [RadarEvent]?
    func geofences(fromObject object: Any) -> [RadarGeofence]?
    func createVerifiedLocationToken(dict: [String: Any]) -> RadarVerifiedLocationToken?
    func didUpdateLocation(_ location: CLLocation, user: RadarUser)
    func didUpdateToken(_ token: RadarVerifiedLocationToken)
}

@objc(RadarSwift) @objcMembers
class RadarSwift: NSObject {
    nonisolated(unsafe) static var bridge: RadarSwiftBridgeProtocol?
}
