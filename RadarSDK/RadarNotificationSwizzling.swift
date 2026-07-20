//
//  RadarNotificationSwizzling.swift
//  RadarSDK
//
//  Created by Alan Charles on 7/17/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import ObjectiveC
import UIKit
import UserNotifications

@objc public final class RadarNotificationSwizzling: NSObject {

    // MARK: - Public setup

    /// Swizzle UNUserNotificationCenterDelegate.didReceiveNotificationResponse
    /// to handle deep links and conversion logging
    @MainActor
    @objc public static func swizzleNotificationCenterDelegate() {
        guard let delegate = UNUserNotificationCenter.current().delegate else { return }
        swizzle(
            on: type(of: delegate),
            original: #selector(UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:withCompletionHandler:)),
            replacement: #selector(RadarNotificationSwizzling.swizzled_userNotificationCenter(_:didReceive:withCompletionHandler:))
        )
    }

    /// Swizzle UIApplicationDelegate methods for silent push and device token capture.
    @MainActor
    @objc public static func swizzleApplicationDelegate() {
        guard let delegate = UIApplication.shared.delegate else { return }
        let delegateClass: AnyClass = type(of: delegate)

        swizzle(
            on: delegateClass,
            original: #selector(UIApplicationDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:)),
            replacement: #selector(RadarNotificationSwizzling.swizzled_application(_:didReceiveRemoteNotification:fetchCompletionHandler:))
        )

        swizzle(
            on: delegateClass,
            original: #selector(UIApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:)),
            replacement: #selector(RadarNotificationSwizzling.swizzled_application(_:didRegisterForRemoteNotificationsWithDeviceToken:))
        )
    }

    // MARK: - Swizzle mechanics

    private static func swizzle(on targetClass: AnyClass, original originalSelector: Selector, replacement swizzledSelector: Selector) {
        guard let swizzledMethod = class_getInstanceMethod(RadarNotificationSwizzling.self, swizzledSelector) else { return }

        let originalMethod = class_getInstanceMethod(targetClass, originalSelector)

        // If the target doesn't implement the original, inject our implementation directly.
        if originalMethod == nil {
            class_addMethod(
                targetClass,
                originalSelector,
                method_getImplementation(swizzledMethod),
                method_getTypeEncoding(swizzledMethod)
            )
            return
        }

        // Add our method under the swizzled selector on the target class, then exchange.
        let didAdd = class_addMethod(
            targetClass,
            swizzledSelector,
            method_getImplementation(swizzledMethod),
            method_getTypeEncoding(swizzledMethod)
        )
        if didAdd, let newMethod = class_getInstanceMethod(targetClass, swizzledSelector) {
            method_exchangeImplementations(originalMethod!, newMethod)
        }
    }

    // MARK: - Swizzled handlers

    /// Handles notification taps: deep links + conversion logging.
    @objc func swizzled_userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let options = RadarSettings.initializeOptions

        if options?.autoHandleNotificationDeepLinks == true {
            RadarNotificationSwizzling.openURL(from: response.notification)
        }
        if options?.autoLogNotificationConversions == true {
            Radar.logConversion(response: response)
        }

        // Call the original (now swizzled) implementation if it exists.
        if responds(to: #selector(swizzled_userNotificationCenter(_:didReceive:withCompletionHandler:))) {
            swizzled_userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
        } else {
            completionHandler()
        }
    }

    /// Handles silent push: fires Radar.didReceivePushNotificationPayload in parallel with the original.
    @objc func swizzled_application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        let group = DispatchGroup()
        var finalResult: UIBackgroundFetchResult = .newData

        let options = RadarSettings.initializeOptions

        if options?.silentPush == true {
            group.enter()
            Radar.didReceivePushNotificationPayload(userInfo) {
                group.leave()
            }
        }

        // Call the original if it exists.
        if responds(to: #selector(swizzled_application(_:didReceiveRemoteNotification:fetchCompletionHandler:))) {
            group.enter()
            swizzled_application(application, didReceiveRemoteNotification: userInfo) { result in
                finalResult = result
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completionHandler(finalResult)
        }
    }

    /// Captures the APNS device token.
    @objc func swizzled_application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let hexString = deviceToken.map { String(format: "%02x", $0) }.joined()
        RadarSettings.pushNotificationToken = hexString

        // Call the original if it exists.
        if responds(to: #selector(swizzled_application(_:didRegisterForRemoteNotificationsWithDeviceToken:))) {
            swizzled_application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
        }
    }

    // MARK: - Deep link handling

    @objc(openURLFromNotification:) public static func openURL(from notification: UNNotification) {
        guard notification.request.identifier.hasPrefix(RADAR_NOTIFICATION_PREFIX),
            let urlString = notification.request.content.userInfo["url"] as? String,
            let url = URL(string: urlString)
        else { return }

        DispatchQueue.main.async {
            guard UIApplication.shared.canOpenURL(url) else { return }
            UIApplication.shared.open(url)
        }
    }
}
