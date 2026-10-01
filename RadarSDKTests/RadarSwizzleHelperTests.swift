//
//  RadarSwizzleHelperTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import ObjectiveC
import Testing
import UIKit
import UserNotifications

@testable import RadarSDK

// Mirrors the delegate selectors RadarNotificationSwizzling targets. Optional parameters let the
// tests call them without a UIApplication or notification center, which a hostless test bundle lacks.
@objc private protocol RadarSwizzleTestTarget {
    @objc(application:didRegisterForRemoteNotificationsWithDeviceToken:)
    optional func didRegister(_ application: UIApplication?, deviceToken: Data)

    @objc(application:didReceiveRemoteNotification:fetchCompletionHandler:)
    optional func didReceiveRemoteNotification(
        _ application: UIApplication?,
        userInfo: [AnyHashable: Any],
        completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    )

    @objc(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)
    optional func didReceiveResponse(
        _ center: UNUserNotificationCenter?,
        response: UNNotificationResponse?,
        completionHandler: @escaping () -> Void
    )
}

private final class RegisterDelegate: NSObject, RadarSwizzleTestTarget {
    nonisolated(unsafe) var receivedToken: Data?

    func didRegister(_ application: UIApplication?, deviceToken: Data) {
        receivedToken = deviceToken
    }
}

private final class RemoteNotificationDelegate: NSObject, RadarSwizzleTestTarget {
    nonisolated(unsafe) var receivedUserInfo: [AnyHashable: Any]?

    func didReceiveRemoteNotification(
        _ application: UIApplication?,
        userInfo: [AnyHashable: Any],
        completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        receivedUserInfo = userInfo
        completionHandler(.noData)
    }
}

private final class ResponseDelegate: NSObject, RadarSwizzleTestTarget {
    nonisolated(unsafe) var callCount = 0

    func didReceiveResponse(
        _ center: UNUserNotificationCenter?,
        response: UNNotificationResponse?,
        completionHandler: @escaping () -> Void
    ) {
        callCount += 1
        completionHandler()
    }
}

private final class EmptyRemoteNotificationDelegate: NSObject, RadarSwizzleTestTarget {}
private final class EmptyResponseDelegate: NSObject, RadarSwizzleTestTarget {}

@Suite("RadarSwizzleHelperTests", .serialized)
struct RadarSwizzleHelperTests {

    private static let registerSelector = Selector(("application:didRegisterForRemoteNotificationsWithDeviceToken:"))
    private static let remoteNotificationSelector = Selector(("application:didReceiveRemoteNotification:fetchCompletionHandler:"))
    private static let responseSelector = Selector(("userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:"))

    private static let swizzledRegisterSelector = Selector(("swizzled_application:didRegisterForRemoteNotificationsWithDeviceToken:"))
    private static let swizzledRemoteNotificationSelector = Selector(
        ("swizzled_application:didReceiveRemoteNotification:fetchCompletionHandler:"))
    private static let swizzledResponseSelector = Selector(
        ("swizzled_userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:"))

    // Same exchange RadarNotificationSwizzling performs on the host app's delegate class.
    private static func swizzle(_ targetClass: AnyClass, original: Selector, replacement: Selector) throws {
        let swizzledMethod = try #require(class_getInstanceMethod(RadarSwizzleHelper.self, replacement))
        let implementation = method_getImplementation(swizzledMethod)
        let types = method_getTypeEncoding(swizzledMethod)

        guard let originalMethod = class_getInstanceMethod(targetClass, original) else {
            #expect(class_addMethod(targetClass, original, implementation, types))
            return
        }
        #expect(class_addMethod(targetClass, replacement, implementation, types))
        let newMethod = try #require(class_getInstanceMethod(targetClass, replacement))
        method_exchangeImplementations(originalMethod, newMethod)
    }

    private static func withSettings(_ body: () async throws -> Void) async rethrows {
        let savedOptions = RadarSettings.initializeOptions
        let savedToken = RadarSettings.pushNotificationToken
        RadarSettings.initializeOptions = nil
        defer {
            RadarSettings.initializeOptions = savedOptions
            RadarSettings.pushNotificationToken = savedToken
        }
        try await body()
    }

