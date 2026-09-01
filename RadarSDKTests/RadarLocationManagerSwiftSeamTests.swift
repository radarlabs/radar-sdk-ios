//
//  RadarLocationManagerSwiftSeamTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import Testing

@testable import RadarSDK

private func invokeStartUpdates(on manager: RadarLocationManager, interval: Int32, blueBar: Bool) {
    typealias StartUpdatesFunction = @convention(c) (AnyObject, Selector, Int32, Bool) -> Void

    let selector = NSSelectorFromString("startUpdates:blueBar:")
    guard let implementation = manager.method(for: selector) else {
        preconditionFailure("RadarLocationManager does not respond to startUpdates:blueBar:")
    }

    unsafeBitCast(implementation, to: StartUpdatesFunction.self)(manager, selector, interval, blueBar)
}

private func invokeStopUpdates(on manager: RadarLocationManager) {
    manager.perform(NSSelectorFromString("stopUpdates"))
}

extension RadarSerializedTests {
    @Suite(.serialized)
    actor RadarLocationManagerSwiftSeamTests {

        // MARK: - startTracking(options:)

        @Test("start tracking reports a permissions error without changing state when unauthorized")
        @MainActor
        func startTrackingRejectsUnauthorizedStatus() {
            RadarLocationManagerSwiftTestHelpers.withMockedSwiftTrackingDependencies(authorizationStatus: .denied) { bridge in
                let existingOptions = RadarTrackingOptions.presetContinuous
                RadarSettings.trackingOptions = existingOptions

                RadarLocationManagerSwift.startTracking(options: .presetResponsive)

                #expect(bridge.lastFailStatus == .errorPermissions)
                #expect(bridge.updateTrackingCallCount == 0)
                #expect(RadarSettings.tracking == false)
                #expect(RadarSettings.trackingOptions == existingOptions)
            }
        }

        @Test(arguments: [CLAuthorizationStatus.authorizedWhenInUse, .authorizedAlways])
        @MainActor
        func startTrackingAcceptsAuthorizedStatus(authorizationStatus: CLAuthorizationStatus) {
            RadarLocationManagerSwiftTestHelpers.withMockedSwiftTrackingDependencies(authorizationStatus: authorizationStatus) { bridge in
                let options = RadarTrackingOptions.presetResponsive

                RadarLocationManagerSwift.startTracking(options: options)

                #expect(bridge.lastFailStatus == nil)
                #expect(bridge.updateTrackingCallCount == 1)
                #expect(RadarSettings.tracking == true)
                #expect(RadarSettings.trackingOptions == options)
            }
        }

        @Test("public start tracking method routes to the Swift twin when enabled")
        @MainActor
        func publicStartTrackingRoutesToSwiftTwinWhenFlagEnabled() {
            RadarLocationManagerSwiftTestHelpers.withMockedSwiftTrackingDependencies(authorizationStatus: .denied) { bridge in
                RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
                    "useSwiftLocationManager": true
                ])

                RadarLocationManager.sharedInstance().startTracking(with: .presetResponsive)

                #expect(bridge.lastFailStatus == .errorPermissions)
                #expect(bridge.updateTrackingCallCount == 0)
                #expect(RadarSettings.tracking == false)
            }
        }

        // MARK: - updateTrackingFromMeta — public method routing

        @Test("Public updateTrackingFromMeta routes to the Swift twin when useSwiftLocationManager is enabled")
        func publicUpdateTrackingFromMetaRoutesToSwiftTwinWhenFlagEnabled() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            let bridge = MockRadarSwiftBridge()
            let originalBridge = RadarSwift.bridge
            RadarSwift.bridge = bridge
            defer {
                RadarSwift.bridge = originalBridge
                RadarLocationManagerSwiftTestHelpers.clearState()
            }

            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: ["useSwiftLocationManager": true])
            let options = RadarLocationManagerSwiftTestHelpers.trackingOptions(beacons: true)
            let meta = RadarMeta.from(dictionary: ["trackingOptions": options.dictionaryValue()])!

            RadarLocationManager.sharedInstance().perform(
                #selector(RadarLocationManagerSwift.updateTrackingFromMeta(_:)),
                with: meta
            )

            #expect(RadarSettings.remoteTrackingOptions == options)
            #expect(bridge.updateTrackingFromInitializeCallCount == 1)
            #expect(bridge.callOrder == ["updateTrackingFromInitialize"])
        }

        @Test("Public updateTrackingFromMeta keeps the Objective-C body when useSwiftLocationManager is disabled")
        func publicUpdateTrackingFromMetaUsesObjCBodyWhenFlagDisabled() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            let bridge = MockRadarSwiftBridge()
            let originalBridge = RadarSwift.bridge
            RadarSwift.bridge = bridge
            defer {
                RadarSwift.bridge = originalBridge
                RadarLocationManagerSwiftTestHelpers.clearState()
            }

            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: ["useSwiftLocationManager": false])
            let options = RadarLocationManagerSwiftTestHelpers.trackingOptions(beacons: true)
            let meta = RadarMeta.from(dictionary: ["trackingOptions": options.dictionaryValue()])!

            RadarLocationManager.sharedInstance().perform(
                #selector(RadarLocationManagerSwift.updateTrackingFromMeta(_:)),
                with: meta
            )

            #expect(RadarSettings.remoteTrackingOptions == options)
            #expect(bridge.callOrder.isEmpty)
        }

        // MARK: - startUpdates and stopUpdates — public method routing

        @Test("Public timer methods route to Swift when useSwiftLocationManager is enabled")
        func publicTimerMethodsRouteToSwiftTwinWhenFlagEnabled() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            let manager = RadarLocationManager.sharedInstance()
            let originalLocationManager = manager.locationManager
            let originalLowPowerLocationManager = manager.lowPowerLocationManager
            let locationManager = TrackingCLLocationManager()
            let lowPowerLocationManager = TrackingCLLocationManager()
            defer {
                invokeStopUpdates(on: manager)
                manager.perform(NSSelectorFromString("cancelPendingShutdown"))
                manager.locationManager = originalLocationManager
                manager.lowPowerLocationManager = originalLowPowerLocationManager
                RadarLocationManagerSwiftTestHelpers.clearState()
            }

            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: ["useSwiftLocationManager": true])
            RadarSettings.tracking = true
            manager.locationManager = locationManager
            manager.lowPowerLocationManager = lowPowerLocationManager

            invokeStartUpdates(on: manager, interval: 5, blueBar: true)
            invokeStopUpdates(on: manager)

            #expect(locationManager.startUpdatingLocationCallCount == 1)
            #expect(locationManager.stopUpdatingLocationCallCount == 1)
            #expect(lowPowerLocationManager.startUpdatingLocationCallCount == 1)
        }

        @Test("Public timer methods keep the Objective-C body when useSwiftLocationManager is disabled")
        func publicTimerMethodsUseObjCBodyWhenFlagDisabled() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            let manager = RadarLocationManager.sharedInstance()
            let originalLocationManager = manager.locationManager
            let originalLowPowerLocationManager = manager.lowPowerLocationManager
            let locationManager = TrackingCLLocationManager()
            let lowPowerLocationManager = TrackingCLLocationManager()
            defer {
                invokeStopUpdates(on: manager)
                manager.perform(NSSelectorFromString("cancelPendingShutdown"))
                manager.locationManager = originalLocationManager
                manager.lowPowerLocationManager = originalLowPowerLocationManager
                RadarLocationManagerSwiftTestHelpers.clearState()
            }

            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: ["useSwiftLocationManager": false])
            RadarSettings.tracking = true
            manager.locationManager = locationManager
            manager.lowPowerLocationManager = lowPowerLocationManager

            invokeStartUpdates(on: manager, interval: 5, blueBar: true)
            invokeStopUpdates(on: manager)

            #expect(locationManager.startUpdatingLocationCallCount == 1)
            #expect(locationManager.stopUpdatingLocationCallCount == 1)
            #expect(lowPowerLocationManager.startUpdatingLocationCallCount == 1)
        }

        // MARK: - stopTracking — public method routing

        @Test("Public stopTracking routes to the Swift twin when useSwiftLocationManager is enabled")
        func publicStopTrackingRoutesToSwiftTwinWhenFlagEnabled() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            let bridge = MockRadarSwiftBridge()
            let originalBridge = RadarSwift.bridge
            let manager = RadarLocationManager.sharedInstance()
            let originalLocationManager = manager.locationManager
            let originalActivityManager = manager.activityManager
            RadarSwift.bridge = bridge
            defer {
                RadarSwift.bridge = originalBridge
                manager.locationManager = originalLocationManager
                manager.activityManager = originalActivityManager
                RadarLocationManagerSwiftTestHelpers.clearState()
            }

            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: ["useSwiftLocationManager": true])
            RadarSettings.tracking = true
            manager.locationManager = TrackingCLLocationManager()
            manager.activityManager = TrackingRadarActivityManager()

            manager.stopTracking()

            #expect(RadarSettings.tracking == false)
            #expect(bridge.callOrder == ["stopIndoorTracking", "updateTracking"])
        }

        @Test("Public stopTracking keeps the Objective-C body when useSwiftLocationManager is disabled")
        func publicStopTrackingUsesObjCBodyWhenFlagDisabled() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            let bridge = MockRadarSwiftBridge()
            let originalBridge = RadarSwift.bridge
            let manager = RadarLocationManager.sharedInstance()
            RadarSwift.bridge = bridge
            defer {
                RadarSwift.bridge = originalBridge
                RadarLocationManagerSwiftTestHelpers.clearState()
            }

            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: ["useSwiftLocationManager": false])
            RadarSettings.tracking = true

            manager.stopTracking()

            #expect(RadarSettings.tracking == false)
            #expect(bridge.callOrder.isEmpty)
        }

        // MARK: - restartPreviousTrackingOptions — Swift twin

        @Test("Swift twin calls Radar.stopTracking and clears previousTrackingOptions when none to restart")
        func swiftTwinStopsTrackingWhenNoPreviousOptions() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }

            // Seed `tracking = true` to observe that `Radar.stopTracking()` actually flipped it off.
            RadarSettings.tracking = true

            RadarLocationManagerSwift.restartPreviousTrackingOptions()

            #expect(RadarSettings.previousTrackingOptions == nil)
            #expect(RadarSettings.tracking == false)
        }

        @Test("Swift twin restarts tracking with previous options and clears previousTrackingOptions")
        @MainActor
        func swiftTwinRestartsTrackingAndClearsPreviousOptions() {
            RadarLocationManagerSwiftTestHelpers.withMockedSwiftTrackingDependencies { bridge in
                RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
                    "useSwiftLocationManager": true
                ])
                let previousOptions = RadarTrackingOptions.presetResponsive
                RadarSettings.previousTrackingOptions = previousOptions

                RadarLocationManagerSwift.restartPreviousTrackingOptions()

                #expect(RadarSettings.previousTrackingOptions == nil)
                #expect(RadarSettings.tracking == true)
                #expect(RadarSettings.trackingOptions == previousOptions)
                #expect(bridge.updateTrackingCallCount == 1)
            }
        }

        // MARK: - restartPreviousTrackingOptions — public method routing

        @Test("Public method routes to Swift twin when useSwiftLocationManager is enabled")
        @MainActor
        func publicMethodRoutesToSwiftTwinWhenFlagEnabled() {
            RadarLocationManagerSwiftTestHelpers.withMockedSwiftTrackingDependencies { bridge in
                RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
                    "useSwiftLocationManager": true
                ])
                let previousOptions = RadarTrackingOptions.presetResponsive
                RadarSettings.previousTrackingOptions = previousOptions

                RadarLocationManager.sharedInstance().restartPreviousTrackingOptions()

                #expect(RadarSettings.previousTrackingOptions == nil)
                #expect(RadarSettings.tracking == true)
                #expect(RadarSettings.trackingOptions == previousOptions)
                #expect(bridge.updateTrackingCallCount == 1)
            }
        }

        @Test("Public method uses ObjC body when useSwiftLocationManager is disabled")
        func publicMethodUsesObjCBodyWhenFlagDisabled() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }

            RadarLocationManagerSwiftTestHelpers.installAuthorizedPermissions()
            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
                "useSwiftLocationManager": false
            ])
            let previousOptions = RadarTrackingOptions.presetResponsive
            RadarSettings.previousTrackingOptions = previousOptions

            RadarLocationManager.sharedInstance().restartPreviousTrackingOptions()

            // ObjC body should land in the same end state as the Swift twin.
            #expect(RadarSettings.previousTrackingOptions == nil)
            #expect(RadarSettings.tracking == true)
            #expect(RadarSettings.trackingOptions == previousOptions)
        }

        // MARK: - Beacon sync — public method routing

        @Test("Public replaceSyncedBeacons routes to Swift twin when flag enabled")
        func publicReplaceSyncedBeaconsRoutesToSwiftTwinWhenFlagEnabled() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }

            // useRadarModifiedBeacon on so the Swift twin short-circuits — exercises only
            // that the dispatch shim routes to the Swift implementation, not the body.
            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
                "useSwiftLocationManager": true,
                "useRadarModifiedBeacon": true,
            ])

            RadarLocationManager.sharedInstance().replaceSyncedBeacons([])
        }

        @Test("ObjC startTrackingWithOptions: does not require the main thread")
        func publicStartTrackingSurvivesBackgroundThread() async {
            await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    RadarLocationManagerSwiftTestHelpers.withMockedSwiftTrackingDependencies { bridge in
                        RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
                            "useSwiftLocationManager": true
                        ])
                        #expect(!Thread.isMainThread)

                        RadarLocationManager.sharedInstance().startTracking(with: .presetResponsive)

                        #expect(bridge.updateTrackingCallCount == 1)
                        #expect(RadarSettings.tracking == true)
                    }
                    continuation.resume()
                }
            }
        }

        @Test("restartPreviousTrackingOptions round-trips through ObjC off the main thread")
        func restartPreviousTrackingOptionsSurvivesBackgroundThread() async {
            await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    RadarLocationManagerSwiftTestHelpers.withMockedSwiftTrackingDependencies { bridge in
                        RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
                            "useSwiftLocationManager": true
                        ])
                        let previousOptions = RadarTrackingOptions.presetResponsive
                        RadarSettings.previousTrackingOptions = previousOptions
                        #expect(!Thread.isMainThread)

                        RadarLocationManagerSwift.restartPreviousTrackingOptions()

                        #expect(RadarSettings.previousTrackingOptions == nil)
                        #expect(RadarSettings.tracking == true)
                        #expect(RadarSettings.trackingOptions == previousOptions)
                        #expect(bridge.updateTrackingCallCount == 1)
                    }
                    continuation.resume()
                }
            }
        }
    }
}
