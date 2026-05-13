//
//  RadarLocationManagerSwiftImplementation.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

// The concrete ObjC implementation type and internal protocol are not accessible from
// Swift in a framework target (project headers aren't part of the public module). The
// stored property is therefore NSObject, and all method dispatch goes through the ObjC
// runtime via C function pointer casts. The @convention(c) signatures must match the
// ObjC method's argument layout exactly; guard-before-cast ensures a clear assertion
// failure rather than a null-pointer crash if a selector is ever missing.
@objc(RadarLocationManagerSwiftImplementation) @objcMembers
final class RadarLocationManagerSwiftImplementation: NSObject {

    private let implementation: NSObject

    init(implementation: NSObject) {
        self.implementation = implementation
        super.init()
    }

    var locationManager: CLLocationManager {
        get { object(forKey: "locationManager") }
        set { implementation.setValue(newValue, forKey: "locationManager") }
    }

    var lowPowerLocationManager: CLLocationManager {
        get { object(forKey: "lowPowerLocationManager") }
        set { implementation.setValue(newValue, forKey: "lowPowerLocationManager") }
    }

    var permissionsHelper: NSObject {
        get { object(forKey: "permissionsHelper") }
        set { implementation.setValue(newValue, forKey: "permissionsHelper") }
    }

    var activityManager: NSObject? {
        get { implementation.value(forKey: "activityManager") as? NSObject }
        set { implementation.setValue(newValue, forKey: "activityManager") }
    }

    @objc(getLocationWithCompletionHandler:)
    func getLocation(withCompletionHandler completionHandler: RadarLocationCompletionHandler?) {
        invokeVoid(
            selector: #selector(getLocation(withCompletionHandler:)),
            with: completionHandler.map { $0 as AnyObject }
        )
    }

    @objc(getLocationWithDesiredAccuracy:completionHandler:)
    func getLocation(
        withDesiredAccuracy desiredAccuracy: RadarTrackingOptionsDesiredAccuracy,
        completionHandler: RadarLocationCompletionHandler?
    ) {
        invokeVoid(
            selector: #selector(getLocation(withDesiredAccuracy:completionHandler:)),
            integer: Int(desiredAccuracy.rawValue),
            object: completionHandler.map { $0 as AnyObject }
        )
    }

