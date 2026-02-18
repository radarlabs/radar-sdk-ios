//
//  RadarLocationManagerModern.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation
import CoreLocation
import UserNotifications

/// A modern implementation of RadarLocationManager using iOS 17+ Core Location APIs.
/// Structural mirror of the ObjC RadarLocationManager, using CLLocationUpdate.liveUpdates(),
/// CLMonitor, and CLBackgroundActivitySession instead of legacy delegate patterns.
@available(iOS 17.0, *)
@objc(RadarLocationManagerModern)
@objcMembers
public class RadarLocationManagerModern: NSObject, RadarLocationProviding, CLLocationManagerDelegate, @unchecked Sendable {

    // MARK: - Singleton

    @objc public static let sharedInstance = RadarLocationManagerModern()

    // MARK: - Constants

    private static let identifierPrefix = "radar_"
    private static let syncGeofenceIdentifierPrefix = "radar_geofence_"
    private static let syncBeaconIdentifierPrefix = "radar_beacon_"
    private static let syncBeaconUUIDIdentifierPrefix = "radar_uuid_"

    // MARK: - Properties (mirrors ObjC .m lines 28–59)

    private var completionHandlers = [RadarLocationCompletionHandler]()
    private var completionHandlerTimeoutItems = [DispatchWorkItem]()
    private var sending = false
    private var started = false
    private var startedInterval: Int = 0
    private var firstPermissionCheck = false

    public let permissionsHelper = RadarPermissionsHelper()
    var activityManager: RadarActivityManager?

    /// Replaces NSTimer + CLLocationManager pair from legacy path
    private var liveUpdateTask: Task<Void, Never>?

    /// Replaces startMonitoringForRegion: / CLLocationManagerDelegate region callbacks
    private var monitor: CLMonitor?

    /// Task consuming CLMonitor.events
    private var monitorTask: Task<Void, Never>?

    /// Replaces allowsBackgroundLocationUpdates + showsBackgroundLocationIndicator
    private var backgroundSession: CLBackgroundActivitySession?

    /// Still needed for visits, SLC, heading, and auth changes (no modern equivalent)
    private let locationManager = CLLocationManager()

    // MARK: - Initialization

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = kCLDistanceFilterNone

