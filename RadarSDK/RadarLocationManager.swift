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

enum RadarLocationMonitoringKind {
    case locationManager
    case conditionMonitoring
}

enum RadarLocationAuthorizationKind {
    case locationManager
    case serviceSession
}

enum RadarLocationBackgroundSessionKind {
    case none
    case backgroundActivitySession
}

enum RadarLocationDiagnosticsKind {
    case legacy
    case serviceSession
}

struct RadarLocationDiagnosticsSnapshot: Equatable {
    let authorizationDenied: Bool
    let authorizationDeniedGlobally: Bool
    let authorizationRestricted: Bool
    let accuracyLimited: Bool
    let insufficientlyInUse: Bool
    let serviceSessionRequired: Bool
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

protocol RadarLocationMonitoring: AnyObject {
    func startMonitoring(_ region: CLRegion)
    func stopMonitoring(_ region: CLRegion)
}

protocol RadarLocationMonitoringMaking {
    func makeMonitoring(kind: RadarLocationMonitoringKind, locationManager: CLLocationManager) -> RadarLocationMonitoring
}

protocol RadarLocationAuthorizationControlling: AnyObject {
    var authorizationStatus: CLAuthorizationStatus { get }
    var accuracyAuthorization: CLAccuracyAuthorization? { get }
    func requestWhenInUseAuthorization()
    func requestAlwaysAuthorization()
    func requestTemporaryFullAccuracyAuthorization(purposeKey: String)
}

protocol RadarLocationAuthorizationControllingMaking {
    func makeAuthorizationController(
        kind: RadarLocationAuthorizationKind,
        locationManager: CLLocationManager
    ) -> RadarLocationAuthorizationControlling
}

protocol RadarLocationBackgroundSessionControlling: AnyObject {
    var isActive: Bool { get }
    func activate()
    func invalidate()
}

protocol RadarLocationBackgroundSessionControllingMaking {
    func makeBackgroundSessionController(
        kind: RadarLocationBackgroundSessionKind
    ) -> RadarLocationBackgroundSessionControlling
}

protocol RadarLocationDiagnosticsProviding: AnyObject {
    func diagnosticsSnapshot() -> RadarLocationDiagnosticsSnapshot
}

protocol RadarLocationDiagnosticsProvidingMaking {
    func makeDiagnosticsProvider(
        kind: RadarLocationDiagnosticsKind,
        locationManager: CLLocationManager
    ) -> RadarLocationDiagnosticsProviding
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

final class RadarLocationManagerMonitoring: RadarLocationMonitoring {
    private let locationManager: CLLocationManager

    init(locationManager: CLLocationManager) {
        self.locationManager = locationManager
    }

    func startMonitoring(_ region: CLRegion) {
        locationManager.startMonitoring(for: region)
    }

    func stopMonitoring(_ region: CLRegion) {
        locationManager.stopMonitoring(for: region)
    }
}

final class RadarLocationManagerAuthorizationController: RadarLocationAuthorizationControlling {
    private let locationManager: CLLocationManager

    init(locationManager: CLLocationManager) {
        self.locationManager = locationManager
    }

    var authorizationStatus: CLAuthorizationStatus {
        CLLocationManager.authorizationStatus()
    }

    var accuracyAuthorization: CLAccuracyAuthorization? {
        if #available(iOS 14.0, *) {
            return locationManager.accuracyAuthorization
        }

        return nil
    }

    func requestWhenInUseAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    func requestAlwaysAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }

    func requestTemporaryFullAccuracyAuthorization(purposeKey: String) {
        guard #available(iOS 14.0, *) else {
            return
        }

        locationManager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: purposeKey)
    }
}

final class RadarNoopLocationBackgroundSessionController: RadarLocationBackgroundSessionControlling {
    private(set) var isActive = false

    func activate() {
        isActive = true
    }

    func invalidate() {
        isActive = false
    }
}

final class RadarLegacyLocationDiagnosticsProvider: RadarLocationDiagnosticsProviding {
    private let locationManager: CLLocationManager

    init(locationManager: CLLocationManager) {
        self.locationManager = locationManager
    }

    func diagnosticsSnapshot() -> RadarLocationDiagnosticsSnapshot {
        let authorizationStatus = CLLocationManager.authorizationStatus()
        let accuracyLimited: Bool

        if #available(iOS 14.0, *) {
            accuracyLimited = locationManager.accuracyAuthorization == .reducedAccuracy
        } else {
            accuracyLimited = false
        }

        return RadarLocationDiagnosticsSnapshot(
            authorizationDenied: authorizationStatus == .denied,
            authorizationDeniedGlobally: !CLLocationManager.locationServicesEnabled(),
            authorizationRestricted: authorizationStatus == .restricted,
            accuracyLimited: accuracyLimited,
            insufficientlyInUse: false,
            serviceSessionRequired: false
        )
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

@available(iOS 17.0, *)
final class RadarConditionMonitoring: RadarLocationMonitoring {
    func startMonitoring(_ region: CLRegion) {
        preconditionFailure("Radar condition monitoring is not implemented for startMonitoring(_:)")
    }