    @objc(startTrackingWithOptions:)
    func startTracking(withOptions trackingOptions: RadarTrackingOptions) {
        invokeVoid(selector: #selector(startTracking(withOptions:)), with: trackingOptions)
    }

    @objc(stopTracking)
    func stopTracking() {
        invokeVoid(selector: #selector(stopTracking))
    }

    @objc(replaceSyncedGeofences:)
    func replaceSyncedGeofences(_ geofences: [RadarGeofence]) {
        invokeVoid(selector: #selector(replaceSyncedGeofences(_:)), with: geofences as NSArray)
    }

    @objc(replaceSyncedBeacons:)
    func replaceSyncedBeacons(_ beacons: [RadarBeacon]) {
        invokeVoid(selector: #selector(replaceSyncedBeacons(_:)), with: beacons as NSArray)
    }

    @objc(replaceSyncedBeaconUUIDs:)
    func replaceSyncedBeaconUUIDs(_ uuids: [String]) {
        invokeVoid(selector: #selector(replaceSyncedBeaconUUIDs(_:)), with: uuids as NSArray)
    }

    @objc(updateTracking)
    func updateTracking() {
        invokeVoid(selector: #selector(updateTracking))
    }

    @objc(updateTrackingFromMeta:)
    func updateTrackingFromMeta(_ meta: NSObject?) {
        invokeVoid(selector: #selector(updateTrackingFromMeta(_:)), with: meta)
    }

    @objc(updateTrackingFromInitialize)
    func updateTrackingFromInitialize() {
        invokeVoid(selector: #selector(updateTrackingFromInitialize))
    }

    @objc(performIndoorScanIfConfigured:beacons:completionHandler:)
    func performIndoorScanIfConfigured(
        _ location: CLLocation,
        beacons: NSArray?,
        completionHandler: @escaping (NSArray?, NSString?) -> Void
    ) {
        invokeVoid(
            selector: #selector(performIndoorScanIfConfigured(_:beacons:completionHandler:)),
            object: location,
            secondObject: beacons,
            thirdObject: completionHandler as AnyObject
        )
    }

    @objc(restartPreviousTrackingOptions)
    func restartPreviousTrackingOptions() {
        invokeVoid(selector: #selector(restartPreviousTrackingOptions))
    }

    @objc(callCompletionHandlersWithStatus:location:)
    func callCompletionHandlers(withStatus status: RadarStatus, location: CLLocation?) {
        invokeVoid(
            selector: #selector(callCompletionHandlers(withStatus:location:)),
            integer: Int(status.rawValue),
            object: location
        )
    }

    // Delegate-forwarding methods are named handleLocationManager to match the
    // NS_SWIFT_NAME annotations in RadarLocationManagerImplementation.h and to avoid
    // confusion with CLLocationManagerDelegate. The @objc attribute preserves the ObjC
    // selector that RadarLocationManager (the facade) forwards.

    @objc(locationManager:didUpdateLocations:)
    func handleLocationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        invokeVoid(
            selector: #selector(handleLocationManager(_:didUpdateLocations:)),
            object: manager,
            secondObject: locations as NSArray
        )
    }

    @objc(locationManager:didEnterRegion:)
    func handleLocationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        invokeVoid(
            selector: #selector(handleLocationManager(_:didEnterRegion:)),
            object: manager,
            secondObject: region
        )
    }

    @objc(locationManager:didExitRegion:)
    func handleLocationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        invokeVoid(
            selector: #selector(handleLocationManager(_:didExitRegion:)),
            object: manager,
            secondObject: region
        )
    }

    @objc(locationManager:didDetermineState:forRegion:)
    func handleLocationManager(
        _ manager: CLLocationManager,
        didDetermineState state: CLRegionState,
        forRegion region: CLRegion
    ) {
        invokeVoid(
            selector: #selector(handleLocationManager(_:didDetermineState:forRegion:)),
            object: manager,
            integer: Int(state.rawValue),
            secondObject: region
        )
    }

    @objc(locationManager:didVisit:)
    func handleLocationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        invokeVoid(
            selector: #selector(handleLocationManager(_:didVisit:)),
            object: manager,
            secondObject: visit
        )
    }

    @objc(locationManager:didFailWithError:)
    func handleLocationManager(_ manager: CLLocationManager, didFailWithError error: NSError) {
        invokeVoid(
            selector: #selector(handleLocationManager(_:didFailWithError:)),
            object: manager,
            secondObject: error
        )
    }

    @objc(locationManager:didUpdateHeading:)
    func handleLocationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        invokeVoid(
            selector: #selector(handleLocationManager(_:didUpdateHeading:)),
            object: manager,
            secondObject: newHeading
        )
    }

    @objc(locationManager:didChangeAuthorizationStatus:)
    func handleLocationManager(
        _ manager: CLLocationManager,
        didChangeAuthorizationStatus status: CLAuthorizationStatus
    ) {
        invokeVoid(
            selector: #selector(handleLocationManager(_:didChangeAuthorizationStatus:)),
            object: manager,
            integer: Int(status.rawValue)
        )
    }

    private func object<T>(forKey key: String) -> T {
        guard let object = implementation.value(forKey: key) as? T else {
            fatalError("Expected value for \(key)")
        }
        return object
    }

    private func invokeVoid(selector: Selector) {
        typealias Function = @convention(c) (AnyObject, Selector) -> Void
        guard let imp = implementation.method(for: selector) else {
            assertionFailure("\(implementation) doesn't implement \(selector)")
            return
        }
        let function = unsafeBitCast(imp, to: Function.self)
        function(implementation, selector)
    }

    private func invokeVoid(selector: Selector, with object: AnyObject?) {
        typealias Function = @convention(c) (AnyObject, Selector, AnyObject?) -> Void
        guard let imp = implementation.method(for: selector) else {
            assertionFailure("\(implementation) doesn't implement \(selector)")
            return
        }
        let function = unsafeBitCast(imp, to: Function.self)
        function(implementation, selector, object)
    }

    private func invokeVoid(selector: Selector, object: AnyObject, secondObject: AnyObject?) {
        typealias Function = @convention(c) (AnyObject, Selector, AnyObject, AnyObject?) -> Void
        guard let imp = implementation.method(for: selector) else {
            assertionFailure("\(implementation) doesn't implement \(selector)")
            return
        }
        let function = unsafeBitCast(imp, to: Function.self)
        function(implementation, selector, object, secondObject)
    }

    private func invokeVoid(selector: Selector, integer: Int, object: AnyObject?) {
        typealias Function = @convention(c) (AnyObject, Selector, Int, AnyObject?) -> Void
        guard let imp = implementation.method(for: selector) else {
            assertionFailure("\(implementation) doesn't implement \(selector)")
            return
        }
        let function = unsafeBitCast(imp, to: Function.self)
        function(implementation, selector, integer, object)
    }

    private func invokeVoid(selector: Selector, object: AnyObject, integer: Int) {
        typealias Function = @convention(c) (AnyObject, Selector, AnyObject, Int) -> Void
        guard let imp = implementation.method(for: selector) else {
            assertionFailure("\(implementation) doesn't implement \(selector)")
            return
        }
        let function = unsafeBitCast(imp, to: Function.self)
        function(implementation, selector, object, integer)
    }

    private func invokeVoid(
        selector: Selector,
        object: AnyObject,
        integer: Int,
        secondObject: AnyObject?
    ) {
        typealias Function = @convention(c) (AnyObject, Selector, AnyObject, Int, AnyObject?) -> Void
        guard let imp = implementation.method(for: selector) else {
            assertionFailure("\(implementation) doesn't implement \(selector)")
            return
        }
        let function = unsafeBitCast(imp, to: Function.self)
        function(implementation, selector, object, integer, secondObject)
    }

    private func invokeVoid(
        selector: Selector,
        object: AnyObject,
        secondObject: AnyObject?,
        thirdObject: AnyObject
    ) {
        typealias Function = @convention(c) (AnyObject, Selector, AnyObject, AnyObject?, AnyObject) -> Void
        guard let imp = implementation.method(for: selector) else {
            assertionFailure("\(implementation) doesn't implement \(selector)")
            return
        }
        let function = unsafeBitCast(imp, to: Function.self)
        function(implementation, selector, object, secondObject, thirdObject)
    }
}
