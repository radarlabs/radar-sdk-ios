//
//  RadarLocationManagerSelectionTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Testing

@testable import RadarSDK

@Suite(.serialized)
actor RadarLocationManagerSelectionTests {

    private func clearSelectionAndConfiguration() {
        let manager = RadarLocationManager.sharedInstance()
        manager.clearImplementationSelectionForTesting()
        RadarSettings.sdkConfiguration = nil
    }

    @Test("default flag selects ObjC implementation")
    func defaultFlagSelectsObjCImplementation() {
        clearSelectionAndConfiguration()
        defer {
            clearSelectionAndConfiguration()
        }

        let manager = RadarLocationManager.sharedInstance()
        _ = manager.locationManager

        #expect(
            manager.selectedImplementationClassNameForTesting()
                == "RadarLocationManagerObjCImplementation"
        )
    }

    @Test("useSwiftLocationManager selects Swift shell implementation")
    func useSwiftFlagSelectsSwiftImplementation() {
        clearSelectionAndConfiguration()
        defer {
            clearSelectionAndConfiguration()
        }

        RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
            "useSwiftLocationManager": true
        ])

        let manager = RadarLocationManager.sharedInstance()
        _ = manager.locationManager

        #expect(
            manager.selectedImplementationClassNameForTesting()
                == "RadarLocationManagerSwiftImplementation"
        )
    }

    @Test("implementation selection is sticky after first access")
    func implementationSelectionIsSticky() {
        clearSelectionAndConfiguration()
        defer {
            clearSelectionAndConfiguration()
        }

        let manager = RadarLocationManager.sharedInstance()
        _ = manager.locationManager

        #expect(
            manager.selectedImplementationClassNameForTesting()
                == "RadarLocationManagerObjCImplementation"
        )

        RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
            "useSwiftLocationManager": true
        ])

        _ = manager.lowPowerLocationManager

        #expect(
            manager.selectedImplementationClassNameForTesting()
                == "RadarLocationManagerObjCImplementation"
        )
    }

    @Test("forwarded dependency properties round-trip through Swift shell")
    func forwardedDependencyPropertiesRoundTripThroughSwiftShell() {
        clearSelectionAndConfiguration()
        defer {
            clearSelectionAndConfiguration()
        }

        RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
            "useSwiftLocationManager": true
        ])

        let manager = RadarLocationManager.sharedInstance()
        let locationManager = CLLocationManager()
        let lowPowerLocationManager = CLLocationManager()
        let permissionsHelper = RadarPermissionsHelper()
        let activityManager = RadarActivityManager.sharedInstance()

        manager.locationManager = locationManager
        manager.lowPowerLocationManager = lowPowerLocationManager
        manager.permissionsHelper = permissionsHelper
        manager.activityManager = activityManager

        #expect(
            manager.selectedImplementationClassNameForTesting()
                == "RadarLocationManagerSwiftImplementation"
        )
        #expect(manager.locationManager === locationManager)
        #expect(manager.lowPowerLocationManager === lowPowerLocationManager)
        #expect(manager.permissionsHelper === permissionsHelper)
        #expect(manager.activityManager === activityManager)
        #expect(manager.locationManager.delegate === manager)
    }
}