    func stopMonitoring(_ region: CLRegion) {
        preconditionFailure("Radar condition monitoring is not implemented for stopMonitoring(_:)")
    }
}

@available(iOS 17.0, *)
final class RadarServiceSessionAuthorizationController: RadarLocationAuthorizationControlling {
    var authorizationStatus: CLAuthorizationStatus {
        preconditionFailure("Radar service session authorization is not implemented for authorizationStatus")
    }

    var accuracyAuthorization: CLAccuracyAuthorization? {
        preconditionFailure("Radar service session authorization is not implemented for accuracyAuthorization")
    }

    func requestWhenInUseAuthorization() {
        preconditionFailure("Radar service session authorization is not implemented for requestWhenInUseAuthorization()")
    }

    func requestAlwaysAuthorization() {
        preconditionFailure("Radar service session authorization is not implemented for requestAlwaysAuthorization()")
    }

    func requestTemporaryFullAccuracyAuthorization(purposeKey: String) {
        preconditionFailure("Radar service session authorization is not implemented for requestTemporaryFullAccuracyAuthorization(purposeKey:)")
    }
}

@available(iOS 17.0, *)
final class RadarBackgroundActivitySessionController: RadarLocationBackgroundSessionControlling {
    var isActive: Bool {
        preconditionFailure("Radar background activity session is not implemented for isActive")
    }

    func activate() {
        preconditionFailure("Radar background activity session is not implemented for activate()")
    }

    func invalidate() {
        preconditionFailure("Radar background activity session is not implemented for invalidate()")
    }
}

@available(iOS 17.0, *)
final class RadarServiceSessionDiagnosticsProvider: RadarLocationDiagnosticsProviding {
    func diagnosticsSnapshot() -> RadarLocationDiagnosticsSnapshot {
        preconditionFailure("Radar service session diagnostics are not implemented for diagnosticsSnapshot()")
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

final class RadarLocationMonitoringFactory: RadarLocationMonitoringMaking {
    func makeMonitoring(kind: RadarLocationMonitoringKind, locationManager: CLLocationManager) -> RadarLocationMonitoring {
        switch kind {
        case .locationManager:
            return RadarLocationManagerMonitoring(locationManager: locationManager)
        case .conditionMonitoring:
            if #available(iOS 17.0, *) {
                return RadarConditionMonitoring()
            }

            return RadarLocationManagerMonitoring(locationManager: locationManager)
        }
    }
}

final class RadarLocationAuthorizationControllerFactory: RadarLocationAuthorizationControllingMaking {
    func makeAuthorizationController(
        kind: RadarLocationAuthorizationKind,
        locationManager: CLLocationManager
    ) -> RadarLocationAuthorizationControlling {
        switch kind {
        case .locationManager:
            return RadarLocationManagerAuthorizationController(locationManager: locationManager)
        case .serviceSession:
            if #available(iOS 17.0, *) {
                return RadarServiceSessionAuthorizationController()
            }

            return RadarLocationManagerAuthorizationController(locationManager: locationManager)
        }
    }
}

final class RadarLocationBackgroundSessionControllerFactory: RadarLocationBackgroundSessionControllingMaking {
    func makeBackgroundSessionController(
        kind: RadarLocationBackgroundSessionKind
    ) -> RadarLocationBackgroundSessionControlling {
        switch kind {
        case .none:
            return RadarNoopLocationBackgroundSessionController()
        case .backgroundActivitySession:
            if #available(iOS 17.0, *) {
                return RadarBackgroundActivitySessionController()
            }

            return RadarNoopLocationBackgroundSessionController()
        }
    }
}

final class RadarLocationDiagnosticsProviderFactory: RadarLocationDiagnosticsProvidingMaking {
    func makeDiagnosticsProvider(
        kind: RadarLocationDiagnosticsKind,
        locationManager: CLLocationManager
    ) -> RadarLocationDiagnosticsProviding {
        switch kind {
        case .legacy:
            return RadarLegacyLocationDiagnosticsProvider(locationManager: locationManager)
        case .serviceSession:
            if #available(iOS 17.0, *) {
                return RadarServiceSessionDiagnosticsProvider()
            }

            return RadarLegacyLocationDiagnosticsProvider(locationManager: locationManager)
        }
    }
}

