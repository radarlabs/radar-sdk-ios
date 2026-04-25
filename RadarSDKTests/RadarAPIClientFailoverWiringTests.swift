//
//  RadarAPIClientFailoverWiringTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import ObjectiveC
import Testing
@testable import RadarSDK

extension RadarSerializedTests {

    @Suite(.serialized)
    final class RadarAPIClientFailoverWiringTests {

        private let apiHelperMock = RadarAPIHelperMock()
        private let apiClient: AnyObject

        init() {
            Radar.initialize(publishableKey: "prj_test_pk_0000000000000000")
            apiClient = ObjCAPIClientBridge.sharedInstance()
            ObjCAPIClientBridge.setAPIHelper(apiHelperMock, on: apiClient)
            RadarFailoverAPICoordinator.verifiedShared.reset()
        }

        deinit {
            RadarFailoverAPICoordinator.verifiedShared.reset()
            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: nil)
        }

        private func setFailoverFlag(_ enabled: Bool) {
            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: ["useVerifiedHostFailover": enabled])
        }

        private func capturedConfigUrl(verified: Bool) async -> String? {
            await withCheckedContinuation { continuation in
                ObjCAPIClientBridge.getConfig(on: apiClient, usage: "wiring-test", verified: verified) { _, _ in
                    continuation.resume(returning: self.apiHelperMock.lastUrl)
                }
            }
        }

        private func capturedTrackUrl(verified: Bool) async -> String? {
            await withCheckedContinuation { continuation in
                let location = CLLocation(latitude: 40.0, longitude: -73.0)
                ObjCAPIClientBridge.track(on: apiClient, location: location, verified: verified) { _, _, _, _, _, _, _ in
                    continuation.resume(returning: self.apiHelperMock.lastUrl)
                }
            }
        }

        @Test func verifiedConfigUsesPrimaryThenSecondaryWhenFailoverEnabled() async {
            setFailoverFlag(true)
            apiHelperMock.mockStatus = .errorServer
            apiHelperMock.mockResponse = ["error": "cloudflare"]

            let firstUrl = await capturedConfigUrl(verified: true)
            let secondUrl = await capturedConfigUrl(verified: true)

            #expect(firstUrl?.contains("api-verified.radar.io") == true)
            #expect(firstUrl?.contains("api-verified.radar.com") == false)
            #expect(secondUrl?.contains("api-verified.radar.com") == true)
        }

        @Test func verifiedConfigSkipsCoordinatorWhenFailoverDisabled() async {
            setFailoverFlag(false)
            apiHelperMock.mockStatus = .errorServer
            apiHelperMock.mockResponse = ["error": "cloudflare"]

            let firstUrl = await capturedConfigUrl(verified: true)
            let secondUrl = await capturedConfigUrl(verified: true)

            #expect(firstUrl?.contains("api-verified.radar.io") == true)
            #expect(secondUrl?.contains("api-verified.radar.io") == true)
            #expect(secondUrl?.contains("api-verified.radar.com") == false)
        }

        @Test func verifiedTrackUsesPrimaryThenSecondaryWhenFailoverEnabled() async {
            setFailoverFlag(true)
            apiHelperMock.mockStatus = .errorNetwork
            apiHelperMock.mockResponse = [:]

            let firstUrl = await capturedTrackUrl(verified: true)
            let secondUrl = await capturedTrackUrl(verified: true)

            #expect(firstUrl == "https://api-verified.radar.io/v1/track")
            #expect(secondUrl == "https://api-verified.radar.com/v1/track")
        }
    }
}

private enum ObjCAPIClientBridge {

    static func sharedInstance() -> AnyObject {
        let selector = NSSelectorFromString("sharedInstance")
        guard let method = class_getClassMethod(apiClientClass, selector) else {
            fatalError("RadarAPIClient sharedInstance selector not found")
        }

        typealias Function = @convention(c) (AnyClass, Selector) -> AnyObject
        let function = unsafeBitCast(method_getImplementation(method), to: Function.self)
        return function(apiClientClass, selector)
    }

    static func setAPIHelper(_ helper: RadarAPIHelperMock, on client: AnyObject) {
        let selector = NSSelectorFromString("setApiHelper:")
        let implementation = client.method(for: selector)

        typealias Function = @convention(c) (AnyObject, Selector, AnyObject) -> Void
        let function = unsafeBitCast(implementation, to: Function.self)
        function(client, selector, helper)
    }

    static func getConfig(
        on client: AnyObject,
        usage: String,
        verified: Bool,
        completion: @escaping @convention(block) (RadarStatus, AnyObject?) -> Void
    ) {
        let selector = NSSelectorFromString("getConfigForUsage:verified:completionHandler:")
        let implementation = client.method(for: selector)

        typealias Function = @convention(c) (AnyObject, Selector, NSString?, Bool, @escaping @convention(block) (RadarStatus, AnyObject?) -> Void) -> Void
        let function = unsafeBitCast(implementation, to: Function.self)
        function(client, selector, usage as NSString, verified, completion)
    }

    static func track(
        on client: AnyObject,
        location: CLLocation,
        verified: Bool,
        completion: @escaping @convention(block) (RadarStatus, NSDictionary?, NSArray?, AnyObject?, NSArray?, AnyObject?, AnyObject?) -> Void
    ) {
        let selector = NSSelectorFromString("trackWithLocation:stopped:foreground:source:replayed:beacons:indoorScan:verified:fraudPayload:expectedCountryCode:expectedStateCode:reason:transactionId:completionHandler:")
        let implementation = client.method(for: selector)

        typealias Function = @convention(c) (
            AnyObject,
            Selector,
            CLLocation,
            Bool,
            Bool,
            RadarLocationSource,
            Bool,
            NSArray?,
            NSString?,
            Bool,
            NSString?,
            NSString?,
            NSString?,
            NSString?,
            NSString?,
            @escaping @convention(block) (RadarStatus, NSDictionary?, NSArray?, AnyObject?, NSArray?, AnyObject?, AnyObject?) -> Void
        ) -> Void
        let function = unsafeBitCast(implementation, to: Function.self)
        function(
            client,
            selector,
            location,
            false,
            true,
            RadarLocationSource(rawValue: 2)!,
            false,
            nil,
            nil,
            verified,
            nil,
            nil,
            nil,
            nil,
            nil,
            completion
        )
    }

    private static var apiClientClass: AnyClass {
        guard let cls = NSClassFromString("RadarAPIClient") else {
            fatalError("Objective-C RadarAPIClient class not found")
        }
        return cls
    }
}
