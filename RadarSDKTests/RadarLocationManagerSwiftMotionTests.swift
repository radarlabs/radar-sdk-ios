//
//  RadarLocationManagerSwiftMotionTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import CoreMotion
import Foundation
import Testing

@testable import RadarSDK

/// A motion activity with fixed values, because Core Motion doesn't let tests create real ones.
final class StubMotionActivity: CMMotionActivity, @unchecked Sendable {
    private let stubStationary: Bool
    private let stubWalking: Bool
    private let stubRunning: Bool
    private let stubAutomotive: Bool
    private let stubCycling: Bool
    private let stubConfidence: CMMotionActivityConfidence
    private let stubStartDate: Date

    init(
        stationary: Bool = false,
        walking: Bool = false,
        running: Bool = false,
        automotive: Bool = false,
        cycling: Bool = false,
        confidence: CMMotionActivityConfidence = .high,
        startDate: Date = Date(timeIntervalSince1970: 1_700_000_000)
    ) {
        stubStationary = stationary
        stubWalking = walking
        stubRunning = running
        stubAutomotive = automotive
        stubCycling = cycling
        stubConfidence = confidence
        stubStartDate = startDate
        super.init()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override var stationary: Bool { stubStationary }
    override var walking: Bool { stubWalking }
    override var running: Bool { stubRunning }
    override var automotive: Bool { stubAutomotive }
    override var cycling: Bool { stubCycling }
    override var confidence: CMMotionActivityConfidence { stubConfidence }
    override var startDate: Date { stubStartDate }
    // Core Motion's description reads state a stub doesn't have, and Swift Testing prints values.
    override var description: String {
        "StubMotionActivity(stationary: \(stubStationary), walking: \(stubWalking), running: \(stubRunning), "
            + "automotive: \(stubAutomotive), cycling: \(stubCycling))"
    }
}

final class StubAltitudeData: CMAltitudeData, @unchecked Sendable {
    private let stubPressure: NSNumber
    private let stubRelativeAltitude: NSNumber

    init(pressure: Double, relativeAltitude: Double) {
        stubPressure = NSNumber(value: pressure)
        stubRelativeAltitude = NSNumber(value: relativeAltitude)
        super.init()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override var pressure: NSNumber { stubPressure }
    override var relativeAltitude: NSNumber { stubRelativeAltitude }
    override var description: String { "StubAltitudeData(pressure: \(stubPressure), relativeAltitude: \(stubRelativeAltitude))" }
}

final class StubAbsoluteAltitudeData: CMAbsoluteAltitudeData, @unchecked Sendable {
    private let stubAltitude: Double
    private let stubAccuracy: Double
    private let stubPrecision: Double

    init(altitude: Double, accuracy: Double, precision: Double) {
        stubAltitude = altitude
        stubAccuracy = accuracy
        stubPrecision = precision
        super.init()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override var altitude: Double { stubAltitude }
    override var accuracy: Double { stubAccuracy }
    override var precision: Double { stubPrecision }
    override var description: String {
        "StubAbsoluteAltitudeData(altitude: \(stubAltitude), accuracy: \(stubAccuracy), precision: \(stubPrecision))"
    }
}

extension RadarSerializedTests {
    @Suite(.serialized)
    struct RadarLocationManagerSwiftMotionTests {

        /// Clears the motion state and records the tracks a motion change starts.
        private func withMotionState(_ body: (_ trackOnceCount: () -> Int) throws -> Void) rethrows {
            let state = RadarState.shared
            let originalActivity = state.lastMotionActivityData
            let originalAuthorization = state.motionAuthorizationString
            let originalTrackOnce = RadarLocationManagerSwift.trackOnceAfterActivityChange
            state.lastMotionActivityData = nil
            state.lastRelativeAltitudeData = nil
            defer {
                state.lastMotionActivityData = originalActivity
                state.motionAuthorizationString = originalAuthorization
                state.lastRelativeAltitudeData = nil
                RadarLocationManagerSwift.trackOnceAfterActivityChange = originalTrackOnce
            }

            var trackOnceCount = 0
            RadarLocationManagerSwift.trackOnceAfterActivityChange = { trackOnceCount += 1 }

            try body { trackOnceCount }
        }

