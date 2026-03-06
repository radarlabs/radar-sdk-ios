//
//  RadarSwiftBridge.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

/**
 This protocol is defined in both swift and Objective-C and should match, it is implemented in objc and set as the bridge variable in swift during initialize, so swift can call private objc functionality without using module maps.
 
 usage: RadarSwift.bridge?.<function>()
 */
@objc
protocol RadarSwiftBridgeProtocol {
    func writeToLogBuffer(level: RadarLogLevel, type: RadarLogType, message: String, forcePersist: Bool)
    func setLogBufferPersistantLog(_ value: Bool)
    func flushReplays()
    func logOpenedAppConversion()
    func syncedRegion() -> CLCircularRegion?
    func geofenceIds() -> [String]?
    func beaconIds() -> [String]?
    func placeId() -> String?
    func syncedGeofences() -> [RadarGeofence]?
    func syncedBeacons() -> [RadarBeacon]?
    func syncedPlaces() -> [RadarPlace]?
    func lastLocation() -> CLLocation?
    func fetchSyncRegion(latitude: Double, longitude: Double, completionHandler: @escaping (RadarStatus, [String: Any]?) -> Void)
    func setSyncedGeofences(_ geofences: [RadarGeofence]?)
    func setSyncedBeacons(_ beacons: [RadarBeacon]?)
    func setSyncedPlaces(_ places: [RadarPlace]?)
    func setSyncedRegion(_ region: CLCircularRegion?)
    func geofencesFromObject(_ object: Any) -> [RadarGeofence]?
    func placesFromObject(_ object: Any) -> [RadarPlace]?
    func beaconsFromObject(_ object: Any) -> [RadarBeacon]?
    func lastSyncedGeofenceIds() -> [String]
    func setLastSyncedGeofenceIds(_ ids: [String]?)
    func lastSyncedPlaceIds() -> [String]
    func setLastSyncedPlaceIds(_ ids: [String]?)
    func lastSyncedBeaconIds() -> [String]
    func setLastSyncedBeaconIds(_ ids: [String]?)
    func geofenceEntryTimestamps() -> [String: Date]
    func setGeofenceEntryTimestamps(_ timestamps: [String: Date]?)
    func dwellEventsFired() -> [String]
    func setDwellEventsFired(_ ids: [String]?)
    func isStopped() -> Bool
    func getTripOptions() -> RadarTripOptions?
}

@objc(RadarSwift) @objcMembers
class RadarSwift: NSObject {
    nonisolated(unsafe) static var bridge: RadarSwiftBridgeProtocol?
}
