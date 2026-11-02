//
//  RadarTrackingUpdateTraceTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import Testing

@testable import RadarSDK

extension RadarSerializedTests {
    /// Traces of tracking updates sent by `RadarLocationManager.sendLocation`. Root spans record into an isolated
    /// manager through `RadarTraceSpan.defaultManager`.
    @Suite(.serialized)
    @MainActor
    struct RadarTrackingUpdateTraceTests {
        private let fixture = RadarSDKTestFixture()
        private let harness = TraceTestHarness()

        @Test("A tracking update traces its track request")
        func trackingUpdateSpanTree() async throws {
            try useTrackResponse()
            let location = RadarSDKTestResources.manhattanLocation()

            let spans = try await sendLocation(location, source: .backgroundLocation, stopped: true)

            #expect(Set(spans.keys) == ["radar.tracking_update", "POST /v1/track"])
            let root = try #require(spans["radar.tracking_update"])
            #expect(root["status"] == nil)
            #expect(TraceTestHarness.stringAttribute(root, "radar.location.source") == "background_location")
            #expect(TraceTestHarness.boolAttribute(root, "radar.track.stopped") == true)
            #expect(TraceTestHarness.boolAttribute(root, "radar.beacons") == false)
            #expect(TraceTestHarness.doubleAttribute(root, "radar.location.accuracy_m") == 65)
            #expect(TraceTestHarness.intAttribute(root, "radar.location.age_ms") != nil)
            #expect(TraceTestHarness.boolAttribute(root, "radar.app.foreground") != nil)
            #expect(TraceTestHarness.attribute(root, "radar.track.batched") == nil)
            #expect(spans["POST /v1/track"]?["parentSpanId"] as? String == root["spanId"] as? String)
        }

        @Test("A failed tracking update ends the root with the track's status")
        func trackingUpdateFailure() async throws {
            fixture.apiHelperMock.mockStatus = .errorServer
            fixture.apiHelperMock.mockResponse = [:]

            let spans = try await sendLocation(RadarSDKTestResources.manhattanLocation(), source: .geofenceExit, stopped: false)

            #expect(TraceTestHarness.errorType(spans["radar.tracking_update"]) == "ERROR_SERVER")
            #expect(TraceTestHarness.stringAttribute(spans["radar.tracking_update"], "radar.location.source") == "geofence_exit")
            #expect(TraceTestHarness.errorType(spans["POST /v1/track"]) == "ERROR_SERVER")
        }

        @Test("A batched tracking update is marked, and has no request span")
        func batchedTrackingUpdate() async throws {
            try useTrackResponse()
            let buffer = RadarReplayBuffer.sharedInstance
            let originalOptions = RadarSettings.trackingOptions
            let originalRemoteOptions = RadarSettings.remoteTrackingOptions
            defer {
                buffer.cancelBatchTimer()
                buffer.clearBuffer()
                RadarSettings.trackingOptions = originalOptions
                RadarSettings.remoteTrackingOptions = originalRemoteOptions
            }
            let options = RadarTrackingOptions.presetResponsive
            options.batchSize = 10
            RadarSettings.trackingOptions = options
            RadarSettings.remoteTrackingOptions = nil

            let spans = try await sendLocation(RadarSDKTestResources.manhattanLocation(), source: .backgroundLocation, stopped: false)

            #expect(Set(spans.keys) == ["radar.tracking_update"])
            #expect(TraceTestHarness.boolAttribute(spans["radar.tracking_update"], "radar.track.batched") == true)
            #expect(spans["radar.tracking_update"]?["status"] == nil)
        }

        // MARK: - Helpers

        private func useTrackResponse() throws {
            fixture.apiHelperMock.mockStatus = .success
            fixture.apiHelperMock.mockResponse = try RadarSDKTestResources.jsonDictionary(fromResource: "track")
        }

        /// Sends a tracking update with root spans recording into the harness's manager, and returns the uploaded
        /// spans by name once its root has been recorded.
        private func sendLocation(
            _ location: CLLocation, source: RadarLocationSource, stopped: Bool
        ) async throws -> [String: [String: Any]] {
            let host = try #require(RadarLocationManager.sharedInstance() as? RadarLocationManagerSwiftHost)
            RadarTraceSpan.defaultManager = harness.manager
            defer { RadarTraceSpan.defaultManager = .shared }

            host.sendLocation(location, stopped: stopped, source: source, replayed: false, beacons: nil, forceTrack: true)

            // The update has no completion handler, so wait for its root to be uploaded.
            for _ in 0..<200 {
                try await harness.manager.flushAndWaitForTesting()
                let spans = harness.spansByName()
                if spans["radar.tracking_update"] != nil {
                    return spans
                }
                try await Task.sleep(nanoseconds: 10_000_000)
            }
            Issue.record("The tracking update's root span was never recorded")
            return [:]
        }
    }
}
