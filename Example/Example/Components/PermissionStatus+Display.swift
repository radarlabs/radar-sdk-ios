//
//  PermissionStatus+Display.swift
//  Example
//
//  Created by Alan Charles on 5/14/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

//  SwiftUI display helpers for `CLAuthorizationStatus` and
//  `UNAuthorizationStatus`. Mirrors the `ConsoleEntry+UI.swift`
//  pattern: extensions that bridge non-UI types to SwiftUI live here.
//

import CoreLocation
import CoreMotion
import SwiftUI
import UserNotifications

extension CLAuthorizationStatus {
    var displayName: String {
        switch self {
        case .notDetermined: return "Not determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedAlways: return "Always"
        case .authorizedWhenInUse: return "When in use"
        @unknown default: return "Unknown"
        }
    }

    var displayColor: Color {
        switch self {
        case .authorizedAlways: return .green
        case .authorizedWhenInUse: return .blue
        case .notDetermined: return .secondary
        case .denied, .restricted: return .red
        @unknown default: return .secondary
        }
    }
}

extension UNAuthorizationStatus {
    var displayName: String {
        switch self {
        case .notDetermined: return "Not determined"
        case .denied: return "Denied"
        case .authorized: return "Authorized"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }

    var displayColor: Color {
        switch self {
        case .authorized, .provisional, .ephemeral: return .green
        case .notDetermined: return .secondary
        case .denied: return .red
        @unknown default: return .secondary
        }
    }
}

extension CMAuthorizationStatus {
    var displayName: String {
        switch self {
        case .notDetermined: return "Not determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorized: return "Authorized"
        @unknown default: return "Unknown"
        }
    }

    var displayColor: Color {
        switch self {
        case .authorized: return .green
        case .notDetermined: return .secondary
        case .denied, .restricted: return .red
        @unknown default: return .secondary
        }
    }
}
