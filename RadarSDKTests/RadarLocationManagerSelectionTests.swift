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

    private func clearImplementationSelection() {
        RadarLocationManager.sharedInstance().clearImplementationSelectionForTesting()
    }

    @Test("default flag selects ObjC implementation")
    func defaultFlagSelectsObjCImplementation() {
        clearImplementationSelection()
        defer { clearImplementationSelection() }

        let manager = RadarLocationManager.sharedInstance()
        manager.forceImplementationSelection(forTestingUseSwift: false)

        #expect(
            manager.selectedImplementationClassNameForTesting()
                == "RadarLocationManagerObjCImplementation"
        )
    }

    @Test("useSwiftLocationManager selects Swift shell implementation")
    func useSwiftFlagSelectsSwiftImplementation() {
        clearImplementationSelection()
        defer { clearImplementationSelection() }

        let manager = RadarLocationManager.sharedInstance()
        manager.forceImplementationSelection(forTestingUseSwift: true)

        #expect(
            manager.selectedImplementationClassNameForTesting()
                == "RadarLocationManagerSwiftImplementation"
        )
    }

    @Test("implementation selection is sticky after first access")
    func implementationSelectionIsSticky() {
        clearImplementationSelection()
        defer { clearImplementationSelection() }

        let manager = RadarLocationManager.sharedInstance()
        manager.forceImplementationSelection(forTestingUseSwift: false)

        #expect(
            manager.selectedImplementationClassNameForTesting()
                == "RadarLocationManagerObjCImplementation"
        )

        // Property accesses on the facade must not disturb the cached selection.
        _ = manager.lowPowerLocationManager
        _ = manager.permissionsHelper

        #expect(
            manager.selectedImplementationClassNameForTesting()
                == "RadarLocationManagerObjCImplementation"
        )
    }

    @Test("forwarded dependency properties round-trip through Swift shell")
    func forwardedDependencyPropertiesRoundTripThroughSwiftShell() {
        clearImplementationSelection()
        defer { clearImplementationSelection() }

        let manager = RadarLocationManager.sharedInstance()
        manager.forceImplementationSelection(forTestingUseSwift: true)

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
