//
//  PermissionsStore.swift
//  Example
//
//  Created by Alan Charles on 5/5/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Combine
import CoreLocation
import UserNotifications
import UIKit
import RadarSDK

/// Observable mirror of the app's permission states.
///
/// Surfaces location and notification authorization status to UI consumers (the
/// Permissions section in TestsView), and provides request actions that don't
/// require leaving the app.
///
/// Motion-activity status is not exposed by the OS — `CMMotionActivityManager`
/// has no public `authorizationStatus` getter. The store provides only a request
/// action via `Radar.requestMotionActivityPermission()`; UI surfaces no status.
///
/// AppDelegate retains its own `CLLocationManager` for `startMonitoringLocationPushes`
/// and the launch-time auto-prompt. PermissionsStore runs a parallel manager purely
/// for status observation. Both see the same OS state; the duplication is benign.
final class PermissionsStore: NSObject, ObservableObject {
    
    @Published private(set) var locationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var notificationStatus: UNAuthorizationStatus = .notDetermined
    
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationStatus = locationManager.authorizationStatus
        refreshNotificationStatus()
        observeAppForeground()
    }
    
    // MARK: - Location
    
    /// Request whichever next-step location authorization is appropriate from the
    /// current state:
    /// - `.notDetermined` → when-in-use prompt
    /// - `.authorizedWhenInUse` → escalate to always
    /// - `.denied` / `.restricted` / `.authorizedAlways` → no-op
    ///
    /// UI should show "Open Settings" for denied/restricted instead of calling this.
    func requestLocation() {
        switch locationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
        case .denied, .restricted, .authorizedAlways:
            break
        @unknown default:
            break
        }
    }
    
    // MARK: - Notifications
    
    func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { [weak self] _, _ in
            self?.refreshNotificationStatus()
        }
    }
    
    /// Re-poll the notification authorization status. Called automatically on app
    /// foreground and after `requestNotifications()` completes; can be invoked
    /// manually from the Permissions section's Refresh button.
    func refreshNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.notificationStatus = settings.authorizationStatus
            }
        }
    }
    
    // MARK: - Motion Activity
    
    /// Triggers the OS prompt via the SDK. The OS does not expose a status getter,
    /// so this is fire-and-check-CMPedometer/Activity-data-later.
    func requestMotionActivity() {
        Radar.requestMotionActivityPermission()
    }
    
    // MARK: - Settings deep link
    
    /// Open the app's page in the system Settings app. Useful for re-enabling
    /// permissions the user has previously denied (the OS will not show a fresh
    /// in-app prompt for denied permissions).
    func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - App lifecycle
    
    private func observeAppForeground() {
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.refreshNotificationStatus()
            }
            .store(in: &cancellables)
    }
}

// MARK: - CLLocationManagerDelegate

extension PermissionsStore: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async { [weak self] in
            self?.locationStatus = manager.authorizationStatus
        }
    }
}
