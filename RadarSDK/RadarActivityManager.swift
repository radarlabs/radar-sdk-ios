//
//  RadarActivityManager.swift
//  RadarSDK
//
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

import CoreMotion
import Foundation

/// Holds a handler or a Core Motion sample while it moves to the main actor. The handlers come from
/// Objective-C and the samples are not `Sendable`, but the main actor is the only reader.
private struct RadarActivityMainActorBox<Value>: @unchecked Sendable {
    let value: Value
}

/// Starts and stops Core Motion activity and altitude updates through `RadarSDKMotion`. Each start
/// method does nothing when `radarSDKMotion` is not set, and it calls its handler on the main actor.
///
/// You can call every method from any thread. A lock keeps each `isUpdating*` flag and its Core
/// Motion start or stop call together, so a start and a stop on different threads cannot leave a
/// sensor on with its flag off, or off with its flag on.
@objc(RadarActivityManager)
class RadarActivityManager: NSObject, @unchecked Sendable {

    @objc(sharedInstance)
    static let shared = RadarActivityManager()

    /// The `RadarSDKMotion` instance. `Radar.initialize` sets it when the app links RadarSDKMotion.
    @objc var radarSDKMotion: RadarMotionProtocol?

    let activityQueue: OperationQueue
    let pressureQueue: OperationQueue
    let absoluteAltitudeQueue: OperationQueue

    // Recursive, so a `RadarSDKMotion` that calls a handler before its start method returns does
    // not deadlock the warm-up handlers in `requestPermission`.
    private let lock = NSRecursiveLock()
    private var updatingActivity = false
    private var updatingPressure = false
    private var updatingAbsoluteAltitude = false

    var isUpdatingActivity: Bool { locked { updatingActivity } }
    var isUpdatingPressure: Bool { locked { updatingPressure } }
    var isUpdatingAbsoluteAltitude: Bool { locked { updatingAbsoluteAltitude } }

    override init() {
        activityQueue = OperationQueue()
        pressureQueue = OperationQueue()
        absoluteAltitudeQueue = OperationQueue()
        activityQueue.name = "com.radar.activityQueue"
        pressureQueue.name = "com.radar.pressureQueue"
        absoluteAltitudeQueue.name = "com.radar.absoluteAltitudeQueue"
        super.init()
    }

    /// Starts each sensor and stops it at the first sample, so that iOS asks for the Motion &
    /// Fitness permission. It does nothing while an update is already running.
    @objc func requestPermission() {
        guard let radarSDKMotion = motionOrLog() else {
            return
        }

        locked {
            guard !updatingAbsoluteAltitude, !updatingActivity, !updatingPressure else {
                return
            }

            RadarLogger.shared.info(
                "requestPermission: warming up CoreMotion sensors (activity, relative altitude, absolute altitude if available)"
            )
            // A warm-up sample can already be on its queue when tracking starts the same sensor.
            // Stop the sensor only if tracking did not start it.
            radarSDKMotion.startActivityUpdates(to: activityQueue) { _ in
                self.locked {
                    if !self.updatingActivity {
                        radarSDKMotion.stopActivityUpdates()
                    }
                }
            }
            radarSDKMotion.startRelativeAltitudeUpdates(to: pressureQueue) { _, _ in
                self.locked {
                    if !self.updatingPressure {
                        radarSDKMotion.stopRelativeAltitudeUpdates()
                    }
                }
            }
            radarSDKMotion.startAbsoluteAltitudeUpdates(to: absoluteAltitudeQueue) { _, _ in
                self.locked {
                    if !self.updatingAbsoluteAltitude {
                        radarSDKMotion.stopAbsoluteAltitudeUpdates()
                    }
                }
            }
        }
    }

    @objc(startActivityUpdatesWithHandler:)
    func startActivityUpdates(handler: ((CMMotionActivity) -> Void)?) {
        guard let radarSDKMotion = motionOrLog() else {
            return
        }

        RadarLogger.shared.debug("startActivityUpdatesWithHandler")

        let handlerBox = RadarActivityMainActorBox(value: handler)
        locked {
            guard !updatingActivity else {
                return
            }
            updatingActivity = true

            radarSDKMotion.startActivityUpdates(to: activityQueue) { activity in
                guard let activity else {
                    return
                }
                let activityBox = RadarActivityMainActorBox(value: activity)
                Task { @MainActor in
                    handlerBox.value?(activityBox.value)
                }
            }
        }
    }

    @objc func stopActivityUpdates() {
        guard let radarSDKMotion = motionOrLog() else {
            return
        }
        locked {
            radarSDKMotion.stopActivityUpdates()
            updatingActivity = false
        }
    }

    @objc(startRelativeAltitudeWithHandler:)
    func startRelativeAltitude(handler: ((CMAltitudeData?) -> Void)?) {
        guard let radarSDKMotion = motionOrLog() else {
            return
        }
        let handlerBox = RadarActivityMainActorBox(value: handler)
        locked {
            guard !updatingPressure else {
                RadarLogger.shared.debug(
                    "startRelativeAltitudeWithHandler: already updating pressure; ignoring duplicate call")
                return
            }
            updatingPressure = true
            RadarLogger.shared.info("startRelativeAltitudeWithHandler: starting CMAltimeter relative updates")
            radarSDKMotion.startRelativeAltitudeUpdates(to: pressureQueue, withHandler: Self.relativeAltitudeHandler(handlerBox))
        }
    }

