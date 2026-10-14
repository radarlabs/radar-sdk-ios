//
//  RadarPermissionsHelperTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import Testing

@testable import RadarSDK

// Covers the Swift and Objective-C permissions helpers, which read the status the authorization
// callback caches in `RadarState` and only ask Core Location before a status has been cached.
extension RadarSerializedTests {
    @Suite(.serialized)
    struct RadarPermissionsHelperTests {

        private func withCachedStatus(_ status: CLAuthorizationStatus, _ body: () -> Void) {
            let state = RadarState()
            let originalStatus = state.locationAuthorizationStatus
            defer { state.locationAuthorizationStatus = originalStatus }
            state.locationAuthorizationStatus = status

            body()
        }

        @Test(
            "The helpers return the cached status",
            arguments: [CLAuthorizationStatus.authorizedAlways, .authorizedWhenInUse, .denied, .restricted]
        )
        func helpersReturnCachedStatus(status: CLAuthorizationStatus) {
            withCachedStatus(status) {
                #expect(RadarPermissionsHelperSwift().locationAuthorizationStatus() == status)
                #expect(RadarPermissionsHelper().locationAuthorizationStatus() == status)
            }
        }

        @Test("The helpers ask Core Location before a status is cached")
        func helpersAskCoreLocationBeforeStatusIsCached() {
            withCachedStatus(.notDetermined) {
                let status = CLLocationManager.authorizationStatus()
                #expect(RadarPermissionsHelperSwift().locationAuthorizationStatus() == status)
                #expect(RadarPermissionsHelper().locationAuthorizationStatus() == status)
            }
        }
    }
}
