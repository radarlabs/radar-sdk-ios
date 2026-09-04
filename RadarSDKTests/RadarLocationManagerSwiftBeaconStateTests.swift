//
//  RadarLocationManagerSwiftBeaconStateTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Testing

@testable import RadarSDK

extension RadarSerializedTests {
    @Suite(.serialized)
    @MainActor
    struct RadarLocationManagerBeaconStateTests {
        private let beaconManager = RadarBeaconManagerSwift.shared

        private func withBeaconDependencies(_ body: () -> Void) {
            let originalBridge = RadarSwift.bridge
            let originalPermissionsHelper = beaconManager.permissionsHelper
            let originalBeaconUUIDs = RadarSettings.beaconUUIDs

            RadarLocationManagerSwiftTestHelpers.clearState()
            RadarSwift.bridge = MockRadarSwiftBridge()
            beaconManager.permissionsHelper = MockRadarPermissionsHelper()
            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
                "useRadarModifiedBeacon": false
            ])
            RadarSettings.beaconUUIDs = []
            RadarSettings.tracking = false
            let trackingOptions = RadarTrackingOptions.presetResponsive
            trackingOptions.syncLocations = .events
            RadarSettings.trackingOptions = trackingOptions
            beaconManager.stopRanging()

            defer {
                beaconManager.stopRanging()
                RadarSwift.bridge = originalBridge
                beaconManager.permissionsHelper = originalPermissionsHelper
                RadarSettings.beaconUUIDs = originalBeaconUUIDs
                RadarLocationManagerSwiftTestHelpers.clearState()
            }

            body()
        }

        private func makeRegion(identifier: String) -> CLBeaconRegion {
            CLBeaconRegion(
                uuid: UUID(),
                major: 1,
                minor: 2,
                identifier: identifier
            )
        }

        private func makeLocation() -> CLLocation {
            CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: 40.7, longitude: -74),
                altitude: 0,
                horizontalAccuracy: 5,
                verticalAccuracy: 5,
                timestamp: Date()
            )
        }

        @Test("didDetermineState ignores non-beacon regions")
        func ignoresNonBeaconRegion() {
            withBeaconDependencies {
                let region = CLCircularRegion(
                    center: CLLocationCoordinate2D(latitude: 40.7, longitude: -74),
                    radius: 100,
                    identifier: "radar_geofence_test"
                )
                var called = false

                RadarLocationManagerSwift.didDetermineState(.inside, region: region) { _, _ in
                    called = true
                }

                #expect(!called)
            }
        }

        @Test("didDetermineState forwards the normal beacon entry payload")
        func forwardsNormalBeaconEntryPayload() {
            withBeaconDependencies {
                let region = makeRegion(identifier: "radar_beacon_test")
                var entryBeacons: [RadarBeacon]?

                RadarLocationManagerSwift.didDetermineState(.inside, region: region) { _, beacons in
                    entryBeacons = beacons
                }

                #expect(entryBeacons?.count == 1)
                #expect(beaconManager.nearbyBeaconIdentifiers.contains(region.identifier))
            }
        }

        @Test("didDetermineState forwards the normal beacon exit payload")
        func forwardsNormalBeaconExitPayload() {
            withBeaconDependencies {
                let region = makeRegion(identifier: "radar_beacon_test")
                var exitBeacons: [RadarBeacon]?
                beaconManager.nearbyBeaconIdentifiers.insert(region.identifier)

                RadarLocationManagerSwift.didDetermineState(.outside, region: region) { _, beacons in
                    exitBeacons = beacons
                }

                #expect(exitBeacons?.isEmpty == true)
                #expect(!beaconManager.nearbyBeaconIdentifiers.contains(region.identifier))
            }
        }

        @Test("didDetermineState handles UUID beacon entry and exit")
        func handlesUUIDBeaconStates() {
            withBeaconDependencies {
                let region = makeRegion(identifier: "radar_uuid_test")
                var entryStatus: RadarStatus?
                var exitStatus: RadarStatus?

                RadarLocationManagerSwift.didDetermineState(.inside, region: region) { status, beacons in
                    entryStatus = status
                    #expect(beacons?.isEmpty == true)
                }
                RadarLocationManagerSwift.didDetermineState(.outside, region: region) { status, beacons in
                    exitStatus = status
                    #expect(beacons?.isEmpty == true)
                }

                #expect(entryStatus == .success)
                #expect(exitStatus == .success)
            }
        }

        @Test("Public didDetermineState uses the Swift path when enabled")
        func publicMethodUsesSwiftPath() {
            withBeaconDependencies {
                RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
                    "useRadarModifiedBeacon": false,
                    "useSwiftLocationManager": true,
                ])
                let locationManager = TrackingCLLocationManager()
                locationManager.mockLocation = makeLocation()
                let region = makeRegion(identifier: "radar_beacon_swift")

                RadarLocationManager.sharedInstance().locationManager(
                    locationManager,
                    didDetermineState: .inside,
                    for: region
                )

                #expect(beaconManager.nearbyBeaconIdentifiers.contains(region.identifier))
            }
        }

        @Test("Public didDetermineState keeps the Objective-C fallback when disabled")
        func publicMethodUsesObjectiveCFallback() {
            withBeaconDependencies {
                RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
                    "useRadarModifiedBeacon": false,
                    "useSwiftLocationManager": false,
                ])
                let locationManager = TrackingCLLocationManager()
                locationManager.mockLocation = makeLocation()
                let region = makeRegion(identifier: "radar_beacon_objc")

                RadarLocationManager.sharedInstance().locationManager(
                    locationManager,
                    didDetermineState: .inside,
                    for: region
                )

                #expect(beaconManager.nearbyBeaconIdentifiers.contains(region.identifier))
            }
        }

        @Test("Public Swift path ignores beacon state without an effective location")
        func publicSwiftPathRequiresLocation() {
            withBeaconDependencies {
                RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
                    "useRadarModifiedBeacon": false,
                    "useSwiftLocationManager": true,
                ])
                let locationManager = TrackingCLLocationManager()
                let region = makeRegion(identifier: "radar_beacon_no_location")
                RadarSwift.bridge = MockRadarSwiftBridge()

                RadarLocationManager.sharedInstance().locationManager(
                    locationManager,
                    didDetermineState: .inside,
                    for: region
                )

                #expect(!beaconManager.nearbyBeaconIdentifiers.contains(region.identifier))
            }
        }
    }
}
