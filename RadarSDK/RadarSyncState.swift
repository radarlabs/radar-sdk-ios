//
//  RadarSyncState.swift
//  RadarSDK
//
//  Created by Alan Charles on 3/19/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

struct RadarSyncState: Codable, Sendable {
    var syncedRegionCenter: RadarCoordinateSwift?
    var syncedRegionRadius: Double?
    var syncedGeofences: [RadarGeofenceSwift]?
    var syncedPlaces: [RadarPlaceSwift]?
    var syncedBeacons: [RadarBeaconSwift]?
    var lastSyncedGeofenceIds: [String] = []
    var lastSyncedPlaceIds: [String] = []
    var lastSyncedBeaconIds: [String] = []
    var geofenceEntryTimestamps: [String: Double] = [:]
    var dwellEventsFired: [String] = []
}

// Usage:
// static let syncStore = RadarFileStore<SyncState>(fileName: "radar_sync_state.json")
//
// let state = syncStore.read() ?? SyncState()
// syncStore.modify { state in state?.lastSyncedGeofenceIds = ["abc"] }
