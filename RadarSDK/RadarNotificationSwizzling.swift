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

    @MainActor
    @objc public static func swizzleNotificationCenterDelegate() {
        guard let delegate = UNUserNotificationCenter.current().delegate else { return }
        swizzle(
            on: type(of: delegate),
            original: #selector(UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:withCompletionHandler:)),
            replacement: #selector(RadarSwizzleHelper.swizzled_userNotificationCenter(_:didReceive:withCompletionHandler:))
        )
    }

    @MainActor
    @objc public static func swizzleApplicationDelegate() {
        guard let delegate = UIApplication.shared.delegate else { return }
        let delegateClass: AnyClass = type(of: delegate)

        swizzle(
            on: delegateClass,
            original: #selector(UIApplicationDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:)),
            replacement: #selector(RadarSwizzleHelper.swizzled_application(_:didReceiveRemoteNotification:fetchCompletionHandler:))
        )

        swizzle(
            on: delegateClass,
            original: #selector(UIApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:)),
            replacement: #selector(RadarSwizzleHelper.swizzled_application(_:didRegisterForRemoteNotificationsWithDeviceToken:))
        )
    }

    private static func swizzle(on targetClass: AnyClass, original originalSelector: Selector, replacement swizzledSelector: Selector) {
        guard let swizzledMethod = class_getInstanceMethod(RadarSwizzleHelper.self, swizzledSelector) else { return }

        let originalMethod = class_getInstanceMethod(targetClass, originalSelector)

        if originalMethod == nil {
            class_addMethod(
                targetClass,
                originalSelector,
                method_getImplementation(swizzledMethod),
                method_getTypeEncoding(swizzledMethod)
            )
            return
        }

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