@objc(RadarLocationManagerImplementation)
public final class RadarLocationManagerImplementation: NSObject {
    private let sourceFactory: RadarLocationUpdateSourceMaking
    private let monitoringFactory: RadarLocationMonitoringMaking
    private let authorizationControllerFactory: RadarLocationAuthorizationControllingMaking
    private let backgroundSessionControllerFactory: RadarLocationBackgroundSessionControllingMaking
    private let diagnosticsProviderFactory: RadarLocationDiagnosticsProvidingMaking
    private weak var locationManager: CLLocationManager?
    private weak var lowPowerLocationManager: CLLocationManager?
    private(set) var locationUpdateSourceKind: RadarLocationUpdateSourceKind = .coreLocationManager
    private(set) var locationMonitoringKind: RadarLocationMonitoringKind = .locationManager
    private(set) var locationAuthorizationKind: RadarLocationAuthorizationKind = .locationManager
    private(set) var locationBackgroundSessionKind: RadarLocationBackgroundSessionKind = .none
    private(set) var locationDiagnosticsKind: RadarLocationDiagnosticsKind = .legacy
    private(set) var locationUpdateSource: RadarLocationUpdateSource?
    private(set) var locationMonitoring: RadarLocationMonitoring?
    private(set) var locationAuthorizationController: RadarLocationAuthorizationControlling?
    private(set) var locationBackgroundSessionController: RadarLocationBackgroundSessionControlling?
    private(set) var locationDiagnosticsProvider: RadarLocationDiagnosticsProviding?

    @objc
    public override init() {
        self.sourceFactory = RadarLocationUpdateSourceFactory()
        self.monitoringFactory = RadarLocationMonitoringFactory()
        self.authorizationControllerFactory = RadarLocationAuthorizationControllerFactory()
        self.backgroundSessionControllerFactory = RadarLocationBackgroundSessionControllerFactory()
        self.diagnosticsProviderFactory = RadarLocationDiagnosticsProviderFactory()
        super.init()
    }

    init(
        sourceFactory: RadarLocationUpdateSourceMaking,
        monitoringFactory: RadarLocationMonitoringMaking,
        authorizationControllerFactory: RadarLocationAuthorizationControllingMaking,
        backgroundSessionControllerFactory: RadarLocationBackgroundSessionControllingMaking,
        diagnosticsProviderFactory: RadarLocationDiagnosticsProvidingMaking
    ) {
        self.sourceFactory = sourceFactory
        self.monitoringFactory = monitoringFactory
        self.authorizationControllerFactory = authorizationControllerFactory
        self.backgroundSessionControllerFactory = backgroundSessionControllerFactory
        self.diagnosticsProviderFactory = diagnosticsProviderFactory
        super.init()
    }

    @objc(configureWithLocationManager:lowPowerLocationManager:)
    public func configure(locationManager: CLLocationManager, lowPowerLocationManager: CLLocationManager) {
        self.locationManager = locationManager
        self.lowPowerLocationManager = lowPowerLocationManager
        rebuildLocationPlatform()
    }

    func setLocationUpdateSourceKind(_ kind: RadarLocationUpdateSourceKind) {
        locationUpdateSourceKind = kind
        rebuildLocationPlatform()
    }

    func setLocationMonitoringKind(_ kind: RadarLocationMonitoringKind) {
        locationMonitoringKind = kind
        rebuildLocationPlatform()
    }

    func setLocationAuthorizationKind(_ kind: RadarLocationAuthorizationKind) {
        locationAuthorizationKind = kind
        rebuildLocationPlatform()
    }

    func setLocationBackgroundSessionKind(_ kind: RadarLocationBackgroundSessionKind) {
        locationBackgroundSessionKind = kind
        rebuildLocationPlatform()
    }

    func setLocationDiagnosticsKind(_ kind: RadarLocationDiagnosticsKind) {
        locationDiagnosticsKind = kind
        rebuildLocationPlatform()
    }

    @objc
    public func didUpdateInjectedDependencies() {
        rebuildLocationPlatform()
    }

    @objc(failFastWithMethod:)
    public func failFast(withMethod method: String) {
        preconditionFailure("RadarLocationManager implementation is not implemented for \(method)")
    }

    private func rebuildLocationPlatform() {
        guard let locationManager, let lowPowerLocationManager else {
            locationUpdateSource = nil
            locationMonitoring = nil
            locationAuthorizationController = nil
            locationBackgroundSessionController = nil
            locationDiagnosticsProvider = nil
            return
        }

        locationUpdateSource = sourceFactory.makeSource(
            kind: locationUpdateSourceKind,
            locationManager: locationManager,
            lowPowerLocationManager: lowPowerLocationManager
        )
        locationMonitoring = monitoringFactory.makeMonitoring(
            kind: locationMonitoringKind,
            locationManager: locationManager
        )
        locationAuthorizationController = authorizationControllerFactory.makeAuthorizationController(
            kind: locationAuthorizationKind,
            locationManager: locationManager
        )
        locationBackgroundSessionController = backgroundSessionControllerFactory.makeBackgroundSessionController(
            kind: locationBackgroundSessionKind
        )
        locationDiagnosticsProvider = diagnosticsProviderFactory.makeDiagnosticsProvider(
            kind: locationDiagnosticsKind,
            locationManager: locationManager
        )
    }
}
