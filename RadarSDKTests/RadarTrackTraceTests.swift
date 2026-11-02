//
//  RadarTrackTraceTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import Testing

@testable import RadarSDK

extension RadarSerializedTests {
    /// Span trees for `trackOnce`. Root spans record into an isolated manager through `RadarTraceSpan.defaultManager`,
    /// which is shared state, so the suite is serialized with the other suites that change SDK singletons.
    @Suite(.serialized)
    @MainActor
    struct RadarTrackTraceTests {
        private let fixture = RadarSDKTestFixture()
        private let harness = TraceTestHarness()

        // MARK: - trackOnce

        @Test("trackOnce traces getting a location and the track request")
        func trackOnceSpanTree() async throws {
            useTrackResponse()

            let status = await traced { Radar.trackOnce(completionHandler: $0) }

            #expect(status == .success)
            let spans = try await uploadedSpans()
            #expect(Set(spans.keys) == ["radar.track_once", "radar.location.get", "POST /v1/track"])
            let root = try #require(spans["radar.track_once"])
            let rootId = try #require(root["spanId"] as? String)
            #expect(root["parentSpanId"] == nil)
            #expect(root["status"] == nil)
            #expect(TraceTestHarness.stringAttribute(root, "radar.location.desired_accuracy") == "medium")
            #expect(TraceTestHarness.boolAttribute(root, "radar.beacons") == false)
            // Called on the main thread, so the app state is recorded.
            #expect(TraceTestHarness.boolAttribute(root, "radar.app.foreground") != nil)
            #expect(TraceTestHarness.stringAttribute(root, "radar.location.accuracy_authorization") != nil)
            #expect(TraceTestHarness.attribute(root, "radar.track.replayed") == nil)

            let get = try #require(spans["radar.location.get"])
            #expect(get["parentSpanId"] as? String == rootId)
            #expect(TraceTestHarness.doubleAttribute(get, "radar.location.accuracy_m") == 65)

            let track = try #require(spans["POST /v1/track"])
            #expect(track["parentSpanId"] as? String == rootId)
            #expect(track["kind"] as? Int == RadarSpanKind.client.rawValue)
            #expect(track["status"] == nil)
            let trackSpanId = try #require(track["spanId"] as? String)
            let traceId = try #require(root["traceId"] as? String)
            #expect(fixture.apiHelperMock.lastHeaders?["traceparent"] as? String == "00-\(traceId)-\(trackSpanId)-01")
        }

        @Test("A trackOnce whose location fails ends the root with the location's status")
        func trackOnceLocationFailure() async throws {
            fixture.permissionsHelperMock.mockLocationAuthorizationStatus = .notDetermined
            fixture.locationManagerMock.mockLocation = nil

            let status = await traced { Radar.trackOnce(completionHandler: $0) }

            #expect(status == .errorPermissions)
            let spans = try await uploadedSpans()
            #expect(Set(spans.keys) == ["radar.track_once", "radar.location.get"])
            #expect(TraceTestHarness.errorType(spans["radar.track_once"]) == "ERROR_PERMISSIONS")
            #expect(TraceTestHarness.errorType(spans["radar.location.get"]) == "ERROR_PERMISSIONS")
        }

        @Test("A trackOnce with beacons traces the beacon search")
        func trackOnceWithBeaconsTracesSearch() async throws {
            // The track fixture has no beacons, so the search finds none and the track is sent without ranging.
            useTrackResponse()

            let status = await traced { Radar.trackOnce(desiredAccuracy: .high, beacons: true, completionHandler: $0) }

            #expect(status == .success)
            let spans = try await uploadedSpans()
            #expect(Set(spans.keys) == ["radar.track_once", "radar.location.get", "GET /v1/search/beacons", "POST /v1/track"])
            let root = spans["radar.track_once"]
            #expect(TraceTestHarness.stringAttribute(root, "radar.location.desired_accuracy") == "high")
            #expect(TraceTestHarness.boolAttribute(root, "radar.beacons") == true)
            #expect(TraceTestHarness.stringAttribute(root, "radar.beacon.source") == "search")
            #expect(spans["GET /v1/search/beacons"]?["kind"] as? Int == RadarSpanKind.client.rawValue)
            #expect(spans["GET /v1/search/beacons"]?["parentSpanId"] as? String == root?["spanId"] as? String)
        }

