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
/// The `isUpdating*` flags are not locked. Callers start and stop updates from the main thread.
@objc(RadarActivityManager)
class RadarActivityManager: NSObject, @unchecked Sendable {

    @objc(sharedInstance)
    static let shared = RadarActivityManager()

    /// The `RadarSDKMotion` instance. `Radar.initialize` sets it when the app links RadarSDKMotion.
    @objc var radarSDKMotion: RadarMotionProtocol?

    let activityQueue: OperationQueue
    let pressureQueue: OperationQueue
    let absoluteAltitudeQueue: OperationQueue
    private(set) var isUpdatingActivity = false
    private(set) var isUpdatingPressure = false
    private(set) var isUpdatingAbsoluteAltitude = false

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

        guard !isUpdatingAbsoluteAltitude, !isUpdatingActivity, !isUpdatingPressure else {
            return
        }

        RadarLogger.shared.info(
            "requestPermission: warming up CoreMotion sensors (activity, relative altitude, absolute altitude if available)"
        )
        radarSDKMotion.startActivityUpdates(to: activityQueue) { _ in
            radarSDKMotion.stopActivityUpdates()
        }
        radarSDKMotion.startRelativeAltitudeUpdates(to: pressureQueue) { _, _ in
            radarSDKMotion.stopRelativeAltitudeUpdates()
        }
        radarSDKMotion.startAbsoluteAltitudeUpdates(to: absoluteAltitudeQueue) { _, _ in
            radarSDKMotion.stopAbsoluteAltitudeUpdates()
        }
    }

    @objc(startActivityUpdatesWithHandler:)
    func startActivityUpdates(handler: ((CMMotionActivity) -> Void)?) {
        guard let radarSDKMotion = motionOrLog() else {
            return
        }

        RadarLogger.shared.debug("startActivityUpdatesWithHandler")

        guard !isUpdatingActivity else {
            return
        }
        isUpdatingActivity = true

        let handlerBox = RadarActivityMainActorBox(value: handler)
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

    @objc func stopActivityUpdates() {
        guard let radarSDKMotion = motionOrLog() else {
            return
        }
        radarSDKMotion.stopActivityUpdates()
        isUpdatingActivity = false
    }

    @objc(startRelativeAltitudeWithHandler:)
    func startRelativeAltitude(handler: ((CMAltitudeData?) -> Void)?) {
        guard let radarSDKMotion = motionOrLog() else {
            return
        }
        guard !isUpdatingPressure else {
            RadarLogger.shared.debug("startRelativeAltitudeWithHandler: already updating pressure; ignoring duplicate call")
            return
        }
        isUpdatingPressure = true
        RadarLogger.shared.info("startRelativeAltitudeWithHandler: starting CMAltimeter relative updates")

        let handlerBox = RadarActivityMainActorBox(value: handler)
        radarSDKMotion.startRelativeAltitudeUpdates(to: pressureQueue) { altitudeData, error in
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
        isUpdatingPressure = false
        radarSDKMotion.stopRelativeAltitudeUpdates()
    }

    // The SDK's deployment target is iOS 15, so absolute altitude needs no availability check.
    @objc(startAbsoluteAltitudeWithHandler:)
    func startAbsoluteAltitude(handler: ((CMAbsoluteAltitudeData?) -> Void)?) {
        guard let radarSDKMotion = motionOrLog() else {
            return
        }
        isUpdatingAbsoluteAltitude = true
        RadarLogger.shared.info("startAbsoluteAltitudeWithHandler: starting CMAltimeter absolute updates (iOS 15+)")

        let handlerBox = RadarActivityMainActorBox(value: handler)
        radarSDKMotion.startAbsoluteAltitudeUpdates(to: absoluteAltitudeQueue) { sample, error in
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
            guard let altitudeData = (sample as AnyObject?) as? CMAbsoluteAltitudeData else {
                RadarLogger.shared.warning(
                    "Absolute altitude handler invoked with nil altitudeData at \(Self.format(callbackTime)) "
                        + "- this will cause altitude to be undefined"
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
        isUpdatingAbsoluteAltitude = false
        radarSDKMotion.stopAbsoluteAltitudeUpdates()
    }

    // MARK: - Helpers

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
