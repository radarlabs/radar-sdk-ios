//
//  RadarSwizzleHelper.swift
//  RadarSDK
//
//  Created by Alan Charles on 7/21/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

// Holds the swizzled handlers that RadarNotificationSwizzling exchanges onto the host app's
// notification center and application delegate classes. Each handler performs Radar logic,
// then calls through to the original implementation via the matching `swizzled_` selector.
//
// At runtime `self` is the host delegate, not a RadarSwizzleHelper, so the handlers must not
// touch instance state, and the call-through methods are `dynamic` so they dispatch through
// the Objective-C runtime and reach the exchanged original implementation.
@objc(RadarSwizzleHelper)
@objcMembers
public final class RadarSwizzleHelper: NSObject {
    override init() {
        super.init()
    }

    @objc(swizzled_userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)
    public dynamic func swizzled_userNotificationCenter(
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

        if responds(
            to: #selector(RadarSwizzleHelper.swizzled_userNotificationCenter(_:didReceive:withCompletionHandler:))
        ) {
            swizzled_userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
        } else {
            completionHandler()
        }
    }

    @objc(swizzled_application:didReceiveRemoteNotification:fetchCompletionHandler:)
    public dynamic func swizzled_application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        let group = DispatchGroup()
        // Written before the matching leave() and read only in notify, so the group orders access.
        nonisolated(unsafe) var finalResult = UIBackgroundFetchResult.newData
        nonisolated(unsafe) let completionHandler = completionHandler

        if RadarSettings.initializeOptions?.silentPush == true {
            group.enter()
            Radar.didReceivePushNotificationPayload(userInfo) {
                group.leave()
            }
        }

        if responds(
            to: #selector(RadarSwizzleHelper.swizzled_application(_:didReceiveRemoteNotification:fetchCompletionHandler:))
        ) {
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

    @objc(swizzled_application:didRegisterForRemoteNotificationsWithDeviceToken:)
    public dynamic func swizzled_application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        RadarSettings.pushNotificationToken = deviceToken.map { String(format: "%02x", $0) }.joined()

        if responds(
            to: #selector(RadarSwizzleHelper.swizzled_application(_:didRegisterForRemoteNotificationsWithDeviceToken:))
        ) {
            swizzled_application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
        }
    }
}
