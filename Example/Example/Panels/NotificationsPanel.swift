//
//  NotificationsPanel.swift
//  Example
//
//  Created by Alan Charles on 5/5/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import RadarSDK
import SwiftUI
import UserNotifications

struct NotificationsPanel: View {
    @EnvironmentObject var logStream: LogStream

    var body: some View {
        TogglePanel("Notifications", initiallyExpanded: false) {
            ActionButton("test notification") {
                let content = UNMutableNotificationContent()
                content.body = "Test"
                content.sound = UNNotificationSound.default
                content.categoryIdentifier = "example"
                let request = UNNotificationRequest(
                    identifier: UUID().uuidString,
                    content: content,
                    trigger: nil
                )
                UNUserNotificationCenter.current().add(request, withCompletionHandler: { (_) in })
            }
            ActionButton("show notification permissions") {
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    let detail = """
                        alert: \(string(for: settings.alertSetting))
                        badge: \(string(for: settings.badgeSetting))
                        lockscreen: \(string(for: settings.lockScreenSetting))
                        sound: \(string(for: settings.soundSetting))
                        notifcenter: \(string(for: settings.notificationCenterSetting))
                        authorization: \(string(for: settings.authorizationStatus))
                        """
                    logStream.write(result: "notification permissions", detail: detail)
                }
            }
            ActionButton("list pending requests") {
                UNUserNotificationCenter.current().getPendingNotificationRequests { notifications in
                    let detail =
                        notifications.isEmpty
                        ? "(none)"
                        : notifications.map { $0.identifier }.joined(separator: "\n")
                    logStream.write(
                        result: "pending notifications: \(notifications.count)",
                        detail: detail
                    )
                }
            }
            ActionButton("remove first notification (simulate sent)", style: .destructive) {
                UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                    if let first = requests.first {
                        UNUserNotificationCenter.current()
                            .removePendingNotificationRequests(withIdentifiers: [first.identifier])
                    }
                }
            }
        }
    }

    // MARK: - String formatting helpers

    private func string(for setting: UNNotificationSetting) -> String {
        switch setting {
        case .notSupported: return "unsupported"
        case .disabled: return "disabled"
        case .enabled: return "enabled"
        @unknown default: return "unknown"
        }
    }

    private func string(for status: UNAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "not determined"
        case .denied: return "denied"
        case .authorized: return "authorized"
        case .provisional: return "provisional"
        case .ephemeral: return "ephemeral (App Clips)"
        @unknown default: return "unknown"
        }
    }
}

#Preview {
    ScrollView {
        NotificationsPanel().padding()
    }
    .environmentObject(LogStream())
}
