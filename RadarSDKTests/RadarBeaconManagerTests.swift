//
//  RadarBeaconManagerTests.swift
//  RadarSDK
//
//  Created by Alan Charles on 7/13/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Testing

@testable import RadarSDK

extension RadarSerializedTests {

    @Suite("RadarBeaconManagerSwift")
    @MainActor
    struct BeaconManagerTests {

        private static let testUUID = "2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6"

        let beaconManager = RadarBeaconManagerSwift.shared
        let mockPermissions = MockRadarPermissionsHelper()

        init() {
            Radar.initialize(publishableKey: "prj_test_pk_0000000000000000")
            beaconManager.permissionsHelper = mockPermissions
            beaconManager.stopRanging()
            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
                "useRadarModifiedBeacon": false
            ])
        }

        // MARK: - Helpers

        private static func makeRegion(
            uuid: String = testUUID,
            major: CLBeaconMajorValue = 1,
            minor: CLBeaconMinorValue = 2,
            identifier: String = "test-beacon"
        ) -> CLBeaconRegion {
            let constraint = CLBeaconIdentityConstraint(
                uuid: UUID(uuidString: uuid)!,
                major: major,
                minor: minor
            )
            return CLBeaconRegion(
                beaconIdentityConstraint: constraint,
                identifier: identifier
            )
        }

        private func makeTestBeacon() -> RadarBeacon {
            let beacon = RadarSwift.bridge!.createBeacon(
                uuid: Self.testUUID,
                major: "1",
                minor: "2",
                rssi: -65
            )
            return beacon
        }

        private func setUseRadarModifiedBeacon(_ value: Bool) {
            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
                "useRadarModifiedBeacon": value
            ])
        }

        // MARK: - rangeBeacons guard clauses

        @Test("rangeBeacons with denied auth returns permissions error")
        func rangeBeacons_authDenied_returnsPermissionsError() {
            mockPermissions.mockAuthorizationStatus = .denied

            var resultStatus: RadarStatus?
            var resultBeacons: [RadarBeacon]?

            beaconManager.rangeBeacons([makeTestBeacon()]) { status, beacons in
                resultStatus = status
                resultBeacons = beacons
            }

            #expect(resultStatus == .errorPermissions)
            #expect(resultBeacons == nil)
        }

        @Test("rangeBeacons with notDetermined auth returns permissions error")
        func rangeBeacons_authNotDetermined_returnsPermissionsError() {
            mockPermissions.mockAuthorizationStatus = .notDetermined

            var resultStatus: RadarStatus?

            beaconManager.rangeBeacons([makeTestBeacon()]) { status, _ in
                resultStatus = status
            }

            #expect(resultStatus == .errorPermissions)
        }

        @Test("rangeBeacons with restricted auth returns permissions error")
        func rangeBeacons_authRestricted_returnsPermissionsError() {
            mockPermissions.mockAuthorizationStatus = .restricted

            var resultStatus: RadarStatus?

            beaconManager.rangeBeacons([makeTestBeacon()]) { status, _ in
                resultStatus = status
            }

            #expect(resultStatus == .errorPermissions)
        }

        @Test("rangeBeacons with ranging unavailable returns bluetooth error")
        func rangeBeacons_rangingUnavailable_returnsBluetoothError() {
            mockPermissions.mockRangingAvailable = false

            var resultStatus: RadarStatus?

            beaconManager.rangeBeacons([makeTestBeacon()]) { status, _ in
                resultStatus = status
            }

            #expect(resultStatus == .errorBluetooth)
        }

        @Test("rangeBeacons with empty array returns success with empty beacons")
        func rangeBeacons_emptyBeacons_returnsSuccessEmpty() {
            var resultStatus: RadarStatus?
            var resultBeacons: [RadarBeacon]?

            beaconManager.rangeBeacons([]) { status, beacons in
                resultStatus = status
                resultBeacons = beacons
            }

            #expect(resultStatus == .success)
            #expect(resultBeacons?.isEmpty == true)
        }

        @Test("rangeBeacons with authorizedWhenInUse proceeds to ranging")
        func rangeBeacons_authorizedWhenInUse_proceeds() {
            mockPermissions.mockAuthorizationStatus = .authorizedWhenInUse

            var handlerCalled = false

            beaconManager.rangeBeacons([makeTestBeacon()]) { _, _ in
                handlerCalled = true
            }

            // Handler is queued, not called synchronously — means we passed the guards
            #expect(!handlerCalled)
        }

        // MARK: - rangeBeaconUUIDs guard clauses

        @Test("rangeBeaconUUIDs with denied auth returns permissions error")
        func rangeBeaconUUIDs_authDenied_returnsPermissionsError() {
            mockPermissions.mockAuthorizationStatus = .denied

            var resultStatus: RadarStatus?

            beaconManager.rangeBeaconUUIDs([Self.testUUID]) { status, _ in
                resultStatus = status
            }

            #expect(resultStatus == .errorPermissions)
        }

        @Test("rangeBeaconUUIDs with notDetermined auth returns permissions error")
        func rangeBeaconUUIDs_authNotDetermined_returnsPermissionsError() {
            mockPermissions.mockAuthorizationStatus = .notDetermined

            var resultStatus: RadarStatus?

            beaconManager.rangeBeaconUUIDs([Self.testUUID]) { status, _ in
                resultStatus = status
            }

            #expect(resultStatus == .errorPermissions)
        }

        @Test("rangeBeaconUUIDs with ranging unavailable returns bluetooth error")
        func rangeBeaconUUIDs_rangingUnavailable_returnsBluetoothError() {
            mockPermissions.mockRangingAvailable = false

            var resultStatus: RadarStatus?

            beaconManager.rangeBeaconUUIDs([Self.testUUID]) { status, _ in
                resultStatus = status
            }

            #expect(resultStatus == .errorBluetooth)
        }

        @Test("rangeBeaconUUIDs with empty array returns success with empty beacons")
        func rangeBeaconUUIDs_emptyUUIDs_returnsSuccessEmpty() {
            var resultStatus: RadarStatus?
            var resultBeacons: [RadarBeacon]?

            beaconManager.rangeBeaconUUIDs([]) { status, beacons in
                resultStatus = status
                resultBeacons = beacons
            }

            #expect(resultStatus == .success)
            #expect(resultBeacons?.isEmpty == true)
        }

        // MARK: - handleBeaconEntry

        @Test("handleBeaconEntry adds beacon and calls completion")
        func handleBeaconEntry_addsToNearbyAndCallsCompletion() {
            let region = Self.makeRegion()

            var resultStatus: RadarStatus?
            var resultBeacons: [RadarBeacon]?

            beaconManager.handleBeaconEntry(for: region) { status, beacons in
                resultStatus = status
                resultBeacons = beacons
            }

            #expect(resultStatus == .success)
            #expect(resultBeacons?.isEmpty == false)
        }

        @Test("handleBeaconEntry when already inside does not call completion again")
        func handleBeaconEntry_alreadyInside_doesNotCallCompletion() {
            let region = Self.makeRegion()

            // First entry
            beaconManager.handleBeaconEntry(for: region) { _, _ in }

            // Second entry
            var secondCalled = false
            beaconManager.handleBeaconEntry(for: region) { _, _ in
                secondCalled = true
            }

            #expect(!secondCalled)
        }

        @Test("handleBeaconEntry with useRadarModifiedBeacon returns early")
        func handleBeaconEntry_useRadarModifiedBeacon_earlyReturn() {
            setUseRadarModifiedBeacon(true)

            let region = Self.makeRegion()
            var called = false

            beaconManager.handleBeaconEntry(for: region) { _, _ in
                called = true
            }

            #expect(!called)
        }

        // MARK: - handleBeaconExit

        @Test("handleBeaconExit removes beacon and calls completion")
        func handleBeaconExit_removesFromNearbyAndCallsCompletion() {
            let region = Self.makeRegion()

            // Enter first
            beaconManager.handleBeaconEntry(for: region) { _, _ in }

            // Then exit
            var resultStatus: RadarStatus?
            var resultBeacons: [RadarBeacon]?

            beaconManager.handleBeaconExit(for: region) { status, beacons in
                resultStatus = status
                resultBeacons = beacons
            }

            #expect(resultStatus == .success)
            #expect(resultBeacons?.isEmpty == true)
        }

        @Test("handleBeaconExit when already outside does not call completion")
        func handleBeaconExit_alreadyOutside_doesNotCallCompletion() {
            let region = Self.makeRegion()

            var called = false
            beaconManager.handleBeaconExit(for: region) { _, _ in
                called = true
            }

            #expect(!called)
        }

        @Test("handleBeaconExit with useRadarModifiedBeacon returns early")
        func handleBeaconExit_useRadarModifiedBeacon_earlyReturn() {
            setUseRadarModifiedBeacon(true)

            let region = Self.makeRegion()
            var called = false

            beaconManager.handleBeaconExit(for: region) { _, _ in
                called = true
            }

            #expect(!called)
        }

        // MARK: - handleBeaconUUIDEntry/Exit

        @Test("handleBeaconUUIDEntry with useRadarModifiedBeacon returns early")
        func handleBeaconUUIDEntry_useRadarModifiedBeacon_earlyReturn() {
            setUseRadarModifiedBeacon(true)

            let region = Self.makeRegion()
            var called = false

            beaconManager.handleBeaconUUIDEntry(for: region) { _, _ in
                called = true
            }

            #expect(!called)
        }

        @Test("handleBeaconUUIDExit with useRadarModifiedBeacon returns early")
        func handleBeaconUUIDExit_useRadarModifiedBeacon_earlyReturn() {
            setUseRadarModifiedBeacon(true)

            let region = Self.makeRegion()
            var called = false

            beaconManager.handleBeaconUUIDExit(for: region) { _, _ in
                called = true
            }

            #expect(!called)
        }

        // MARK: - stopRanging

        @Test("stopRanging clears state and calls completion handlers")
        func stopRanging_clearsStateAndCallsHandlers() {
            var resultStatus: RadarStatus?
            var resultBeacons: [RadarBeacon]?

            // Start ranging to queue a handler
            beaconManager.rangeBeacons([makeTestBeacon()]) { status, beacons in
                resultStatus = status
                resultBeacons = beacons
            }

            // Stop should fire the queued handler
            beaconManager.stopRanging()

            #expect(resultStatus == .success)
            #expect(resultBeacons != nil)
        }
    }
}
