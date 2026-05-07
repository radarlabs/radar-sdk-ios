//
//  RadarLocationManager.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

// This boundary keeps "how locations arrive" separate from the state machine that
// decides what to do with them, so we can adopt new Core Location delivery APIs
// without reshaping the facade again.
enum RadarLocationUpdateSourceKind {
    case coreLocationManager
    case liveUpdates
}

protocol RadarLocationUpdateSource: AnyObject {
    func requestSingleUpdate()
    func setStandardUpdatesEnabled(_ isEnabled: Bool)
    func setLowPowerUpdatesEnabled(_ isEnabled: Bool)
}

protocol RadarLocationUpdateSourceMaking {
    func makeSource(
        kind: RadarLocationUpdateSourceKind,
        locationManager: CLLocationManager,
        lowPowerLocationManager: CLLocationManager
    ) -> RadarLocationUpdateSource
}

final class RadarCoreLocationUpdateSource: RadarLocationUpdateSource {
    private let locationManager: CLLocationManager
    private let lowPowerLocationManager: CLLocationManager

    init(locationManager: CLLocationManager, lowPowerLocationManager: CLLocationManager) {
        self.locationManager = locationManager
        self.lowPowerLocationManager = lowPowerLocationManager
    }

    func requestSingleUpdate() {
        locationManager.requestLocation()
    }

    func setStandardUpdatesEnabled(_ isEnabled: Bool) {
        if isEnabled {
            locationManager.startUpdatingLocation()
        } else {
            locationManager.stopUpdatingLocation()
        }
    }

    func setLowPowerUpdatesEnabled(_ isEnabled: Bool) {
        if isEnabled {
            lowPowerLocationManager.startUpdatingLocation()
        } else {
            lowPowerLocationManager.stopUpdatingLocation()
        }
    }
}

@available(iOS 17.0, *)
final class RadarLiveLocationUpdateSource: RadarLocationUpdateSource {
    func requestSingleUpdate() {
        preconditionFailure("Radar liveUpdates source is not implemented for requestSingleUpdate()")
    }

    func setStandardUpdatesEnabled(_ isEnabled: Bool) {
        preconditionFailure("Radar liveUpdates source is not implemented for setStandardUpdatesEnabled(_:)")
    }

    func setLowPowerUpdatesEnabled(_ isEnabled: Bool) {
        preconditionFailure("Radar liveUpdates source is not implemented for setLowPowerUpdatesEnabled(_:)")
    }
}

final class RadarLocationUpdateSourceFactory: RadarLocationUpdateSourceMaking {
    func makeSource(
        kind: RadarLocationUpdateSourceKind,
        locationManager: CLLocationManager,
        lowPowerLocationManager: CLLocationManager
    ) -> RadarLocationUpdateSource {
        switch kind {
        case .coreLocationManager:
            return RadarCoreLocationUpdateSource(
                locationManager: locationManager,
                lowPowerLocationManager: lowPowerLocationManager
            )
        case .liveUpdates:
            if #available(iOS 17.0, *) {
                return RadarLiveLocationUpdateSource()
            }

            return RadarCoreLocationUpdateSource(
                locationManager: locationManager,
                lowPowerLocationManager: lowPowerLocationManager
            )
        }
    }
}

@objc(RadarLocationManagerImplementation)
public final class RadarLocationManagerImplementation: NSObject {
    private let sourceFactory: RadarLocationUpdateSourceMaking
    private weak var locationManager: CLLocationManager?
    private weak var lowPowerLocationManager: CLLocationManager?
    private(set) var locationUpdateSourceKind: RadarLocationUpdateSourceKind = .coreLocationManager
    private(set) var locationUpdateSource: RadarLocationUpdateSource?

    @objc
    public override init() {
        self.sourceFactory = RadarLocationUpdateSourceFactory()
        super.init()
    }

    init(sourceFactory: RadarLocationUpdateSourceMaking) {
        self.sourceFactory = sourceFactory
        super.init()
    }

    @objc(configureWithLocationManager:lowPowerLocationManager:)
    public func configure(locationManager: CLLocationManager, lowPowerLocationManager: CLLocationManager) {
        self.locationManager = locationManager
        self.lowPowerLocationManager = lowPowerLocationManager
        rebuildLocationUpdateSource()
    }

    func setLocationUpdateSourceKind(_ kind: RadarLocationUpdateSourceKind) {
        locationUpdateSourceKind = kind
        rebuildLocationUpdateSource()
    }

    @objc
    public func didUpdateInjectedDependencies() {
        rebuildLocationUpdateSource()
    }

    @objc(failFastWithMethod:)
    public func failFast(withMethod method: String) {
        preconditionFailure("RadarLocationManager implementation is not implemented for \(method)")
    }

    private func rebuildLocationUpdateSource() {
        guard let locationManager, let lowPowerLocationManager else {
            locationUpdateSource = nil
            return
        }

        locationUpdateSource = sourceFactory.makeSource(
            kind: locationUpdateSourceKind,
            locationManager: locationManager,
            lowPowerLocationManager: lowPowerLocationManager
        )
    }
}
