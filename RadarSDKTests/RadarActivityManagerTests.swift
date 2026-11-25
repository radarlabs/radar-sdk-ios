//
//  RadarActivityManagerTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreMotion
import Foundation
import ObjectiveC
import Testing

@testable import RadarSDK

/// Records the calls that `RadarActivityManager` makes, and keeps the handlers so a test can send samples.
final class TrackingRadarMotion: NSObject, RadarMotionProtocol, @unchecked Sendable {
    private(set) var calls: [String] = []
    private(set) var queues: [OperationQueue] = []
    private(set) var activityHandlers: [CMMotionActivityHandler] = []
    private(set) var relativeAltitudeHandlers: [CMAltitudeHandler] = []
    private(set) var absoluteAltitudeHandlers: [CMAltitudeHandler] = []

    static func stringForMotionAuthorization() -> String { "AUTHORIZED" }

    func startActivityUpdates(to queue: OperationQueue, withHandler handler: @escaping CMMotionActivityHandler) {
        calls.append("startActivityUpdates")
        queues.append(queue)
        activityHandlers.append(handler)
    }

    func stopActivityUpdates() {
        calls.append("stopActivityUpdates")
    }

    func startRelativeAltitudeUpdates(to queue: OperationQueue, withHandler handler: @escaping CMAltitudeHandler) {
        calls.append("startRelativeAltitudeUpdates")
        queues.append(queue)
        relativeAltitudeHandlers.append(handler)
    }

    func stopRelativeAltitudeUpdates() {
        calls.append("stopRelativeAltitudeUpdates")
    }

    func startAbsoluteAltitudeUpdates(to queue: OperationQueue, withHandler handler: @escaping CMAltitudeHandler) {
        calls.append("startAbsoluteAltitudeUpdates")
        queues.append(queue)
        absoluteAltitudeHandlers.append(handler)
    }

    func stopAbsoluteAltitudeUpdates() {
        calls.append("stopAbsoluteAltitudeUpdates")
    }
}

@Suite("RadarActivityManager")
struct RadarActivityManagerTests {

    private func makeManager() -> (RadarActivityManager, TrackingRadarMotion) {
        let manager = RadarActivityManager()
        let motion = TrackingRadarMotion()
        manager.radarSDKMotion = motion
        return (manager, motion)
    }

    // MARK: - radarSDKMotion == nil

    @Test("Without radarSDKMotion, start methods do not set the updating flags")
    func startWithoutMotionDoesNothing() {
        let manager = RadarActivityManager()

        manager.startActivityUpdates { _ in }
        manager.startRelativeAltitude { _ in }
        manager.startAbsoluteAltitude { _ in }
        manager.requestPermission()

        #expect(manager.isUpdatingActivity == false)
        #expect(manager.isUpdatingPressure == false)
        #expect(manager.isUpdatingAbsoluteAltitude == false)
    }

    @Test("Without radarSDKMotion, stop methods keep the updating flags")
    func stopWithoutMotionKeepsFlags() {
        let (manager, _) = makeManager()
        manager.startActivityUpdates { _ in }
        manager.startRelativeAltitude { _ in }
        manager.startAbsoluteAltitude { _ in }
        manager.radarSDKMotion = nil

        manager.stopActivityUpdates()
        manager.stopRelativeAltitudeUpdates()
        manager.stopAbsoluteAltitudeUpdates()

        #expect(manager.isUpdatingActivity)
        #expect(manager.isUpdatingPressure)
        #expect(manager.isUpdatingAbsoluteAltitude)
    }

    // MARK: - Queues

    @Test("Each update type uses its own named queue")
    func queuesHaveNames() {
        let manager = RadarActivityManager()

        #expect(manager.activityQueue.name == "com.radar.activityQueue")
        #expect(manager.pressureQueue.name == "com.radar.pressureQueue")
        #expect(manager.absoluteAltitudeQueue.name == "com.radar.absoluteAltitudeQueue")
    }

    @Test("Objective-C reaches the class and the shared instance by their old names")
    func objectiveCNamesAreKept() {
        #expect(NSClassFromString("RadarActivityManager") === RadarActivityManager.self)
        #expect(class_getClassMethod(RadarActivityManager.self, NSSelectorFromString("sharedInstance")) != nil)
    }

    // MARK: - Activity

    @Test("startActivityUpdates sets the flag and ignores a second start")
    func activityStartIsIdempotent() {
        let (manager, motion) = makeManager()

        manager.startActivityUpdates { _ in }
        manager.startActivityUpdates { _ in }

        #expect(manager.isUpdatingActivity)
        #expect(motion.calls == ["startActivityUpdates"])
        #expect(motion.queues.first === manager.activityQueue)
    }

