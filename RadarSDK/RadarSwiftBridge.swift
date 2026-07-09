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
    func logOpenedAppConversion()
    func invoke(target: NSObject, selector: Selector, args: [Any])
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
    func radarUser() -> RadarUser?
}

@objc(RadarSwift) @objcMembers
class RadarSwift: NSObject {
    nonisolated(unsafe) static var bridge: RadarSwiftBridgeProtocol?
}