        @Test("trackOnce(location:) traces only the track request")
        func trackOnceWithLocationSpanTree() async throws {
            useTrackResponse()

            let status = await traced {
                Radar.trackOnce(location: RadarSDKTestResources.manhattanLocation(), completionHandler: $0)
            }

            #expect(status == .success)
            let spans = try await uploadedSpans()
            #expect(Set(spans.keys) == ["radar.track_once_with_location", "POST /v1/track"])
            let root = spans["radar.track_once_with_location"]
            #expect(TraceTestHarness.attribute(root, "radar.location.desired_accuracy") == nil)
            #expect(TraceTestHarness.stringAttribute(root, "radar.location.accuracy_authorization") != nil)
            #expect(spans["POST /v1/track"]?["parentSpanId"] as? String == root?["spanId"] as? String)
        }

        @Test("A track sent as a replay flush has a replay span and no track span")
        func replayBranch() async throws {
            useTrackResponse()
            let buffer = RadarReplayBuffer.sharedInstance
            let originalOptions = RadarSettings.trackingOptions
            let originalRemoteOptions = RadarSettings.remoteTrackingOptions
            defer {
                buffer.mutableReplayBuffer = []
                RadarSettings.trackingOptions = originalOptions
                RadarSettings.remoteTrackingOptions = originalRemoteOptions
            }
            let options = RadarTrackingOptions.presetResponsive
            options.replay = .all
            RadarSettings.trackingOptions = options
            RadarSettings.remoteTrackingOptions = nil
            buffer.writeNewReplayToBuffer(["latitude": 40.0, "longitude": -73.0])

            let status = await traced { Radar.trackOnce(completionHandler: $0) }

            #expect(status == .success)
            let spans = try await uploadedSpans()
            #expect(Set(spans.keys) == ["radar.track_once", "radar.location.get", "POST /v1/track/replay"])
            let root = spans["radar.track_once"]
            #expect(TraceTestHarness.boolAttribute(root, "radar.track.replayed") == true)
            let replay = spans["POST /v1/track/replay"]
            #expect(replay?["parentSpanId"] as? String == root?["spanId"] as? String)
            #expect(replay?["kind"] as? Int == RadarSpanKind.client.rawValue)
            // The buffered replay plus this track.
            #expect(TraceTestHarness.intAttribute(replay, "radar.replay.count") == 2)
        }

        @Test("Untraced calls send no traceparent")
        func untracedCallsSendNoTraceparent() async throws {
            useTrackResponse()
            harness.manager.overrideSampledForTesting(false)

            let status = await traced { Radar.trackOnce(completionHandler: $0) }

            #expect(status == .success)
            #expect(fixture.apiHelperMock.lastHeaders?["traceparent"] == nil)
            try await harness.manager.flushAndWaitForTesting()
            #expect(harness.session.requests.isEmpty)
        }

        // MARK: - Helpers

        /// Flushes the harness's manager, then returns every uploaded span by name.
        private func uploadedSpans() async throws -> [String: [String: Any]] {
            try await harness.manager.flushAndWaitForTesting()
            return harness.spansByName()
        }

        private func useTrackResponse() {
            fixture.permissionsHelperMock.mockLocationAuthorizationStatus = .authorizedWhenInUse
            fixture.locationManagerMock.mockLocation = RadarSDKTestResources.manhattanLocation()
            fixture.apiHelperMock.mockStatus = .success
            fixture.apiHelperMock.mockResponse = (try? RadarSDKTestResources.jsonDictionary(fromResource: "track")) ?? [:]
        }

        /// Runs `call` with root spans recording into the harness's manager, and returns the status its completion
        /// handler receives.
        private func traced(
            _ call: (@escaping (RadarStatus, CLLocation?, [RadarEvent]?, RadarUser?) -> Void) -> Void
        ) async -> RadarStatus {
            RadarTraceSpan.defaultManager = harness.manager
            defer { RadarTraceSpan.defaultManager = .shared }
            return await awaitCompletion { resume in
                call { status, _, _, _ in resume(status) }
            }
        }
    }
}
