//
//  PermissionsStore.swift
//  Example
//
//  Created by Alan Charles on 5/5/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Combine
import CoreLocation
import CoreMotion
import Foundation
import RadarSDK
import UIKit
import UserNotifications

/// Observable mirror of the app's permission states.
///
/// Surfaces location, notification, and motion-activity authorization status,
/// plus the count of pending SDK-scheduled local notifications, to UI consumers
/// (the Permissions section in TestsSettingsView). Also provides request
/// actions that don't require leaving the app.
///
/// AppDelegate retains its own `CLLocationManager` for `startMonitoringLocationPushes`
/// and the launch-time auto-prompt. PermissionsStore runs a parallel manager purely
/// for status observation. Both see the same OS state; the duplication is benign.
final class PermissionsStore: NSObject, ObservableObject {

    @Published private(set) var locationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var notificationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var motionStatus: CMAuthorizationStatus = .notDetermined
    @Published private(set) var pendingRadarNotificationCount: Int = 0

    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()
        locationManager.delegate = self
        locationStatus = locationManager.authorizationStatus
        refreshNotificationStatus()
        refreshMotionStatus()
        refreshPendingRadarNotifications()
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

    /// Count of OS-level pending notifications scheduled by the SDK. These are
    /// `UNNotificationRequest`s registered via `RadarNotificationHelper`
    /// (geofence, beacon, and event notifications) — they share the `radar_`
    /// identifier prefix.
    ///
    /// Refreshes on app foreground and from the Permissions section's Refresh
    /// button.
    func refreshPendingRadarNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { [weak self] requests in
            let count = requests.filter { $0.identifier.hasPrefix("radar_") }.count
            DispatchQueue.main.async {
                self?.pendingRadarNotificationCount = count
            }
        }
    }

    // MARK: - Motion Activity

    /// Re-poll the motion-activity authorization status from CoreMotion.
    /// Called automatically on init and on app foreground; can be invoked
    /// from the Permissions section's Refresh button. After a freshly-
    /// triggered prompt, `requestMotionActivity()` also schedules a delayed
    /// refresh since CoreMotion has no completion handler for the prompt
    /// response.
    func refreshMotionStatus() {
        let status = CMMotionActivityManager.authorizationStatus()
        DispatchQueue.main.async { [weak self] in
            self?.motionStatus = status
        }
    }

    /// Triggers the OS prompt via the SDK, then polls authorization a moment
    /// later. CoreMotion exposes no callback for the prompt response, so a
    /// brief delay is the simplest way to catch the user's answer.
    func requestMotionActivity() {
        Radar.requestMotionActivityPermission()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.refreshMotionStatus()
        }
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
                self?.refreshMotionStatus()
                self?.refreshPendingRadarNotifications()
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
