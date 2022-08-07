//
//  Utils.swift
//  Example
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

import Foundation
import RadarSDK

extension RadarEvent {
    
    public var stringValue: String {
        let confidenceStr = self.confidence.stringValue
        
        switch self.type {
        case .userEnteredGeofence:
            return "Entered geofence \(geofence!.__description) with \(confidenceStr)"
        case .userExitedGeofence:
            return "Exited geofence \(geofence!.__description) with \(confidenceStr)"
        case .userEnteredPlace:
            return "Entered place \(place!.name) with \(confidenceStr)"
        case .userExitedPlace:
            return "Exited place \(place!.name) with \(confidenceStr)"
        case .userNearbyPlaceChain:
            return "Nearby chain \(place!.chain!.name) with \(confidenceStr)"
        case .userEnteredRegionState:
            return "Entered state \(region!.name) (\(region!.code)) with \(confidenceStr)"
        case .userExitedRegionState:
            return "Exited state \(region!.name) (\(region!.code)) with \(confidenceStr)"
        case .userEnteredRegionDMA:
            return "Entered DMA \(region!.name) (\(region!.code)) with \(confidenceStr)"
        case .userExitedRegionDMA:
            return "Exited DMA \(region!.name) (\(region!.code)) with \(confidenceStr)"
        case .userEnteredRegionCountry:
            return "Entered country \(region!.name) (\(region!.code)) with \(confidenceStr)"
        case .userExitedRegionCountry:
            return "Exited country \(region!.name) (\(region!.code)) with \(confidenceStr)"
        case .custom:
            return "Custom event '\(customType!)'"
        default:
            return "Unknown"
        }
    }
    
}

extension RadarEventConfidence {
    
    var stringValue: String {
        switch self {
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
    
}

extension RadarLocationSource {
    
    var stringValue: String {
        switch self {
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
