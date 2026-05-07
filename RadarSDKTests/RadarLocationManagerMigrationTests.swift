//
//  RadarLocationManagerMigrationTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Testing
import CoreLocation
@testable import RadarSDK

@Suite(.serialized)
actor RadarLocationManagerMigrationTests {
    @Test("Location manager Swift migration flag defaults off")
    func migrationFlagDefaultsOff() {
        RadarUserDefaults.set(nil, forKey: .LocationManagerSwiftMigrationEnabled)

        #expect(RadarSettings.locationManagerSwiftMigrationEnabled == false)
    }

    @Test("Location manager Swift migration flag round trips")
    func migrationFlagRoundTrips() {
        RadarSettings.locationManagerSwiftMigrationEnabled = true
        #expect(RadarSettings.locationManagerSwiftMigrationEnabled == true)

        RadarSettings.locationManagerSwiftMigrationEnabled = false
        #expect(RadarSettings.locationManagerSwiftMigrationEnabled == false)
    }

    @Test("Location manager implementation defaults to a CLLocationManager source")
    func implementationDefaultsToCoreLocationManagerSource() {
        let implementation = RadarLocationManagerImplementation()
        let locationManager = CLLocationManager()
        let lowPowerLocationManager = CLLocationManager()

        implementation.configure(
            locationManager: locationManager,
            lowPowerLocationManager: lowPowerLocationManager
        )

        #expect(implementation.locationUpdateSourceKind == .coreLocationManager)
        #expect(implementation.locationUpdateSource is RadarCoreLocationUpdateSource)
    }

    @Test("Location manager implementation can select a live updates source")
    func implementationCanSelectLiveUpdatesSource() {
        let implementation = RadarLocationManagerImplementation()
        let locationManager = CLLocationManager()
        let lowPowerLocationManager = CLLocationManager()

        implementation.configure(
            locationManager: locationManager,
            lowPowerLocationManager: lowPowerLocationManager
        )
        implementation.setLocationUpdateSourceKind(.liveUpdates)

        if #available(iOS 17.0, *) {
            #expect(implementation.locationUpdateSource is RadarLiveLocationUpdateSource)
        } else {
            #expect(implementation.locationUpdateSource is RadarCoreLocationUpdateSource)
        }
    }

    @Test("Location manager facade owns both injected CLLocationManager delegates")
    func facadeOwnsInjectedLocationManagerDelegates() {
        let locationManager = RadarLocationManager()
        let standardManager = CLLocationManager()
        let lowPowerManager = CLLocationManager()

        locationManager.locationManager = standardManager
        locationManager.lowPowerLocationManager = lowPowerManager

        #expect(standardManager.delegate === locationManager)
        #expect(lowPowerManager.delegate === locationManager)
    }
}
