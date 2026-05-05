//
//  NotificationsPanel.swift
//  Example
//
//  Created by Alan Charles on 5/5/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import SwiftUI
import RadarSDK
import UserNotifications

struct NotificationsPanel: View {
    @Binding var outputText: String
    
    var body: some View {
        TogglePanel("Notifications", initiallyExpanded: false) {
            ActionButton("test notification") {
                let content = UNMutableNotificationContent()
                content.body = "Test"
                content.sound = UNNotificationSound.default
                content.categoryIdentifier = "example"
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                UNUserNotificationCenter.current().add(request, withCompletionHandler: { (_) in })
            }
            ActionButton("show notification permissions") {
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    outputText.removeAll()
                    switch settings.alertSetting {
                    case .notSupported:
                        outputText.append("alert unsupported")
                    case .disabled:
                        outputText.append("alert disabled")
                    case .enabled:
                        outputText.append("alert enabled")
                    @unknown default:
                        outputText.append("alert unknown")
                    }
                    outputText.append("")
                    switch settings.badgeSetting {
                    case .notSupported:
                        outputText.append("badge unsupported")
                    case .disabled:
                        outputText.append("badge disabled")
                    case .enabled:
                        outputText.append("badge enabled")
                    @unknown default:
                        outputText.append("badge unknown")
                    }
                    outputText.append("")
                    switch settings.lockScreenSetting {
                    case .notSupported:
                        outputText.append("lockscreen unsupported")
                    case .disabled:
                        outputText.append("lockscreen disabled")
                    case .enabled:
                        outputText.append("lockscreen enabled")
                    @unknown default:
                        outputText.append("lockscreen unknown")
                    }
                    outputText.append("")
                    switch settings.soundSetting {
                    case .notSupported:
                        outputText.append("sound unsupported")
                    case .disabled:
                        outputText.append("sound disabled")
                    case .enabled:
                        outputText.append("sound enabled")
                    @unknown default:
                        outputText.append("sound unknown")
                    }
                    outputText.append("")
                    switch settings.notificationCenterSetting {
                    case .notSupported:
                        outputText.append("notifcenter unsupported")
                    case .disabled:
                        outputText.append("notifcenter disabled")
                    case .enabled:
                        outputText.append("notifcenter enabled")
                    @unknown default:
                        outputText.append("notifcenter unknown")
                    }
                    outputText.append("")
                    switch settings.authorizationStatus {
                    case .notDetermined:
                        outputText.append("User has not been asked for notification permission")
                    case .denied:
                        outputText.append("User denied notification permission")
                    case .authorized:
                        outputText.append("Notifications authorized")
                    case .provisional:
                        outputText.append("Provisional permission granted")
                    case .ephemeral:
                        outputText.append("Ephemeral permission (App Clips)")
                    @unknown default:
                        outputText.append("Unknown status")
                    }
                }
            }
            ActionButton("list pending requests") {
                UNUserNotificationCenter.current().getPendingNotificationRequests { notifications in
                    outputText.removeAll()
                    for notification in notifications {
                        outputText.append(notification.identifier)
                    }
                }
            }
            ActionButton("remove first notification (simulate sent)", style: .destructive) {
                UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                    if requests.count > 0 {
                        let firstRequestId = requests.first!.identifier
                        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [firstRequestId])
                    }
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        NotificationsPanel(outputText: .constant(""))
            .padding()
    }
}