    @Test("Keeps the Objective-C class name and swizzled selectors")
    func keepsObjectiveCContract() {
        #expect(NSClassFromString("RadarSwizzleHelper") == RadarSwizzleHelper.self)
        #expect(NSStringFromClass(RadarSwizzleHelper.self) == "RadarSwizzleHelper")
        #expect(class_getInstanceMethod(RadarSwizzleHelper.self, Self.swizzledRegisterSelector) != nil)
        #expect(class_getInstanceMethod(RadarSwizzleHelper.self, Self.swizzledRemoteNotificationSelector) != nil)
        #expect(class_getInstanceMethod(RadarSwizzleHelper.self, Self.swizzledResponseSelector) != nil)
    }

    @Test("Device token registration saves the hex token and calls the original")
    func registerSavesHexTokenAndCallsOriginal() async throws {
        try await Self.withSettings {
            try Self.swizzle(RegisterDelegate.self, original: Self.registerSelector, replacement: Self.swizzledRegisterSelector)

            let delegate = RegisterDelegate()
            let token = Data([0x00, 0x0f, 0xa0, 0xff, 0x12])
            (delegate as RadarSwizzleTestTarget).didRegister?(nil, deviceToken: token)

            #expect(RadarSettings.pushNotificationToken == "000fa0ff12")
            #expect(delegate.receivedToken == token)
        }
    }

    @Test("Remote notification calls the original and passes its result through")
    func remoteNotificationCallsOriginal() async throws {
        try await Self.withSettings {
            try Self.swizzle(
                RemoteNotificationDelegate.self,
                original: Self.remoteNotificationSelector,
                replacement: Self.swizzledRemoteNotificationSelector
            )

            let delegate = RemoteNotificationDelegate()
            let (result, isMainThread) = await withCheckedContinuation { continuation in
                (delegate as RadarSwizzleTestTarget).didReceiveRemoteNotification?(nil, userInfo: ["key": "value"]) { result in
                    continuation.resume(returning: (result, Thread.isMainThread))
                }
            }

            #expect(result == .noData)
            #expect(isMainThread)
            #expect(delegate.receivedUserInfo?["key"] as? String == "value")
        }
    }

    @Test("Remote notification without an original handler completes with new data")
    func remoteNotificationWithoutOriginalCompletesWithNewData() async throws {
        try await Self.withSettings {
            try Self.swizzle(
                EmptyRemoteNotificationDelegate.self,
                original: Self.remoteNotificationSelector,
                replacement: Self.swizzledRemoteNotificationSelector
            )

            let delegate = EmptyRemoteNotificationDelegate()
            let result = await withCheckedContinuation { continuation in
                (delegate as RadarSwizzleTestTarget).didReceiveRemoteNotification?(nil, userInfo: [:]) { result in
                    continuation.resume(returning: result)
                }
            }

            #expect(result == .newData)
        }
    }

    @Test("Notification response calls the original handler once")
    func responseCallsOriginal() async throws {
        try await Self.withSettings {
            try Self.swizzle(ResponseDelegate.self, original: Self.responseSelector, replacement: Self.swizzledResponseSelector)

            let delegate = ResponseDelegate()
            nonisolated(unsafe) var completed = 0
            (delegate as RadarSwizzleTestTarget).didReceiveResponse?(nil, response: nil) { completed += 1 }

            #expect(delegate.callCount == 1)
            #expect(completed == 1)
        }
    }

    @Test("Notification response without an original handler still completes")
    func responseWithoutOriginalCompletes() async throws {
        try await Self.withSettings {
            try Self.swizzle(EmptyResponseDelegate.self, original: Self.responseSelector, replacement: Self.swizzledResponseSelector)

            let delegate = EmptyResponseDelegate()
            nonisolated(unsafe) var completed = 0
            (delegate as RadarSwizzleTestTarget).didReceiveResponse?(nil, response: nil) { completed += 1 }

            #expect(completed == 1)
        }
    }
}