    @Test("stopActivityUpdates clears the flag, so the next start starts again")
    func activityStopClearsFlag() {
        let (manager, motion) = makeManager()
        manager.startActivityUpdates { _ in }

        manager.stopActivityUpdates()
        #expect(manager.isUpdatingActivity == false)

        manager.startActivityUpdates { _ in }
        #expect(motion.calls == ["startActivityUpdates", "stopActivityUpdates", "startActivityUpdates"])
    }

    @Test("Activity samples go to the handler on the main actor, and nil samples are dropped")
    @MainActor
    func activitySampleReachesHandler() async {
        let (manager, motion) = makeManager()
        let activity = StubMotionActivity(stationary: true)

        await withCheckedContinuation { continuation in
            manager.startActivityUpdates { sample in
                MainActor.assertIsolated()
                #expect(sample === activity)
                continuation.resume()
            }
            let handler = motion.activityHandlers[0]
            handler(nil)
            handler(activity)
        }
    }

    // MARK: - Relative altitude

    @Test("startRelativeAltitude sets the flag and ignores a second start")
    func relativeAltitudeStartIsIdempotent() {
        let (manager, motion) = makeManager()

        manager.startRelativeAltitude { _ in }
        manager.startRelativeAltitude { _ in }

        #expect(manager.isUpdatingPressure)
        #expect(motion.calls == ["startRelativeAltitudeUpdates"])
        #expect(motion.queues.first === manager.pressureQueue)
    }

    @Test("stopRelativeAltitudeUpdates clears the flag")
    func relativeAltitudeStopClearsFlag() {
        let (manager, motion) = makeManager()
        manager.startRelativeAltitude { _ in }

        manager.stopRelativeAltitudeUpdates()

        #expect(manager.isUpdatingPressure == false)
        #expect(motion.calls == ["startRelativeAltitudeUpdates", "stopRelativeAltitudeUpdates"])
    }

    @Test("Relative altitude errors and nil samples do not call the handler")
    @MainActor
    func relativeAltitudeErrorIsDropped() async {
        let (manager, motion) = makeManager()
        let sample = StubAltitudeData(pressure: 100, relativeAltitude: 1)

        await withCheckedContinuation { continuation in
            // Only the last call has data and no error. If an earlier call reached the handler, the
            // continuation would resume twice and crash.
            manager.startRelativeAltitude { altitudeData in
                #expect(altitudeData === sample)
                continuation.resume()
            }
            let handler = motion.relativeAltitudeHandlers[0]
            handler(sample, NSError(domain: "test", code: 1))
            handler(nil, nil)
            handler(sample, nil)
        }
    }

    // MARK: - Absolute altitude

    @Test("startAbsoluteAltitude sets the flag, ignores a second start, and stop clears it")
    func absoluteAltitudeStartAndStop() {
        let (manager, motion) = makeManager()

        manager.startAbsoluteAltitude { _ in }
        manager.startAbsoluteAltitude { _ in }
        #expect(manager.isUpdatingAbsoluteAltitude)
        #expect(motion.queues.first === manager.absoluteAltitudeQueue)

        manager.stopAbsoluteAltitudeUpdates()
        #expect(manager.isUpdatingAbsoluteAltitude == false)
        #expect(motion.calls == ["startAbsoluteAltitudeUpdates", "stopAbsoluteAltitudeUpdates"])
    }

    @Test("Absolute altitude samples reach the handler as CMAbsoluteAltitudeData")
    @MainActor
    func absoluteAltitudeSampleReachesHandler() async {
        let (manager, motion) = makeManager()
        let sample = StubAbsoluteAltitudeData(altitude: 10, accuracy: 1, precision: 1)

        await withCheckedContinuation { continuation in
            manager.startAbsoluteAltitude { altitudeData in
                #expect(altitudeData === sample)
                continuation.resume()
            }
            // `RadarMotionProtocol` types this handler as `CMAltitudeHandler`, but Core Motion sends
            // `CMAbsoluteAltitudeData`. Pass it the same way.
            let handler = motion.absoluteAltitudeHandlers[0]
            handler(nil, NSError(domain: "test", code: 1))
            handler(unsafeBitCast(sample, to: CMAltitudeData.self), nil)
        }
    }

    // MARK: - requestPermission

