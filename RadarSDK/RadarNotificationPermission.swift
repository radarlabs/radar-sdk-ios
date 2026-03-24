//
//  RadarNotificationPermission.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 3/20/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import UserNotifications

struct NotificationPermissions: Codable {
    let alert: Bool?
    let sound: Bool?
    let badge: Bool?
    let lockScreen: Bool?
    let notificationCenter: Bool?
    let authorizationStatus: String
    
    init(from settings: UNNotificationSettings) {
        switch settings.alertSetting {
        case .notSupported:
            alert = nil
        case .disabled:
            alert = false
        case .enabled:
            alert = true
        @unknown default:
            alert = nil
        }
        switch settings.badgeSetting {
        case .notSupported:
            badge = nil
        case .disabled:
            badge = false
        case .enabled:
            badge = true
        @unknown default:
            badge = nil
        }
        switch settings.lockScreenSetting {
        case .notSupported:
            lockScreen = nil
        case .disabled:
            lockScreen = false
        case .enabled:
            lockScreen = true
        @unknown default:
            lockScreen = nil
        }
        switch settings.soundSetting {
        case .notSupported:
            sound = nil
        case .disabled:
            sound = false
        case .enabled:
            sound = true
        @unknown default:
            sound = nil
        }
        switch settings.notificationCenterSetting {
        case .notSupported:
            notificationCenter = nil
        case .disabled:
            notificationCenter = false
        case .enabled:
            notificationCenter = true
        @unknown default:
            notificationCenter = nil
        }
        switch settings.authorizationStatus {
        case .notDetermined:
            authorizationStatus = "not_determined"
        case .denied:
            authorizationStatus = "denied"
        case .authorized:
            authorizationStatus = "authorized"
        case .provisional:
            authorizationStatus = "provisional"
        case .ephemeral:
            authorizationStatus = "ephemeral"
        @unknown default:
            authorizationStatus = "unknown"
        }
    }
    
    func canSendNotification() -> Bool {
        // whether or not any notifications will be sent, when all notification types are disabled, iOS will not return anything from pending notifications list
        // if that is the case, mostly likely the user has not received any notifications in the pending list.
        return authorizationStatus == "authorized" && (alert == true || sound == true || badge == true || lockScreen == true || notificationCenter == true)
    }
}