    private static func relativeAltitudeHandler(
        _ handlerBox: RadarActivityMainActorBox<((CMAltitudeData?) -> Void)?>
    ) -> CMAltitudeHandler {
        return { altitudeData, error in
            let callbackTime = Date().timeIntervalSince1970
            RadarLogger.shared.debug(
                "Relative altitude callback invoked at \(Self.format(callbackTime)), "
                    + "Motion & Fitness auth status: \(Self.motionAuthorizationStatus())"
            )

            if let error {
                RadarLogger.shared.error("startRelativeAltitudeWithHandler error: \(Self.describe(error))")
                RadarLogger.shared.warning(
                    "Ensure Motion & Fitness permissions are granted and device supports barometer (CMAltimeter)")
                return
            }
            guard let altitudeData else {
                RadarLogger.shared.warning(
                    "Relative altitude handler invoked with nil altitudeData at \(Self.format(callbackTime)) "
                        + "- this will cause altitude to be undefined"
                )
                return
            }

            let pressure = altitudeData.pressure.doubleValue
            RadarLogger.shared.debug(
                "Relative altitude sample: pressure=\(Self.format(pressure)) kPa "
                    + "(\(String(format: "%.1f", pressure * 10.0)) hPa), "
                    + "relative=\(Self.format(altitudeData.relativeAltitude.doubleValue)) m, "
                    + "timestamp=\(Self.format(callbackTime))"
            )
            let altitudeBox = RadarActivityMainActorBox(value: altitudeData)
            Task { @MainActor in
                handlerBox.value?(altitudeBox.value)
            }
        }
    }

    @objc func stopRelativeAltitudeUpdates() {
        guard let radarSDKMotion = motionOrLog() else {
            return
        }
        RadarLogger.shared.debug("stopRelativeAltitudeUpdates")
        locked {
            updatingPressure = false
            radarSDKMotion.stopRelativeAltitudeUpdates()
        }
    }

    // The SDK's deployment target is iOS 15, so absolute altitude needs no availability check.
    @objc(startAbsoluteAltitudeWithHandler:)
    func startAbsoluteAltitude(handler: ((CMAbsoluteAltitudeData?) -> Void)?) {
        guard let radarSDKMotion = motionOrLog() else {
            return
        }
        let handlerBox = RadarActivityMainActorBox(value: handler)
        locked {
            guard !updatingAbsoluteAltitude else {
                RadarLogger.shared.debug(
                    "startAbsoluteAltitudeWithHandler: already updating absolute altitude; ignoring duplicate call")
                return
            }
            updatingAbsoluteAltitude = true
            RadarLogger.shared.info(
                "startAbsoluteAltitudeWithHandler: starting CMAltimeter absolute updates (iOS 15+)")
            radarSDKMotion.startAbsoluteAltitudeUpdates(
                to: absoluteAltitudeQueue, withHandler: Self.absoluteAltitudeHandler(handlerBox))
        }
    }

    private static func absoluteAltitudeHandler(
        _ handlerBox: RadarActivityMainActorBox<((CMAbsoluteAltitudeData?) -> Void)?>
    ) -> CMAltitudeHandler {
        return { sample, error in
            let callbackTime = Date().timeIntervalSince1970
            RadarLogger.shared.debug(
                "Absolute altitude callback invoked at \(Self.format(callbackTime)), "
                    + "Motion & Fitness auth status: \(Self.motionAuthorizationStatus())"
            )

            if let error {
                RadarLogger.shared.error("startAbsoluteAltitudeUpdatesToQueue error: \(Self.describe(error))")
                return
            }
            // `RadarMotionProtocol` declares this handler with `CMAltitudeHandler`, but RadarSDKMotion
            // passes the handler to `CMAltimeter`, which sends `CMAbsoluteAltitudeData`.
            guard let sample else {
                RadarLogger.shared.warning(
                    "Absolute altitude handler invoked with nil altitudeData at \(Self.format(callbackTime)) "
                        + "- this will cause altitude to be undefined"
                )
                return
            }
            guard let altitudeData = (sample as AnyObject) as? CMAbsoluteAltitudeData else {
                RadarLogger.shared.error(
                    "Absolute altitude handler invoked with \(type(of: sample)), not CMAbsoluteAltitudeData; "
                        + "dropping the sample"
                )
                return
            }

            RadarLogger.shared.debug(
                "Absolute altitude sample: altitude=\(Self.format(altitudeData.altitude)) m, "
                    + "accuracy=\(Self.format(altitudeData.accuracy)) m, "
                    + "precision=\(Self.format(altitudeData.precision)) m, "
                    + "timestamp=\(Self.format(callbackTime))"
            )
            let altitudeBox = RadarActivityMainActorBox(value: altitudeData)
            Task { @MainActor in
                handlerBox.value?(altitudeBox.value)
            }
        }
    }

    @objc func stopAbsoluteAltitudeUpdates() {
        guard let radarSDKMotion = motionOrLog() else {
            return
        }
        locked {
            updatingAbsoluteAltitude = false
            radarSDKMotion.stopAbsoluteAltitudeUpdates()
        }
    }

    // MARK: - Helpers

    private func locked<T>(_ body: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }

    private func motionOrLog() -> RadarMotionProtocol? {
        guard let radarSDKMotion else {
            RadarLogger.shared.debug("radarSDKMotion is not set")
            return nil
        }
        return radarSDKMotion
    }

    private static func format(_ value: Double) -> String {
        String(format: "%.3f", value)
    }

    private static func describe(_ error: Error) -> String {
        let nsError = error as NSError
        return "\(nsError.localizedDescription) (domain: \(nsError.domain), code: \(nsError.code))"
    }

    // `Radar.stringForMotionAuthorizationStatus` is declared in Radar+Internal.h, which Swift can't
    // see. `Radar.initialize` sets the bridge before it sets `radarSDKMotion`.
    private static func motionAuthorizationStatus() -> String {
        RadarSwift.bridge?.motionAuthorizationString() ?? "unknown"
    }
}
