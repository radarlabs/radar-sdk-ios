//
//  RadarLocationManagerObjCRegionTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import Testing

@testable import RadarSDK

// Covers `replaceBubbleGeofence:radius:` and `removeBubbleGeofence` in RadarLocationManager.m,
// the bodies that run while `useSwiftLocationManager` is off. The Swift twins in
// RadarLocationManager+Swift.swift are covered by RadarLocationManagerSwiftRegionTests.

private func invokeReplaceBubbleGeofence(on manager: RadarLocationManager, location: CLLocation, radius: Int32) {
    typealias ReplaceBubbleGeofenceFunction = @convention(c) (AnyObject, Selector, CLLocation, Int32) -> Void

    let selector = NSSelectorFromString("replaceBubbleGeofence:radius:")
    guard let implementation = manager.method(for: selector) else {
        preconditionFailure("RadarLocationManager does not respond to replaceBubbleGeofence:radius:")
    }

    unsafeBitCast(implementation, to: ReplaceBubbleGeofenceFunction.self)(manager, selector, location, radius)
}

private func invokeRemoveBubbleGeofence(on manager: RadarLocationManager) {
    manager.perform(NSSelectorFromString("removeBubbleGeofence"))
}

extension RadarSerializedTests {
    @Suite(.serialized)
    actor RadarLocationManagerObjCRegionTests {
        @Test("Objective-C back-to-back replaceBubbleGeofence calls leave one bubble while monitoredRegions is stale")
        func objCReplaceBubbleGeofenceBackToBackLeavesOneBubble() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            let manager = RadarLocationManager.sharedInstance()
            let originalLocationManager = manager.locationManager
            let locationManager = TrackingCLLocationManager()
            defer {
                manager.locationManager = originalLocationManager
                RadarLocationManagerSwiftTestHelpers.clearState()
            }

            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: ["useSwiftLocationManager": false])
            RadarSettings.tracking = true
            manager.locationManager = locationManager
            locationManager.staleMonitoredRegions = []
            let location = CLLocation(latitude: 40.7, longitude: -74.0)

            for _ in 0..<3 {
                invokeReplaceBubbleGeofence(on: manager, location: location, radius: 100)
            }

            let bubbleRegions = locationManager.trackedRegions.filter { $0.identifier.hasPrefix("radar_bubble_") }
            #expect(bubbleRegions.count == 1)
        }

        @Test("Objective-C removeBubbleGeofence removes the last registered bubble while monitoredRegions is stale")
        func objCRemoveBubbleGeofenceRemovesLastRegisteredBubble() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            let manager = RadarLocationManager.sharedInstance()
            let originalLocationManager = manager.locationManager
            let locationManager = TrackingCLLocationManager()
            defer {
                manager.locationManager = originalLocationManager
                RadarLocationManagerSwiftTestHelpers.clearState()
            }

            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: ["useSwiftLocationManager": false])
            RadarSettings.tracking = true
            manager.locationManager = locationManager
            locationManager.staleMonitoredRegions = []

            invokeReplaceBubbleGeofence(on: manager, location: CLLocation(latitude: 40.7, longitude: -74.0), radius: 100)
            invokeRemoveBubbleGeofence(on: manager)

            #expect(locationManager.trackedRegions.isEmpty)
        }
    }
}