    @Test("requestPermission starts each sensor and stops it at the first sample")
    func requestPermissionWarmsUpSensors() {
        let (manager, motion) = makeManager()

        manager.requestPermission()

        #expect(motion.calls == ["startActivityUpdates", "startRelativeAltitudeUpdates", "startAbsoluteAltitudeUpdates"])
        #expect(manager.isUpdatingActivity == false)
        #expect(manager.isUpdatingPressure == false)
        #expect(manager.isUpdatingAbsoluteAltitude == false)

        motion.activityHandlers[0](nil)
        motion.relativeAltitudeHandlers[0](nil, nil)
        motion.absoluteAltitudeHandlers[0](nil, nil)

        #expect(
            Set(motion.calls.suffix(3))
                == ["stopActivityUpdates", "stopRelativeAltitudeUpdates", "stopAbsoluteAltitudeUpdates"])
    }

    @Test("A late warm-up sample does not stop a sensor that tracking started")
    func requestPermissionLateSampleKeepsTrackingUpdates() {
        let (manager, motion) = makeManager()

        manager.requestPermission()
        manager.startActivityUpdates { _ in }
        manager.startRelativeAltitude { _ in }
        manager.startAbsoluteAltitude { _ in }

        // The warm-up samples arrive after tracking started each sensor.
        motion.activityHandlers[0](nil)
        motion.relativeAltitudeHandlers[0](nil, nil)
        motion.absoluteAltitudeHandlers[0](nil, nil)

        #expect(!motion.calls.contains("stopActivityUpdates"))
        #expect(!motion.calls.contains("stopRelativeAltitudeUpdates"))
        #expect(!motion.calls.contains("stopAbsoluteAltitudeUpdates"))
        #expect(manager.isUpdatingActivity)
        #expect(manager.isUpdatingPressure)
        #expect(manager.isUpdatingAbsoluteAltitude)
    }

    @Test("requestPermission off the main thread starts the sensors before it returns")
    func requestPermissionOffMainStartsAtOnce() async {
        let (manager, motion) = makeManager()

        await Task.detached {
            manager.requestPermission()
        }.value

        #expect(motion.calls == ["startActivityUpdates", "startRelativeAltitudeUpdates", "startAbsoluteAltitudeUpdates"])
    }

    // MARK: - Threads

    @Test("Starts and stops from many threads keep each flag and its sensor together")
    func concurrentStartsAndStopsStayConsistent() {
        let (manager, motion) = makeManager()

        // `TrackingRadarMotion` is not thread-safe, so this also checks that the manager never
        // calls it from two threads at the same time.
        DispatchQueue.concurrentPerform(iterations: 1_000) { index in
            switch index % 6 {
            case 0: manager.startActivityUpdates { _ in }
            case 1: manager.stopActivityUpdates()
            case 2: manager.startRelativeAltitude { _ in }
            case 3: manager.stopRelativeAltitudeUpdates()
            case 4: manager.startAbsoluteAltitude { _ in }
            default: manager.stopAbsoluteAltitudeUpdates()
            }
        }

        // A sensor only starts again after a stop, so no start may follow its own start.
        for sensor in ["Activity", "RelativeAltitude", "AbsoluteAltitude"] {
            let calls = motion.calls.filter { $0.hasSuffix("\(sensor)Updates") }
            let doubleStart = zip(calls, calls.dropFirst()).contains { $0.hasPrefix("start") && $1.hasPrefix("start") }
            #expect(!doubleStart, "\(sensor) started twice without a stop")
            let running = calls.last?.hasPrefix("start") ?? false
            switch sensor {
            case "Activity": #expect(manager.isUpdatingActivity == running)
            case "RelativeAltitude": #expect(manager.isUpdatingPressure == running)
            default: #expect(manager.isUpdatingAbsoluteAltitude == running)
            }
        }
    }

    @Test("requestPermission does nothing while an update is running")
    @MainActor
    func requestPermissionSkipsWhileUpdating() {
        let (manager, motion) = makeManager()
        manager.startRelativeAltitude { _ in }

        manager.requestPermission()

        #expect(motion.calls == ["startRelativeAltitudeUpdates"])
    }

    // MARK: - startMotionUpdates

    @Test("startMotionUpdates keeps the shared activity manager on a host that has none")
    func startMotionUpdatesStoresSharedInstance() {
        let host = TrackingRadarLocationManagerHost()
        host.activityManager = nil
        // The test bundle does not link RadarSDKMotion, so the shared instance has no
        // `radarSDKMotion` and its start methods do nothing. Do not change the shared instance here:
        // other suites can run at the same time.
        let shared = RadarActivityManager.shared

        let options = RadarTrackingOptions.presetEfficient
        options.useMotion = true
        options.usePressure = false
        RadarLocationManagerSwift.startMotionUpdates(host: host, options: options)

        #expect(host.activityManager === shared)
    }

    @Test("startMotionUpdates leaves the host alone when motion and pressure are off")
    func startMotionUpdatesWithoutMotionLeavesHost() {
        let host = TrackingRadarLocationManagerHost()
        host.activityManager = nil

        let options = RadarTrackingOptions.presetEfficient
        options.useMotion = false
        options.usePressure = false
        RadarLocationManagerSwift.startMotionUpdates(host: host, options: options)

        #expect(host.activityManager == nil)
    }
}
