//
//  RadarSwiftUtils.swift
//  RadarSDK
//
//  Created by Kenny Hu on 4/17/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation
import ActivityKit

@objc(RadarSwiftUtils) class RadarSwiftUtils: NSObject {
    // Define a concrete type for activity attributes
    struct RadarActivityAttributes: ActivityAttributes {
       
        public struct ContentState: Codable, Hashable {
               // Dynamic stateful properties about your activity go here!
               var emoji: String
           }
        
    }

    @objc public static func areActivitiesEnabled() -> Bool{
        if #available(iOS 16.2, *) {
            let areActivitiesEnabled = ActivityAuthorizationInfo().areActivitiesEnabled
            if (!areActivitiesEnabled) {
                RadarLogger.sharedInstance().log(level:RadarLogLevel.debug, message:"Live activities are not enabled")
            }
            return areActivitiesEnabled
        } else {
            return false
        }
    }

    @objc public static func areLiveActivitiesActive() -> Bool {
        if #available(iOS 16.2, *) {
            let activityAuthorizationInfo = ActivityAuthorizationInfo()
            if !activityAuthorizationInfo.areActivitiesEnabled {
                RadarLogger.sharedInstance().log(level:RadarLogLevel.debug, message:"Live activities are not enabled")
                return false
            }
            
            // Get all active activities using the concrete RadarActivityAttributes type
            let activities = Activity<RadarActivityAttributes>.activities
            let hasActiveActivities = activities.count > 0
            
            if hasActiveActivities {
                RadarLogger.sharedInstance().log(level:RadarLogLevel.info, message:"Live activities are active")
            } else {
                RadarLogger.sharedInstance().log(level:RadarLogLevel.info, message:"No live activities are active")
            }
            
            return hasActiveActivities
        } else {
            return false
        }
    }
}
