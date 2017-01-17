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
    
    static func stringForStatus(_ status: RadarStatus) -> String {
        switch status {
        case .success:
            return "Success"
        case .errorPublishableKey:
            return "Publishable Key Error"
        case .errorUserId:
            return "User ID Error"
        case .errorPermissions:
            return "Permissions Error"
        case .errorLocation:
            return "Location Error"
        case .errorNetwork:
            return "Network Error"
        case .errorUnauthorized:
            return "Unauthorized Error"
        case .errorServer:
            return "Server Error"
        default:
            return "Unknown Error"
        }
    }
    
    static func stringForGeofence(_ geofence: RadarGeofence) -> String {
        let description = geofence._description
        let tag = geofence.tag == nil ? "nil" : geofence.tag!
        let externalId = geofence.externalId == nil ? "nil" : geofence.externalId!
        return description + " / " + tag + " / " + externalId
    }
    
    static func stringForEvent(_ event: RadarEvent) -> String {
        let type = event.type == .userEnteredGeofence ? "user.entered_geofence" : "user.exited_geofence"
        let description = event.geofence._description
        return type + " / " + description
    }
    
}
