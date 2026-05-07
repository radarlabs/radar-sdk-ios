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
        #expect(implementation.locationMonitoringKind == .locationManager)
        #expect(implementation.locationMonitoring is RadarLocationManagerMonitoring)
        #expect(implementation.locationAuthorizationKind == .locationManager)
        #expect(implementation.locationAuthorizationController is RadarLocationManagerAuthorizationController)
        #expect(implementation.locationBackgroundSessionKind == .none)
        #expect(implementation.locationBackgroundSessionController is RadarNoopLocationBackgroundSessionController)
        #expect(implementation.locationDiagnosticsKind == .legacy)
        #expect(implementation.locationDiagnosticsProvider is RadarLegacyLocationDiagnosticsProvider)
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

    @Test("Location manager implementation can select future location platform collaborators")
    func implementationCanSelectFutureLocationPlatformCollaborators() {
        let implementation = RadarLocationManagerImplementation()
        let locationManager = CLLocationManager()
        let lowPowerLocationManager = CLLocationManager()

        implementation.configure(
            locationManager: locationManager,
            lowPowerLocationManager: lowPowerLocationManager
        )
        implementation.setLocationMonitoringKind(.conditionMonitoring)
        implementation.setLocationAuthorizationKind(.serviceSession)
        implementation.setLocationBackgroundSessionKind(.backgroundActivitySession)
        implementation.setLocationDiagnosticsKind(.serviceSession)

        if #available(iOS 17.0, *) {
            #expect(implementation.locationMonitoring is RadarConditionMonitoring)
            #expect(implementation.locationAuthorizationController is RadarServiceSessionAuthorizationController)
            #expect(implementation.locationBackgroundSessionController is RadarBackgroundActivitySessionController)
            #expect(implementation.locationDiagnosticsProvider is RadarServiceSessionDiagnosticsProvider)
        } else {
            #expect(implementation.locationMonitoring is RadarLocationManagerMonitoring)
            #expect(implementation.locationAuthorizationController is RadarLocationManagerAuthorizationController)
            #expect(implementation.locationBackgroundSessionController is RadarNoopLocationBackgroundSessionController)
            #expect(implementation.locationDiagnosticsProvider is RadarLegacyLocationDiagnosticsProvider)
        }
    }

    @Test("Location manager legacy diagnostics snapshot reflects current authorization state")
    func legacyDiagnosticsSnapshotDefaults() {
        let implementation = RadarLocationManagerImplementation()
        let locationManager = CLLocationManager()
        let lowPowerLocationManager = CLLocationManager()

        implementation.configure(
            locationManager: locationManager,
            lowPowerLocationManager: lowPowerLocationManager
        )

        let snapshot = implementation.locationDiagnosticsProvider?.diagnosticsSnapshot()

        #expect(snapshot != nil)
        #expect(snapshot?.insufficientlyInUse == false)
        #expect(snapshot?.serviceSessionRequired == false)
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