        Task {
            self.monitor = await CLMonitor("RadarSDK")
            self.startMonitorEventConsumer()
        }
    }

    // MARK: - Completion Handler Management (mirrors lines 111–158)

    private func callCompletionHandlers(status: RadarStatus, location: CLLocation?) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        guard !completionHandlers.isEmpty else { return }

        RadarLogger.shared.log(level: .debug,
            message: "Calling completion handlers | self.completionHandlers.count = \(completionHandlers.count)")

        for timeout in completionHandlerTimeoutItems {
            timeout.cancel()
        }
        for handler in completionHandlers {
            handler(status, location, RadarState.stopped())
        }

        completionHandlers.removeAll()
        completionHandlerTimeoutItems.removeAll()
    }

    private func addCompletionHandler(_ completionHandler: RadarLocationCompletionHandler?) {
        guard let completionHandler else { return }

        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        completionHandlers.append(completionHandler)

        let timeout = DispatchWorkItem { [weak self] in
            self?.timeoutCompletionHandler(completionHandler)
        }
        completionHandlerTimeoutItems.append(timeout)
        DispatchQueue.main.asyncAfter(deadline: .now() + 20, execute: timeout)
    }

    private func cancelTimeouts() {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        for timeout in completionHandlerTimeoutItems {
            timeout.cancel()
        }
        completionHandlerTimeoutItems.removeAll()
    }

    private func timeoutCompletionHandler(_ completionHandler: RadarLocationCompletionHandler?) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        RadarLogger.shared.log(level: .debug, message: "Location timeout")
        callCompletionHandlers(status: .errorLocation, location: nil)
    }

    // MARK: - Public Methods (mirrors lines 160–307)

    public func getLocationWithCompletionHandler(_ completionHandler: RadarLocationCompletionHandler?) {
        getLocationWith(.medium, completionHandler: completionHandler)
    }

    public func getLocationWith(_ desiredAccuracy: RadarTrackingOptionsDesiredAccuracy,
                         completionHandler: RadarLocationCompletionHandler?) {
        let authStatus = permissionsHelper.locationAuthorizationStatus()
        guard authStatus == .authorizedWhenInUse || authStatus == .authorizedAlways else {
            RadarDelegateHolder.sharedInstance().didFail(status: .errorPermissions)
            completionHandler?(.errorPermissions, nil, false)
            return
        }

        addCompletionHandler(completionHandler)

        // Use a single await from liveUpdates for the one-shot location
        Task {
            do {
                let config = liveConfiguration(for: desiredAccuracy)
                for try await update in CLLocationUpdate.liveUpdates(config) {
                    if let location = update.location {
                        await MainActor.run {
                            self.handleLocation(location, source: .foregroundLocation)
                        }
                        return
                    }
                    if update.isStationary {
                        // Still waiting for a fix
                        continue
                    }
                }
            } catch {
                await MainActor.run {
                    RadarLogger.shared.log(level: .debug,
                        message: "getLocation liveUpdates error: \(error)")
                    self.callCompletionHandlers(status: .errorLocation, location: nil)
                }
            }
        }
    }

    public func startTracking(with options: RadarTrackingOptions) {
        let authStatus = permissionsHelper.locationAuthorizationStatus()
        guard authStatus == .authorizedWhenInUse || authStatus == .authorizedAlways else {
            RadarDelegateHolder.sharedInstance().didFail(status: .errorPermissions)
            return
        }

        RadarSettings.tracking = true
        RadarSettings.trackingOptions = options
        updateTracking()
    }

    public func stopTracking() {
        RadarSettings.tracking = false

        if let sdkConfiguration = RadarSettings.sdkConfiguration, sdkConfiguration.extendFlushReplays {
            RadarLogger.shared.log(level: .info,
                message: "Flushing replays from stopTracking()", type: .sdkCall)
            RadarReplayBuffer.sharedInstance().flushReplays(withCompletionHandler: nil, completionHandler: nil)
        }

        guard let trackingOptions = RadarSettings.trackingOptions else { return }
        if trackingOptions.useMotion || trackingOptions.usePressure {
            locationManager.stopUpdatingHeading()
            if let activityManager = self.activityManager {
                if trackingOptions.usePressure {
                    activityManager.stopRelativeAltitudeUpdates()
                    activityManager.stopAbsoluteAltitudeUpdates()
                }
                if trackingOptions.useMotion {
                    activityManager.stopActivityUpdates()
                }
            }
        }

        trackingOptions.startTrackingAfter = nil
        trackingOptions.stopTrackingAfter = nil
        RadarSettings.trackingOptions = trackingOptions

        updateTracking()
    }

    /// Starts a Task that iterates CLLocationUpdate.liveUpdates() and throttles to the desired interval.
    /// Replaces NSTimer + startUpdatingLocation() from the legacy path.
    private func startUpdates(interval: Int, blueBar: Bool) {
        guard !started || interval != startedInterval else {
            RadarLogger.shared.log(level: .debug, message: "Already started live updates")
            return
        }

        RadarLogger.shared.log(level: .debug,
            message: "Starting live updates | interval = \(interval)")

        stopUpdates()

        // Background session replaces allowsBackgroundLocationUpdates + showsBackgroundLocationIndicator
        if blueBar {
            backgroundSession = CLBackgroundActivitySession()
        }

        let options = Radar.getTrackingOptions()
        let config = liveConfigurationForTrackingOptions(options)

        started = true
        startedInterval = interval

        liveUpdateTask = Task { [weak self] in
            do {
                var lastHandledAt: Date?
                for try await update in CLLocationUpdate.liveUpdates(config) {
                    guard let self = self, !Task.isCancelled else { return }

                    if let location = update.location {
                        let now = Date()
                        let shouldProcess: Bool
                        if let last = lastHandledAt {
                            shouldProcess = now.timeIntervalSince(last) >= Double(interval) - 0.1
                        } else {
                            shouldProcess = true
                        }

                        if shouldProcess {
                            lastHandledAt = now
                            await MainActor.run {
                                if self.completionHandlers.count > 0 {
                                    self.handleLocation(location, source: .foregroundLocation)
                                } else {
                                    let tracking = RadarSettings.tracking
                                    if !tracking {
                                        RadarLogger.shared.log(level: .debug,
                                            message: "Ignoring location: not tracking")
                                        return
                                    }
                                    self.handleLocation(location, source: .backgroundLocation)
                                }
                            }
                        }
                    }
                }
            } catch {
                await MainActor.run { [weak self] in
                    RadarLogger.shared.log(level: .debug,
                        message: "liveUpdates stream error: \(error)")
                    RadarDelegateHolder.sharedInstance().didFail(status: .errorLocation)
                    self?.callCompletionHandlers(status: .errorLocation, location: nil)
                }
            }
        }
    }

    private func stopUpdates() {
        guard liveUpdateTask != nil || started else { return }

        RadarLogger.shared.log(level: .debug, message: "Stopping live updates")

        liveUpdateTask?.cancel()
        liveUpdateTask = nil

        backgroundSession?.invalidate()
        backgroundSession = nil

        started = false
        startedInterval = 0

        if !sending {
            let delay: TimeInterval = RadarSettings.tracking ? 10 : 0
            RadarLogger.shared.log(level: .debug, message: "Scheduling shutdown")
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.shutDown()
            }
        }
    }

    private func shutDown() {
        RadarLogger.shared.log(level: .debug, message: "Shutting down")

        liveUpdateTask?.cancel()
        liveUpdateTask = nil

        backgroundSession?.invalidate()
        backgroundSession = nil
    }

    // MARK: - updateTracking (mirrors lines 321–510)

    public func updateTracking() {
        updateTracking(location: nil, fromInitialize: false)
    }

    public func updateTrackingFromInitialize() {
        updateTracking(location: nil, fromInitialize: true)
    }

    private func updateTracking(location: CLLocation?) {
        updateTracking(location: location, fromInitialize: false)
    }

    private func updateTracking(location: CLLocation?, fromInitialize: Bool) {
        DispatchQueue.main.async { [self] in
            var tracking = RadarSettings.tracking
            let options = Radar.getTrackingOptions()
            guard let localOptions = RadarSettings.trackingOptions else { return }

            RadarLogger.shared.log(level: .debug,
                message: "Updating tracking | options = \(options.dictionaryValue()); location = \(String(describing: location))")

            if !tracking, let startAfter = localOptions.startTrackingAfter, startAfter.timeIntervalSinceNow < 0 {
                RadarLogger.shared.log(level: .debug,
                    message: "Starting time-based tracking | startTrackingAfter = \(String(describing: options.startTrackingAfter))")
                RadarSettings.tracking = true
                tracking = true
            } else if tracking, let stopAfter = localOptions.stopTrackingAfter, stopAfter.timeIntervalSinceNow < 0 {
                RadarLogger.shared.log(level: .debug,
                    message: "Stopping time-based tracking | stopTrackingAfter = \(String(describing: options.stopTrackingAfter))")
                RadarSettings.tracking = false
                tracking = false
            }

            if tracking {
                // Motion & pressure
                if options.useMotion {
                    self.activityManager = RadarActivityManager.sharedInstance()
                    self.locationManager.headingFilter = 5
                    self.locationManager.startUpdatingHeading()
                    self.activityManager?.startActivityUpdates { activity in
                        var activityType: RadarActivityType = .unknown
                        if activity.stationary {
                            activityType = .stationary
                        } else if activity.walking || activity.running {
                            activityType = .foot
                        } else if activity.automotive {
                            activityType = .car
                        } else if activity.cycling {
                            activityType = .bike
                        }

                        guard activityType != .unknown else { return }

                        let previousType = RadarState.lastMotionActivityData()["type"] as? String
                        if let previousType, previousType == Radar.stringForActivityType(activityType) {
                            return
                        }

                        RadarState.setLastMotionActivityData([
                            "type": Radar.stringForActivityType(activityType),
                            "timestamp": activity.startDate.timeIntervalSince1970,
                            "confidence": activity.confidence.rawValue
                        ])

                        RadarLogger.shared.log(level: .debug,
                            message: "Activity detected, initiating trackOnce")
                        Radar.trackOnce(completionHandler: nil)
                    }
                }

                if options.usePressure {
                    self.activityManager = RadarActivityManager.sharedInstance()
                    RadarState.setMotionAuthorizationString(Radar.stringForMotionAuthorizationStatus())
                    RadarLogger.shared.log(level: .debug,
                        message: "usePressure enabled: starting relative altitude updates")
                    self.activityManager?.startRelativeAltitude { altitudeData in
                        guard let altitudeData else {
                            RadarLogger.shared.log(level: .warning,
                                message: "Relative altitude callback received nil data")
                            return
                        }
                        var currentState = (RadarState.lastRelativeAltitudeData() as? [String: Any])?.merging([:]) { a, _ in a } ?? [:]
                        currentState["pressure"] = altitudeData.pressure.doubleValue * 10
                        currentState["relativeAltitude"] = altitudeData.relativeAltitude.doubleValue
                        currentState["relativeAltitudeTimestamp"] = Date().timeIntervalSince1970
                        RadarState.setLastRelativeAltitudeData(currentState as NSDictionary as! [AnyHashable: Any])
                    }

                    self.activityManager?.startAbsoluteAltitude { altitudeData in
                        guard let altitudeData else {
                            RadarLogger.shared.log(level: .warning,
                                message: "Absolute altitude callback received nil data")
                            return
                        }
                        var currentState = (RadarState.lastRelativeAltitudeData() as? [String: Any])?.merging([:]) { a, _ in a } ?? [:]
                        currentState["altitude"] = altitudeData.altitude
                        currentState["accuracy"] = altitudeData.accuracy
                        currentState["precision"] = altitudeData.precision
                        currentState["absoluteAltitudeTimestamp"] = Date().timeIntervalSince1970
                        RadarState.setLastRelativeAltitudeData(currentState as NSDictionary as! [AnyHashable: Any])
                    }
                }

                // Desired accuracy for CLLocationManager (still used for visits/SLC)
                let desiredAccuracy: CLLocationAccuracy
                switch options.desiredAccuracy {
                case .high: desiredAccuracy = kCLLocationAccuracyBest
                case .low: desiredAccuracy = kCLLocationAccuracyKilometer
                default: desiredAccuracy = kCLLocationAccuracyHundredMeters
                }
                self.locationManager.desiredAccuracy = desiredAccuracy

                let startUpdatesAllowed = options.showBlueBar
                    || CLLocationManager.authorizationStatus() == .authorizedAlways
                let stopped = RadarState.stopped()

                if stopped {
                    if options.desiredStoppedUpdateInterval == 0 {
                        stopUpdates()
                    } else if startUpdatesAllowed {
                        startUpdates(interval: Int(options.desiredStoppedUpdateInterval), blueBar: options.showBlueBar)
                    }
                    // No bubble geofences in modern path
                } else {
                    if options.desiredMovingUpdateInterval == 0 {
                        stopUpdates()
                    } else if startUpdatesAllowed {
                        startUpdates(interval: Int(options.desiredMovingUpdateInterval), blueBar: options.showBlueBar)
                    }
                    // No bubble geofences in modern path
                }

                if !options.syncGeofences {
                    removeSyncedGeofences()
                }

                if options.useVisits {
                    self.locationManager.startMonitoringVisits()
                } else {
                    self.locationManager.stopMonitoringVisits()
                }

                if options.useSignificantLocationChanges {
                    self.locationManager.startMonitoringSignificantLocationChanges()
                } else {
                    self.locationManager.stopMonitoringSignificantLocationChanges()
                }

                if !options.beacons {
                    removeSyncedBeacons()
                }
            } else {
                stopUpdates()
                removeAllRegions()

                if !fromInitialize {
                    RadarLogger.shared.log(level: .debug,
                        message: "Stopping monitoring visits and SLCs")
                    self.locationManager.stopMonitoringVisits()
                    self.locationManager.stopMonitoringSignificantLocationChanges()
                }
            }
        }
    }

    public func updateTracking(from meta: RadarMeta?) {
        if let meta {
            if let trackingOptions = meta.trackingOptions {
                RadarLogger.shared.log(level: .debug,
                    message: "Setting remote tracking options | trackingOptions = \(trackingOptions)")
                RadarSettings.remoteTrackingOptions = trackingOptions
            } else {
                RadarSettings.remoteTrackingOptions = nil
                RadarLogger.shared.log(level: .debug,
                    message: "Removed remote tracking options | trackingOptions = \(String(describing: Radar.getTrackingOptions()))")
            }
        }
        updateTrackingFromInitialize()
    }

    public func restartPreviousTrackingOptions() {
        let previousTrackingOptions = RadarSettings.previousTrackingOptions
        RadarLogger.shared.log(level: .debug,
            message: "Restarting previous tracking options")

        if let previousTrackingOptions {
            Radar.startTracking(trackingOptions: previousTrackingOptions)
        } else {
            Radar.stopTracking()
        }

        RadarSettings.previousTrackingOptions = nil
    }

    // MARK: - Geofence & Beacon Management (mirrors lines 541–737)
    // No bubble geofences in modern path — CLLocationUpdate + CLBackgroundActivitySession makes them redundant

    public func replaceSyncedGeofences(_ geofences: [RadarGeofence]) {
        removeSyncedGeofences()

        let options = Radar.getTrackingOptions()
        let numGeofences = min(geofences.count, options.beacons ? 9 : 19)
        var requests = [UNNotificationRequest]()

        for i in 0..<numGeofences {
            let geofence = geofences[i]
            let geofenceId = geofence._id
            let identifier = "\(Self.syncGeofenceIdentifierPrefix)\(geofenceId)"

            var center: RadarCoordinate?
            var radius: Double = 100
            if let circleGeometry = geofence.geometry as? RadarCircleGeometry {
                center = circleGeometry.center
                radius = circleGeometry.radius
            } else if let polygonGeometry = geofence.geometry as? RadarPolygonGeometry {
                center = polygonGeometry.center
                radius = polygonGeometry.radius
            }

            guard let center else { continue }

            let condition = CLMonitor.CircularGeographicCondition(
                center: center.coordinate,
                radius: radius
            )
            Task {
                await self.monitor?.add(condition, identifier: identifier)
            }

            RadarLogger.shared.log(level: .debug,
                message: "Synced geofence | latitude = \(center.coordinate.latitude); longitude = \(center.coordinate.longitude); radius = \(radius); identifier = \(identifier)")

            if let metadata = geofence.metadata {
                if let content = RadarNotificationHelper.extractContent(fromMetadata: metadata, identifier: identifier) {
                    let region = CLCircularRegion(center: center.coordinate, radius: radius, identifier: identifier)
                    region.notifyOnEntry = true
                    region.notifyOnExit = false

                    var repeats = false
                    if let notificationRepeats = metadata["radar:notificationRepeats"] as? String {
                        repeats = (notificationRepeats as NSString).boolValue
                    }

                    let trigger = UNLocationNotificationTrigger(region: region, repeats: repeats)
                    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                    requests.append(request)
                }
            }
        }

        RadarNotificationHelper.updateClientSideCampaigns(withPrefix: Self.syncGeofenceIdentifierPrefix, notificationRequests: requests)
    }

    private func removeSyncedGeofences() {
        Task {
            guard let monitor = self.monitor else { return }
            for identifier in await monitor.identifiers {
                if identifier.hasPrefix(Self.syncGeofenceIdentifierPrefix) {
                    await monitor.remove(identifier)
                }
            }
        }
        RadarLogger.shared.log(level: .debug, message: "Removed synced geofences")
    }

    public func replaceSyncedBeacons(_ beacons: [RadarBeacon]) {
        if RadarSettings.useRadarModifiedBeacon { return }

        removeSyncedBeacons()

        let tracking = RadarSettings.tracking
        let options = Radar.getTrackingOptions()
        guard tracking, options.beacons else {
            RadarLogger.shared.log(level: .debug, message: "Skipping replacing synced beacons")
            return
        }

        let numBeacons = min(beacons.count, 9)

        for i in 0..<numBeacons {
            let beacon = beacons[i]
            let identifier = "\(Self.syncBeaconIdentifierPrefix)\(beacon._id ?? "")"

            guard let uuid = UUID(uuidString: beacon.uuid) else {
                RadarLogger.shared.log(level: .debug,
                    message: "Error syncing beacon | identifier = \(identifier); uuid = \(beacon.uuid)")
                continue
            }

            let condition = CLMonitor.BeaconIdentityCondition(
                uuid: uuid,
                major: UInt16(truncating: NumberFormatter().number(from: beacon.major) ?? 0),
                minor: UInt16(truncating: NumberFormatter().number(from: beacon.minor) ?? 0)
            )

            Task {
                await self.monitor?.add(condition, identifier: identifier, assuming: .unknown)
            }

            RadarLogger.shared.log(level: .debug,
                message: "Synced beacon | identifier = \(identifier); uuid = \(beacon.uuid); major = \(beacon.major); minor = \(beacon.minor)")
        }
    }

    public func replaceSyncedBeaconUUIDs(_ uuids: [String]) {
        if RadarSettings.useRadarModifiedBeacon { return }

        removeSyncedBeacons()

        let tracking = RadarSettings.tracking
        let options = Radar.getTrackingOptions()
        guard tracking, options.beacons else { return }

        let numUUIDs = min(uuids.count, 9)

        for i in 0..<numUUIDs {
            let uuidStr = uuids[i]
            let identifier = "\(Self.syncBeaconUUIDIdentifierPrefix)\(uuidStr)"

            guard let uuid = UUID(uuidString: uuidStr) else {
                RadarLogger.shared.log(level: .debug,
                    message: "Error syncing UUID | identifier = \(identifier); uuid = \(uuidStr)")
                continue
            }

            let condition = CLMonitor.BeaconIdentityCondition(uuid: uuid)

            Task {
                await self.monitor?.add(condition, identifier: identifier, assuming: .unknown)
            }

            RadarLogger.shared.log(level: .debug,
                message: "Synced UUID | identifier = \(identifier); uuid = \(uuidStr)")
        }
    }

    private func removeSyncedBeacons() {
        if RadarSettings.useRadarModifiedBeacon { return }

        Task {
            guard let monitor = self.monitor else { return }
            for identifier in await monitor.identifiers {
                if identifier.hasPrefix(Self.syncBeaconUUIDIdentifierPrefix)
                    || identifier.hasPrefix(Self.syncBeaconIdentifierPrefix) {
                    await monitor.remove(identifier)
                }
            }
        }
    }

    private func removeAllRegions() {
        Task {
            guard let monitor = self.monitor else { return }
            for identifier in await monitor.identifiers {
                if identifier.hasPrefix(Self.identifierPrefix) {
                    await monitor.remove(identifier)
                }
            }
        }
    }

    // MARK: - handleLocation (mirrors lines 741–910)

    private func handleLocation(_ location: CLLocation, source: RadarLocationSource) {
        handleLocation(location, source: source, beacons: nil)
    }

    private func handleLocation(_ location: CLLocation, source: RadarLocationSource, beacons: [RadarBeacon]?) {
        RadarLogger.shared.log(level: .debug,
            message: "Handling location | source = \(Radar.stringForLocationSource(source)); location = \(location)")

        cancelTimeouts()

        guard location.isValid else {
            RadarLogger.shared.log(level: .debug,
                message: "Invalid location | source = \(Radar.stringForLocationSource(source)); location = \(location)")
            callCompletionHandlers(status: .errorLocation, location: nil)
            return
        }

        let options = Radar.getTrackingOptions()
        let wasStopped = RadarState.stopped()
        var stopped = false

        let force = (source == .foregroundLocation || source == .manualLocation
                     || source == .beaconEnter || source == .beaconExit || source == .visitArrival)

        if wasStopped && !force && location.horizontalAccuracy >= 1000
            && options.desiredAccuracy != .low {
            RadarLogger.shared.log(level: .debug,
                message: "Skipping location: inaccurate | accuracy = \(location.horizontalAccuracy)")
            updateTracking(location: location)
            return
        }

        let tracking = RadarSettings.tracking
        if !force && !tracking {
            RadarLogger.shared.log(level: .debug, message: "Skipping location: not tracking")
            return
        }

        var distance: CLLocationDistance = CLLocationDistanceMax
        var duration: TimeInterval = 0

        if options.stopDistance > 0 && options.stopDuration > 0 {
            var lastMovedLocation = RadarState.lastMovedLocation()
            if lastMovedLocation == nil {
                lastMovedLocation = location
                RadarState.setLastMovedLocation(location)
            }
            var lastMovedAt = RadarState.lastMovedAt()
            if lastMovedAt == nil {
                lastMovedAt = location.timestamp
                RadarState.setLastMovedAt(location.timestamp)
            }

            if !force, let lastMovedAt, lastMovedAt.timeIntervalSince(location.timestamp) > 0 {
                RadarLogger.shared.log(level: .debug,
                    message: "Skipping location: old | lastMovedAt = \(lastMovedAt); location.timestamp = \(location.timestamp)")
                return
            }

            if let lastMovedLocation, let lastMovedAt {
                distance = location.distance(from: lastMovedLocation)
                duration = location.timestamp.timeIntervalSince(lastMovedAt)
                if duration == 0 {
                    duration = -location.timestamp.timeIntervalSinceNow
                }
                let arrival = source == .visitArrival
                stopped = (distance <= Double(options.stopDistance) && duration >= Double(options.stopDuration)) || arrival

                RadarLogger.shared.log(level: .debug,
                    message: "Calculating stopped | stopped = \(stopped); arrival = \(arrival); distance = \(distance); duration = \(duration)")

                if distance > Double(options.stopDistance) {
                    RadarState.setLastMovedLocation(location)
                    if !stopped {
                        RadarState.setLastMovedAt(location.timestamp)
                    }
                }
            }
        } else {
            stopped = force || source == .visitArrival
        }

        let justStopped = stopped && !wasStopped
        RadarState.setStopped(stopped)
        RadarState.setLast(location)

        RadarDelegateHolder.sharedInstance().didUpdateClientLocation(location, stopped: stopped, source: source)

        if source != .manualLocation {
            updateTracking(location: location)
        }

        callCompletionHandlers(status: .success, location: location)

        var sendLocation = location
        var sendStopped = stopped
        var replayed = false

        if let lastFailedStoppedLocation = RadarState.lastFailedStoppedLocation(),
           options.replay == .stops && !justStopped {
            sendLocation = lastFailedStoppedLocation
            sendStopped = true
            replayed = true
            RadarState.setLastFailedStoppedLocation(nil)

            RadarLogger.shared.log(level: .debug,
                message: "Replaying location | location = \(sendLocation); stopped = \(sendStopped)")
        }

        let lastSentAt = RadarState.lastSentAt()
        let ignoreSync = lastSentAt == nil || !completionHandlers.isEmpty || justStopped || replayed
            || source == .beaconEnter || source == .beaconExit
        let now = Date()
        let lastSyncInterval = lastSentAt != nil ? now.timeIntervalSince(lastSentAt!) : 0

        if !ignoreSync {
            if !force && stopped && wasStopped && distance <= Double(options.stopDistance)
                && (options.desiredStoppedUpdateInterval == 0 || options.syncLocations != .all) {
                RadarLogger.shared.log(level: .debug,
                    message: "Skipping sync: already stopped")
                return
            }

            let lastSyncIntervalWithBuffer = lastSyncInterval + 0.1
            if lastSyncIntervalWithBuffer < Double(options.desiredSyncInterval) {
                RadarLogger.shared.log(level: .debug,
                    message: "Skipping sync: desired sync interval | desiredSyncInterval = \(options.desiredSyncInterval); lastSyncInterval = \(lastSyncIntervalWithBuffer)")
                return
            }

            if !force && !justStopped && lastSyncInterval < 1 {
                RadarLogger.shared.log(level: .debug,
                    message: "Skipping sync: rate limit | justStopped = \(justStopped); lastSyncInterval = \(lastSyncInterval)")
                return
            }

            if options.syncLocations == .none {
                RadarLogger.shared.log(level: .debug,
                    message: "Skipping sync: sync mode | sync = \(RadarTrackingOptions.string(for: options.syncLocations))")
                return
            }

            let canExit = RadarState.canExit()
            if !canExit && options.syncLocations == .stopsAndExits {
                RadarLogger.shared.log(level: .debug,
                    message: "Skipping sync: can't exit | canExit = \(canExit)")
                return
            }
        }

        RadarState.updateLastSentAt()

        if source == .foregroundLocation {
            return
        }

        self.sendLocation(sendLocation, stopped: sendStopped, source: source, replayed: replayed, beacons: beacons)
    }

    // MARK: - performIndoorScanIfConfigured

    public func performIndoorScanIfConfigured(_ location: CLLocation,
                                       beacons: [RadarBeacon]?,
                                       completionHandler: @escaping ([RadarBeacon]?, String?) -> Void) {
        let options = Radar.getTrackingOptions()
        let radarSDKIndoors: AnyClass? = NSClassFromString("RadarSDKIndoors")

        if options.useIndoorScan && !RadarSettings.inSurveyMode && radarSDKIndoors != nil && RadarUtils.foreground() {
            RadarLogger.shared.log(level: .debug, message: "Starting indoor scan")

            let sel = NSSelectorFromString("startIndoorScan:forLength:withKnownLocation:completionHandler:")
            if let cls = radarSDKIndoors, cls.responds(to: sel) {
                let imp = cls.method(for: sel)
                typealias IndoorScanFunc = @convention(c) (AnyClass, Selector, String, Int32, CLLocation, @escaping (String?, CLLocation?) -> Void) -> Void
                let func_ = unsafeBitCast(imp, to: IndoorScanFunc.self)
                func_(cls, sel, "", 5, location) { indoorScanResult, _ in
                    RadarLogger.shared.log(level: .debug,
                        message: "Indoor scan completed: \(indoorScanResult?.count ?? 0) chars")
                    completionHandler(beacons, indoorScanResult)
                }
            } else {
                completionHandler(beacons, nil)
            }
        } else {
            if options.useIndoorScan && !RadarSettings.inSurveyMode && radarSDKIndoors == nil {
                RadarLogger.shared.log(level: .debug, message: "RadarSDKIndoors not available, skipping indoor scan")
            } else if options.useIndoorScan && !RadarSettings.inSurveyMode && radarSDKIndoors != nil && !RadarUtils.foreground() {
                RadarLogger.shared.log(level: .debug, message: "App in background, skipping indoor scan (Bluetooth not available)")
            }
            completionHandler(beacons, nil)
        }
    }

    // MARK: - sendLocation (mirrors lines 939–1059)

    private func sendLocation(_ location: CLLocation, stopped: Bool, source: RadarLocationSource, replayed: Bool, beacons: [RadarBeacon]?) {
        RadarLogger.shared.log(level: .debug,
            message: "Sending location | source = \(Radar.stringForLocationSource(source)); location = \(location); stopped = \(stopped); replayed = \(replayed)")

        sending = true

        let options = Radar.getTrackingOptions()

        if RadarSettings.useRadarModifiedBeacon {
            let callTrackAPI: ([RadarBeacon]?) -> Void = { [weak self] beacons in
                guard let self else { return }
                self.performIndoorScanIfConfigured(location, beacons: beacons) { beacons, indoorScan in
                    Radar.apiTrack(
                        with: location,
                        stopped: stopped,
                        foreground: RadarUtils.foreground(),
                        source: source,
                        replayed: replayed,
                        beacons: beacons,
                        indoorScan: indoorScan
                    ) { status, _, _, _, nearbyGeofences, config, _ in
                        self.sending = false
                        self.updateTracking(from:config?.meta)
                        if let nearbyGeofences {
                            self.replaceSyncedGeofences(nearbyGeofences)
                        }
                    }
                }
            }

            if options.beacons
                && source != .beaconEnter && source != .beaconExit
                && source != .mockLocation && source != .manualLocation {
                RadarLogger.shared.log(level: .debug, message: "Searching for nearby beacons")

                Radar.apiSearchBeacons(
                    near: location, radius: 1000, limit: 10
                ) { [weak self] status, _, beacons, beaconUUIDs in
                    guard let self else { return }
                    if let beaconUUIDs, !beaconUUIDs.isEmpty {
                        self.replaceSyncedBeaconUUIDs(beaconUUIDs as! [String])
                        RadarUtils.run(onMainThread: {
                            RadarBeaconManager.sharedInstance().rangeBeaconUUIDs(beaconUUIDs as! [String]) { status, beacons in
                                if status != .success || beacons == nil {
                                    callTrackAPI(nil)
                                    return
                                }
                                callTrackAPI(beacons)
                            }
                        })
                    } else if let beacons, !beacons.isEmpty {
                        self.replaceSyncedBeacons(beacons)
                        RadarUtils.run(onMainThread: {
                            RadarBeaconManager.sharedInstance().rangeBeacons(beacons) { status, beacons in
                                if status != .success || beacons == nil {
                                    callTrackAPI(nil)
                                    return
                                }
                                callTrackAPI(beacons)
                            }
                        })
                    } else {
                        callTrackAPI([])
                    }
                }
            } else {
                callTrackAPI(nil)
            }
        } else {
            if options.beacons {
                RadarLogger.shared.log(level: .debug, message: "Searching for nearby beacons")

                if source != .beaconEnter && source != .beaconExit
                    && source != .mockLocation && source != .manualLocation {
                    Radar.apiSearchBeacons(
                        near: location, radius: 1000, limit: 10
                    ) { [weak self] _, _, beacons, beaconUUIDs in
                        guard let self else { return }
                        if let beaconUUIDs, !beaconUUIDs.isEmpty {
                            self.replaceSyncedBeaconUUIDs(beaconUUIDs as! [String])
                        } else if let beacons, !beacons.isEmpty {
                            self.replaceSyncedBeacons(beacons)
                        }
                    }
                }
            }

            performIndoorScanIfConfigured(location, beacons: beacons) { [weak self] beacons, indoorScan in
                guard let self else { return }
                Radar.apiTrack(
                    with: location,
                    stopped: stopped,
                    foreground: RadarUtils.foreground(),
                    source: source,
                    replayed: replayed,
                    beacons: beacons,
                    indoorScan: indoorScan
                ) { status, _, _, _, nearbyGeofences, config, _ in
                    self.sending = false
                    guard status == .success, let config else { return }
                    self.updateTracking(from:config.meta)
                    if let nearbyGeofences {
                        self.replaceSyncedGeofences(nearbyGeofences)
                    }
                }
            }
        }
    }

    // MARK: - CLMonitor Event Handling (replaces delegate methods)

    private func startMonitorEventConsumer() {
        monitorTask = Task { [weak self] in
            guard let self, let monitor = self.monitor else { return }
            do {
                for try await event in await monitor.events {
                    await MainActor.run {
                        self.handleMonitorEvent(event)
                    }
                }
            } catch {
                RadarLogger.shared.log(level: .debug, message: "Monitor events stream error: \(error)")
            }
        }
    }

    private func handleMonitorEvent(_ event: CLMonitor.Event) {
        let identifier = event.identifier

        guard identifier.hasPrefix(Self.identifierPrefix) else {
            RadarLogger.shared.log(level: .debug, message: "Ignoring monitor event: wrong prefix")
            return
        }

        let tracking = RadarSettings.tracking
        guard tracking else {
            RadarLogger.shared.log(level: .debug, message: "Ignoring monitor event: not tracking")
            return
        }

        let location: CLLocation
        if let mgrLocation = locationManager.location, mgrLocation.isValid {
            location = mgrLocation
        } else if let lastLocation = RadarState.lastLocation() {
            location = lastLocation
        } else {
            return
        }

        let isEntry = event.state == .satisfied
        let isExit = event.state == .unsatisfied

        if identifier.hasPrefix(Self.syncBeaconUUIDIdentifierPrefix) {
            // Need to construct a CLBeaconRegion from the identifier for the beacon manager
            let uuidStr = String(identifier.dropFirst(Self.syncBeaconUUIDIdentifierPrefix.count))
            guard let uuid = UUID(uuidString: uuidStr) else { return }
            let beaconRegion = CLBeaconRegion(uuid: uuid, identifier: identifier)

            if isEntry {
                RadarBeaconManager.sharedInstance().handleBeaconUUIDEntry(for: beaconRegion) { [weak self] _, nearbyBeacons in
                    self?.handleLocation(location, source: .beaconEnter, beacons: nearbyBeacons)
                }
            } else if isExit {
                RadarBeaconManager.sharedInstance().handleBeaconUUIDExit(for: beaconRegion) { [weak self] _, nearbyBeacons in
                    self?.handleLocation(location, source: .beaconExit, beacons: nearbyBeacons)
                }
            }
        } else if identifier.hasPrefix(Self.syncBeaconIdentifierPrefix) {
            let beaconId = String(identifier.dropFirst(Self.syncBeaconIdentifierPrefix.count))
            // For specific beacon entries we need UUID/major/minor — we'd need to look up from the monitor
            // For now, create a generic beacon region; the beacon manager handles ranging
            // The beacon manager expects a CLBeaconRegion — we retrieve the condition from the monitor
            Task {
                guard let record = await self.monitor?.record(for: identifier) else { return }
                if let beaconCondition = record.lastEvent.refinement as? CLMonitor.BeaconIdentityCondition {
                    let beaconRegion = CLBeaconRegion(
                        uuid: beaconCondition.uuid,
                        major: beaconCondition.major as! UInt16,
                        minor: beaconCondition.minor as! UInt16,
                        identifier: identifier
                    )
                    await MainActor.run {
                        if isEntry {
                            RadarBeaconManager.sharedInstance().handleBeaconEntry(for: beaconRegion) { [weak self] _, nearbyBeacons in
                                self?.handleLocation(location, source: .beaconEnter, beacons: nearbyBeacons)
                            }
                        } else if isExit {
                            RadarBeaconManager.sharedInstance().handleBeaconExit(for: beaconRegion) { [weak self] _, nearbyBeacons in
                                self?.handleLocation(location, source: .beaconExit, beacons: nearbyBeacons)
                            }
                        }
                    }
                }
            }
        } else if identifier.hasPrefix(Self.syncGeofenceIdentifierPrefix) {
            if isEntry {
                handleLocation(location, source: .geofenceEnter)
            } else if isExit {
                handleLocation(location, source: .geofenceExit)
            }
        }
    }

    // MARK: - CLLocationManagerDelegate (visits, heading, auth — no modern equivalent)

    public func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        guard let managerLocation = manager.location else { return }

        RadarLogger.shared.log(level: .debug,
            message: "Visit detected | arrival = \(visit.arrivalDate); departure = \(visit.departureDate); horizontalAccuracy = \(visit.horizontalAccuracy)")

        let tracking = RadarSettings.tracking
        guard tracking else {
            RadarLogger.shared.log(level: .debug, message: "Ignoring visit: not tracking")
            return
        }

        if visit.departureDate == .distantFuture {
            handleLocation(managerLocation, source: .visitArrival)
        } else {
            handleLocation(managerLocation, source: .visitDeparture)
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        RadarState.setLastHeadingData([
            "magneticHeading": newHeading.magneticHeading,
            "trueHeading": newHeading.trueHeading,
            "headingAccuracy": newHeading.headingAccuracy,
            "x": newHeading.x,
            "y": newHeading.y,
            "z": newHeading.z,
            "timestamp": newHeading.timestamp.timeIntervalSince1970
        ])
    }

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if firstPermissionCheck {
            firstPermissionCheck = false
            return
        }

        let status = manager.authorizationStatus
        if (status == .authorizedAlways || status == .authorizedWhenInUse) {
            guard let sdkConfig = RadarSettings.sdkConfiguration else { return }
            if sdkConfig.trackOnceOnAppOpen || sdkConfig.startTrackingOnInitialize {
                RadarLogger.shared.log(level: .info, message: "Location services authorized")
                Radar.trackOnce(completionHandler: nil)
                if let trackingOptions = RadarSettings.trackingOptions,
                   sdkConfig.startTrackingOnInitialize && !RadarSettings.tracking {
                    Radar.startTracking(trackingOptions: trackingOptions)
                }
            }
        }
    }

    // MARK: - Helpers

    /// Maps RadarTrackingOptionsDesiredAccuracy to a CLLocationUpdate.LiveConfiguration for one-shot requests.
    private func liveConfiguration(for desiredAccuracy: RadarTrackingOptionsDesiredAccuracy) -> CLLocationUpdate.LiveConfiguration {
        switch desiredAccuracy {
        case .high: return .default
        case .low: return .otherNavigation
        default: return .otherNavigation
        }
    }

    /// Maps RadarTrackingOptions to the appropriate CLLocationUpdate.LiveConfiguration.
    private func liveConfigurationForTrackingOptions(_ options: RadarTrackingOptions) -> CLLocationUpdate.LiveConfiguration {
        switch options.liveUpdateConfiguration {
        case .automotiveNavigation: return .automotiveNavigation
        case .otherNavigation: return .otherNavigation
        case .fitness: return .fitness
        case .airborne: return .airborne
        default: return .default
        }
    }
}
