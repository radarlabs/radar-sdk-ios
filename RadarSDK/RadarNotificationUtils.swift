//
//  RadarNotificationUtils.swift
//  RadarSDK
//
//  Created by Alan Charles on 7/17/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
@preconcurrency import UserNotifications

@objc public final class RadarNotificationUtils: NSObject {

    private static let semaphore = DispatchSemaphore(value: 1)

    // Checks current notification authorization and persists the result.
    // Called from Radar.m during initialization.
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
            let converted = delivered.map { $0 as [String: Any] }
            completionHandler(converted, [])
        }
    }

    @objc public static func updateClientSideCampaigns(
        withPrefix prefix: String,
        notificationRequests requests: [UNNotificationRequest]
    ) {
        DispatchQueue.global().async {
            semaphore.wait()
            removePendingNotifications(withPrefix: prefix) {
                addNotificationRequests(requests)
            }
        }
    }

    private static func removePendingNotifications(
        withPrefix prefix: String,
        completionHandler: @Sendable @escaping () -> Void
    ) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { pending in
            RadarLogger.shared.log(level: .debug, message: "Found \(pending.count) pending notifications")

            var identifiersToRemove: [String] = []
            var notificationsToKeep: [NotificationValue] = []

            for request in pending {
                if request.identifier.hasPrefix(prefix) {
                    identifiersToRemove.append(request.identifier)
                } else if let value = NotificationValue(from: request) {
                    notificationsToKeep.append(value)
                }
            }

            RadarLogger.shared.log(level: .debug, message: "Found \(identifiersToRemove.count) pending notifications to remove")
            RadarState().registeredNotifications = notificationsToKeep

            if !identifiersToRemove.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
                RadarLogger.shared.log(level: .debug, message: "Removed pending notifications")
            }

            completionHandler()
        }
    }

    private static func addNotificationRequests(_ requests: [UNNotificationRequest]) {
        checkNotificationPermissions { granted in
            guard granted else {
                RadarLogger.shared.log(level: .debug, message: "Notification permissions not granted. Skipping adding notifications.")
                semaphore.signal()
                return
            }

            let center = UNUserNotificationCenter.current()
            let group = DispatchGroup()
            let collectQueue = DispatchQueue(label: "com.radar.notificationRegister")
            nonisolated(unsafe) var added: [NotificationValue] = []

            for request in requests {
                group.enter()
                center.add(request) { error in
                    if let error {
                        RadarLogger.shared.log(level: .error, message: "Error adding local notification | identifier = \(request.identifier); error = \(error)")
                    } else {
                        if let value = NotificationValue(from: request) {
                            collectQueue.sync {
                                added.append(value)
                            }
                        }
                        RadarLogger.shared.log(level: .debug, message: "Added local notification | identifier = \(request.identifier)")
                    }
                    group.leave()
                }
            }

            group.notify(queue: .global()) {
                if !added.isEmpty {
                    let state = RadarState()
                    var registered = state.registeredNotifications ?? []
                    registered.append(contentsOf: added)
                    state.registeredNotifications = registered
                }
                semaphore.signal()
            }
        }
    }
}
