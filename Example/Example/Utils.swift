//
//  Utils.swift
//  Example
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

import Foundation
import RadarSDK

class Utils {

    /// The Radar API host the SDK is configured with. The SDK persists `radar-host` into the
    /// app-group suite (see RadarUserDefaults); falls back to production if unset. Use this
    /// everywhere instead of hardcoding `https://api.radar.io` so map, assets, and API calls
    /// all target the same host.
    static var radarHost: String {
        let suite = UserDefaults.standard.string(forKey: "radar-appGroup")
        return UserDefaults(suiteName: suite)?.string(forKey: "radar-host") ?? "https://api.radar.io"
    }

    static func stringForRadarEvent(_ event: RadarEvent) -> String {
        let confidenceStr = Utils.stringForRadarEventConfidence(event.confidence)
        
        switch event.type {
        case .userEnteredGeofence:
            return "Entered geofence \(event.geofence!.__description) with \(confidenceStr)"
        case .userExitedGeofence:
            return "Exited geofence \(event.geofence!.__description) with \(confidenceStr)"
        case .userEnteredPlace:
            return "Entered place \(event.place!.name) with \(confidenceStr)"
        case .userExitedPlace:
            return "Exited place \(event.place!.name) with \(confidenceStr)"
        case .userNearbyPlaceChain:
            return "Nearby chain \(event.place!.chain!.name) with \(confidenceStr)"
        case .userEnteredRegionState:
            return "Entered state \(event.region!.name) (\(event.region!.code)) with \(confidenceStr)"
        case .userExitedRegionState:
            return "Exited state \(event.region!.name) (\(event.region!.code)) with \(confidenceStr)"
        case .userEnteredRegionDMA:
            return "Entered DMA \(event.region!.name) (\(event.region!.code)) with \(confidenceStr)"
        case .userExitedRegionDMA:
            return "Exited DMA \(event.region!.name) (\(event.region!.code)) with \(confidenceStr)"
        case .userEnteredRegionCountry:
            return "Entered country \(event.region!.name) (\(event.region!.code)) with \(confidenceStr)"
        case .userExitedRegionCountry:
            return "Exited country \(event.region!.name) (\(event.region!.code)) with \(confidenceStr)"
        case .conversion:
            return "Received conversion event with name \(event.conversionName!)"
        default:
            return "Unknown"
        }
    }
    
    static func stringForRadarEventConfidence(_ confidence: RadarEventConfidence) -> String {
        switch confidence {
        case .high:
            return "high confidence"
        case .medium:
            return "medium confidence"
        case .low:
            return "low confidence"
        default:
            return "no confidence"
        }
    }
    
    static func stringForRadarLocationSource(_ source: RadarLocationSource) -> String {
        switch source {
        case .foregroundLocation:
            return "foreground"
        case .backgroundLocation:
            return "background"
        case .manualLocation:
            return "manual"
        case .geofenceEnter:
            return "geofence enter"
        case .geofenceExit:
            return "geofence exit"
        case .visitArrival:
            return "visit arrival"
        case .visitDeparture:
            return "visit departure"
        default:
            return "unknown"
        }
    }
    
}