        private func options(_ configure: (RadarTrackingOptions) -> Void) -> RadarTrackingOptions {
            let options = RadarTrackingOptions.presetResponsive
            options.useMotion = false
            options.usePressure = false
            configure(options)
            return options
        }

        // MARK: - Activity

        @Test(
            "activityType maps Core Motion activities to Radar activity types",
            arguments: [
                ("stationary and automotive", RadarActivityType.stationary),
                ("walking", .foot),
                ("running", .foot),
                ("automotive and cycling", .car),
                ("cycling", .bike),
                ("none", .unknown),
            ])
        func activityTypeMapping(flags: String, expected: RadarActivityType) {
            let activity = StubMotionActivity(
                stationary: flags.contains("stationary"),
                walking: flags.contains("walking"),
                running: flags.contains("running"),
                automotive: flags.contains("automotive"),
                cycling: flags.contains("cycling")
            )

            #expect(RadarLocationManagerSwift.activityType(for: activity) == expected)
        }

        @Test("a new activity is stored and starts a track")
        func newActivityIsStoredAndTracked() throws {
            try withMotionState { trackOnceCount in
                let startDate = Date(timeIntervalSince1970: 1_700_000_123)
                let activity = StubMotionActivity(walking: true, confidence: .medium, startDate: startDate)

                RadarLocationManagerSwift.recordMotionActivity(activity, options: options { $0.syncLocations = .all })

                let stored = try #require(RadarState.shared.lastMotionActivityData)
                #expect(stored["type"] as? String == "foot")
                #expect((stored["timestamp"] as? NSNumber)?.doubleValue == startDate.timeIntervalSince1970)
                #expect((stored["confidence"] as? NSNumber)?.intValue == CMMotionActivityConfidence.medium.rawValue)
                #expect(trackOnceCount() == 1)
            }
        }

        @Test("an activity of the same type as the last one is skipped")
        func sameActivityTypeIsSkipped() {
            withMotionState { trackOnceCount in
                let options = options { $0.syncLocations = .all }
                RadarLocationManagerSwift.recordMotionActivity(StubMotionActivity(automotive: true), options: options)
                let firstTimestamp = RadarState.shared.lastMotionActivityData?["timestamp"] as? NSNumber

                RadarLocationManagerSwift.recordMotionActivity(
                    StubMotionActivity(automotive: true, startDate: Date(timeIntervalSince1970: 1_800_000_000)),
                    options: options)

                #expect(RadarState.shared.lastMotionActivityData?["timestamp"] as? NSNumber == firstTimestamp)
                #expect(trackOnceCount() == 1)
            }
        }

        @Test("an unknown activity is skipped")
        func unknownActivityIsSkipped() {
            withMotionState { trackOnceCount in
                RadarLocationManagerSwift.recordMotionActivity(StubMotionActivity(), options: options { _ in })

                #expect(RadarState.shared.lastMotionActivityData == nil)
                #expect(trackOnceCount() == 0)
            }
        }

        @Test("an activity is stored without a track when syncLocations is events")
        func activityWithEventsSyncDoesNotTrack() {
            withMotionState { trackOnceCount in
                RadarLocationManagerSwift.recordMotionActivity(
                    StubMotionActivity(cycling: true), options: options { $0.syncLocations = .events })

                #expect(RadarState.shared.lastMotionActivityData?["type"] as? String == "bike")
                #expect(trackOnceCount() == 0)
            }
        }

        // MARK: - Altitude

        @Test("relative altitude is stored with the pressure in hPa")
        func relativeAltitudeIsStored() {
            withMotionState { _ in
                RadarLocationManagerSwift.recordRelativeAltitude(StubAltitudeData(pressure: 101.3, relativeAltitude: 2.5))

                let stored = RadarState.shared.lastRelativeAltitudeData
                #expect((stored?["pressure"] as? NSNumber)?.doubleValue == 101.3 * 10)
                #expect((stored?["relativeAltitude"] as? NSNumber)?.doubleValue == 2.5)
                #expect(stored?["relativeAltitudeTimestamp"] != nil)
            }
        }

