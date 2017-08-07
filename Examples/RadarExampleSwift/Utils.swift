//
//  Utils.swift
//  RadarExampleSwift
//
//  Copyright © 2017 Radar Labs, Inc. All rights reserved.
//

import Foundation

class Utils {

    static func getUserId() -> String {
        return UIDevice.current.identifierForVendor!.uuidString
    }

    static func stringForEvent(_ event: RadarEvent) -> String {
        switch event.type {
        case .userEnteredGeofence:
            return "Entered geofence \(event.geofence != nil ? event.geofence!._description : "-")"
        case .userExitedGeofence:
            return "Exited geofence \(event.geofence != nil ? event.geofence!._description : "-")"
        case .userEnteredHome:
            return "Entered home"
        case .userExitedHome:
            return "Exited home"
        case .userEnteredOffice:
            return "Entered office"
        case .userExitedOffice:
            return "Exited office"
        case .userStartedTraveling:
            return "Started traveling"
        case .userStoppedTraveling:
            return "Stopped traveling"
        case .userEnteredPlace:
            return "Entered place \(event.place != nil ? event.place!.name : "-")"
        case .userExitedPlace:
            return "Exited place \(event.place != nil ? event.place!.name : "-")"
        default:
            return "-"
        }
    }

}
