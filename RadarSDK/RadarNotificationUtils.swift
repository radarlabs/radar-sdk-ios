//
//  RadarNotificationUtils.swift
//  RadarSDK
//
//  Created by Alan Charles on 7/17/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import UserNotifications

@objc public final class RadarNotificationUtils: NSObject {
    
    // Checks current notification authorization and persists the result.
    // Called from Radar.m during intialization.
    @objc public static func checkNotificationPermissions(completionHandler: (@Sendable (Bool) -> Void)?) {
        guard NSClassFromString("XCTestCase") == nil else {
            completionHandler?(false)
            return
        }
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let granted = settings.authorizationStatus == .authorized
            RadarUserDefaults.set(granted, forKey: .NotificationPermissionGranted)
            if !granted {
                RadarLogger.shared.log(level: .debug, message: "Notification permissions not granted.")
            }
            completionHandler?(granted)
        }
    }
    
    /// Returns delivered notifications (registered minus still-pending).
    /// Called from RadarAPIClient.m before each track request.
    @objc public static func getNotificationDiff(completionHandler: @Sendable @escaping ([[String: Any]], [Any]) -> Void) {
        guard NSClassFromString("XCTestCase") == nil else {
            completionHandler([], [])
            return
        }

        Task {
            let delivered = await RadarNotificationHelper.shared.getDeliveredNotifications()
            completionHandler(delivered, [])
        }
    }
}