        @Test("absolute altitude is added to the stored relative altitude")
        func absoluteAltitudeIsMerged() {
            withMotionState { _ in
                RadarLocationManagerSwift.recordRelativeAltitude(StubAltitudeData(pressure: 100, relativeAltitude: 1))

                RadarLocationManagerSwift.recordAbsoluteAltitude(
                    StubAbsoluteAltitudeData(altitude: 120.5, accuracy: 3, precision: 0.5))

                let stored = RadarState.shared.lastRelativeAltitudeData
                #expect((stored?["pressure"] as? NSNumber)?.doubleValue == 1000)
                #expect((stored?["altitude"] as? NSNumber)?.doubleValue == 120.5)
                #expect((stored?["accuracy"] as? NSNumber)?.doubleValue == 3)
                #expect((stored?["precision"] as? NSNumber)?.doubleValue == 0.5)
                #expect(stored?["absoluteAltitudeTimestamp"] != nil)
            }
        }

        @Test("nil altitude data leaves the stored altitude unchanged")
        func nilAltitudeDataIsIgnored() {
            withMotionState { _ in
                RadarLocationManagerSwift.recordRelativeAltitude(nil)
                RadarLocationManagerSwift.recordAbsoluteAltitude(nil)

                #expect(RadarState.shared.lastRelativeAltitudeData == nil)
            }
        }

        // MARK: - startMotionUpdates

        @Test("useMotion starts heading and activity updates, and activity updates are recorded")
        func useMotionStartsActivityUpdates() throws {
            try RadarLocationManagerSwiftTestHelpers.withMockedSwiftTrackingDependencies { _ in
                try withMotionState { trackOnceCount in
                    let host = TrackingRadarLocationManagerHost()

                    RadarLocationManagerSwift.startMotionUpdates(host: host, options: options { $0.useMotion = true })

                    #expect(host.trackingLocationManager.headingFilter == 5)
                    #expect(host.trackingLocationManager.startUpdatingHeadingCallCount == 1)
                    #expect(host.relativeAltitudeHandlers.isEmpty)
                    #expect(host.absoluteAltitudeHandlers.isEmpty)

                    let handler = try #require(host.activityHandlers.first)
                    handler(StubMotionActivity(stationary: true))

                    #expect(RadarState.shared.lastMotionActivityData?["type"] as? String == "stationary")
                    #expect(trackOnceCount() == 1)
                }
            }
        }

        @Test("usePressure stores the motion authorization and records altitude updates")
        func usePressureStartsAltitudeUpdates() throws {
            try RadarLocationManagerSwiftTestHelpers.withMockedSwiftTrackingDependencies { bridge in
                try withMotionState { _ in
                    bridge.mockMotionAuthorizationString = "AUTHORIZED"
                    let host = TrackingRadarLocationManagerHost()

                    RadarLocationManagerSwift.startMotionUpdates(host: host, options: options { $0.usePressure = true })

                    #expect(RadarState.shared.motionAuthorizationString == "AUTHORIZED")
                    #expect(host.activityHandlers.isEmpty)
                    #expect(host.trackingLocationManager.startUpdatingHeadingCallCount == 0)

                    let relativeHandler = try #require(host.relativeAltitudeHandlers.first)
                    let absoluteHandler = try #require(host.absoluteAltitudeHandlers.first)
                    relativeHandler(StubAltitudeData(pressure: 99, relativeAltitude: 0))
                    absoluteHandler(StubAbsoluteAltitudeData(altitude: 10, accuracy: 1, precision: 1))

                    let stored = RadarState.shared.lastRelativeAltitudeData
                    #expect((stored?["pressure"] as? NSNumber)?.doubleValue == 990)
                    #expect((stored?["altitude"] as? NSNumber)?.doubleValue == 10)
                }
            }
        }
    }
}
