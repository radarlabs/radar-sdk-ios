//
//  RadarEfficientTrackManager.swift
//  RadarSDK
//
//  Created by Alan Charles on 1/29/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import CoreLocation

@objc(RadarEfficientTrackManager)
public final class RadarEfficientTrackManager: NSObject {
    
    private static let placeDetectionRadius: Double = 100.0
    private static let beaconRange: Double = 100.0
    
    @objc public static func shouldTrack(location: CLLocation, options: RadarTrackingOptions) -> Bool {
        guard RadarSwift.bridge?.syncedRegion() != nil else {
            RadarLogger.shared.debug("EfficientTrack: No synced region, should track")
            return true
        }
        
        if isOutsideSyncedRegion(location: location) {
            RadarLogger.shared.debug("EfficientTrack: Outside synced region, should track")
            return true
        }
        
        if Radar.getTripOptions() != nil {
            RadarLogger.shared.debug("EfficientTrack: On active trip, should always track")
            return true
        }
        
        if options.syncOnGeofenceEvents && hasGeofenceStateChanged(location: location) {
            RadarLogger.shared.debug("EfficientTrack: Geofence state changed, should track")
            return true
        }
        
        if options.syncOnPlaceEvents && hasPlaceStateChanged(location: location) {
            RadarLogger.shared.debug("EfficientTrack: Places state changed, should track")
            return true
        }
        
        if options.syncOnBeaconEvents && hasBeaconStateChanged(location: location) {
            RadarLogger.shared.debug("EfficientTrack: Beacon state changed, should track")
            return true
        }
        
        RadarLogger.shared.debug("EfficientTrack: No state change detected, skipping track")
        return false
    }
    
    @objc public static func getGeofences(for location: CLLocation) -> [RadarGeofence] {
        guard let nearbyGeofences = RadarSwift.bridge?.nearbyGeofences(), !nearbyGeofences.isEmpty else {
            return []
        }
        
        var userGeofences: [RadarGeofence] = []
        
        for geofence in nearbyGeofences {
            var center: RadarCoordinate?
            var radius: Double = 100
            
            if let circleGeometry = geofence.geometry as? RadarCircleGeometry {
                center = circleGeometry.center
                radius = circleGeometry.radius
            } else if let polygonGeometry = geofence.geometry as? RadarPolygonGeometry {
                center = polygonGeometry.center
                radius = polygonGeometry.radius
            } else {
                RadarLogger.shared.debug("EfficientTrack: Skipping geofence with unsupported geometry")
                continue
            }
            
            if let center = center,
               isPoint(location, insideCircleWithCenter: center.coordinate, radius: radius) {
                userGeofences.append(geofence)
            }
        }
        
        return userGeofences
    }
    
    @objc public static func getBeacons(for location: CLLocation) -> [RadarBeacon] {
        guard let nearbyBeacons = RadarSwift.bridge?.nearbyBeacons(), !nearbyBeacons.isEmpty else {
            return []
        }
        
        var userBeacons: [RadarBeacon] = []
        
        for beacon in nearbyBeacons {
            if let geometry = beacon.geometry {
                let beaconLocation = CLLocation(
                    latitude: geometry.coordinate.latitude,
                    longitude: geometry.coordinate.longitude
                )
                
                let distance = location.distance(from: beaconLocation)
                
                if distance <= beaconRange {
                    userBeacons.append(beacon)
                }
            }
        }
        
        return userBeacons
    }
    
    @objc public static func getPlaces(for location: CLLocation) -> [RadarPlace] {
        guard let nearbyPlaces = RadarSwift.bridge?.nearbyPlaces(), !nearbyPlaces.isEmpty else {
            return []
        }
        
        var userPlaces: [RadarPlace] = []
        
        for place in nearbyPlaces {
            if isPoint(location, insideCircleWithCenter: place.location.coordinate, radius: placeDetectionRadius) {
                userPlaces.append(place)
            }
        }
        
        return userPlaces
    }
    
    @objc public static func hasGeofenceStateChanged(location: CLLocation) -> Bool {
        let lastKnownGeofenceIds = RadarSwift.bridge?.geofenceIds() ?? []
        let currentGeofences = getGeofences(for: location)
        
        let currentGeofenceIds = Set(currentGeofences.compactMap { $0._id })
        let lastKnownSet = Set(lastKnownGeofenceIds)
        
        // entries
        for currentId in currentGeofenceIds {
            if !lastKnownSet.contains(currentId) {
                RadarLogger.shared.debug("EfficientTrack: Detected geofence entry: \(currentId)")
                return true
            }
        }
        
        // exits
        for lastKnownId in lastKnownGeofenceIds {
            if !currentGeofenceIds.contains(lastKnownId) {
                RadarLogger.shared.debug("EfficientTrack: Detected geofence exit: \(lastKnownId)")
                return true
            }
        }
        
        return false
    }
    
    @objc public static func hasBeaconStateChanged(location: CLLocation) -> Bool {
        let lastKNownBeaconIds = RadarSwift.bridge?.beaconIds() ?? []
        let currentBeacons = getBeacons(for: location)
        
        let currentBeaconIds = Set(currentBeacons.compactMap { $0._id })
        let lastKnownSet = Set(lastKNownBeaconIds)
        
        for currentId in currentBeaconIds {
            if !lastKnownSet.contains(currentId) {
                RadarLogger.shared.debug("EfficientTrack: Detected beacon entry: \(currentId)")
                return true
            }
        }
        
        for lastKnownId in lastKNownBeaconIds {
            if !currentBeaconIds.contains(lastKnownId) {
                RadarLogger.shared.debug("EfficientTrack: Detected beacon exit: \(lastKnownId)")
                return true
            }
        }
        
        return false
    }
    
    @objc public static func hasPlaceStateChanged(location: CLLocation) -> Bool {
        let lastKnownPlaceId = RadarSwift.bridge?.placeId()
        let currentPlaces = getPlaces(for: location)
        
        let currentPlaceIds = Set(currentPlaces.compactMap { $0._id})
        
        let wasInPlace = lastKnownPlaceId != nil && !lastKnownPlaceId!.isEmpty
        let isInPlace =  lastKnownPlaceId != nil && currentPlaceIds.contains(lastKnownPlaceId!)
        
        if !currentPlaceIds.isEmpty && !isInPlace {
            return true
        }
        
        if wasInPlace && !currentPlaceIds.contains(lastKnownPlaceId!) {
            return true
        }
        
        return false
        
    }
    
    @objc public static func isOutsideSyncedRegion(location: CLLocation) -> Bool {
        guard let syncedRegion = RadarSwift.bridge?.syncedRegion() else {
            return true
        }
        
        return !syncedRegion.contains(location.coordinate)
    }
    
    @objc public static func isPoint(_ point: CLLocation, insideCircleWithCenter center: CLLocationCoordinate2D, radius: Double) -> Bool {
        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
        let distance = centerLocation.distance(from: point)
        return distance <= radius
    }
}
