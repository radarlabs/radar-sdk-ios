//
//  RadarTraceInstrumentationTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import Testing

@testable import RadarSDK

extension TraceTestHarness {
    /// Flushes, then returns every uploaded span by name.
    func uploadedSpans() async throws -> [String: [String: Any]] {
        try await manager.flushAndWaitForTesting()
        return spansByName()
    }

    /// Every span uploaded so far, by name. For a name that repeats, the first one.
    func spansByName() -> [String: [String: Any]] {
        Dictionary(allSpans().map { ($0["name"] as? String ?? "", $0) }, uniquingKeysWith: { first, _ in first })
    }

    /// Every span uploaded so far, in upload order.
    func allSpans() -> [[String: Any]] {
        session.payloads.flatMap { payload in
            Self.scopeSpans(payload)?["spans"] as? [[String: Any]] ?? []
        }
    }

    /// An uploaded span's attribute value, such as `["stringValue": "high"]`.
    static func attribute(_ span: [String: Any]?, _ key: String) -> [String: Any]? {
        let attributes = span?["attributes"] as? [[String: Any]] ?? []
        return attributes.first { $0["key"] as? String == key }?["value"] as? [String: Any]
    }

    static func stringAttribute(_ span: [String: Any]?, _ key: String) -> String? {
        attribute(span, key)?["stringValue"] as? String
    }

    static func boolAttribute(_ span: [String: Any]?, _ key: String) -> Bool? {
        attribute(span, key)?["boolValue"] as? Bool
    }

    /// OTLP encodes integers as decimal strings.
    static func intAttribute(_ span: [String: Any]?, _ key: String) -> Int64? {
        (attribute(span, key)?["intValue"] as? String).flatMap { Int64($0) }
    }

    static func doubleAttribute(_ span: [String: Any]?, _ key: String) -> Double? {
        attribute(span, key)?["doubleValue"] as? Double
    }

    /// The `error.type` of a span that ended with a non-success status.
    static func errorType(_ span: [String: Any]?) -> String? {
        stringAttribute(span, "error.type")
    }
}

@Suite("RadarTraceSpan instrumentation")
final class RadarTraceInstrumentationTests {
    private let harness = TraceTestHarness()
    private var manager: RadarTraceManager { harness.manager }

    // MARK: - Track

    @Test("recordTrack sets the root attributes, and omits the app state when it's unknown")
    func recordTrackSetsRootAttributes() async throws {
        let withState = RadarTraceSpan.start("with-state", manager: manager)
        withState.recordTrack(desiredAccuracy: .high, beacons: true, foreground: NSNumber(value: false))
        withState.end(status: .success)
        let withoutState = RadarTraceSpan.start("without-state", manager: manager)
        withoutState.recordTrack(desiredAccuracy: .low, beacons: false, foreground: nil)
        withoutState.end(status: .success)

        let spans = try await harness.uploadedSpans()
        let first = spans["with-state"]
        #expect(TraceTestHarness.stringAttribute(first, "radar.location.desired_accuracy") == "high")
        #expect(TraceTestHarness.boolAttribute(first, "radar.beacons") == true)
        #expect(TraceTestHarness.boolAttribute(first, "radar.app.foreground") == false)
        #expect(TraceTestHarness.stringAttribute(first, "radar.location.accuracy_authorization") == RadarUtils.locationAccuracyAuthorization)
        let second = spans["without-state"]
        #expect(TraceTestHarness.stringAttribute(second, "radar.location.desired_accuracy") == "low")
        #expect(TraceTestHarness.boolAttribute(second, "radar.beacons") == false)
        #expect(TraceTestHarness.attribute(second, "radar.app.foreground") == nil)
    }

    @Test("endingTrackHandler ends the root with the track's status, then calls the handler")
    func endingTrackHandlerEndsTheRoot() async throws {
        let root = RadarTraceSpan.start("root", manager: manager)
        var calls: [RadarStatus] = []
        let handler = try #require(root.endingTrackHandler { status, _, _, _ in calls.append(status) })

        handler(.errorNetwork, nil, nil, nil)

        #expect(calls == [.errorNetwork])
        let json = try await harness.uploadedSpans()["root"]
        #expect(TraceTestHarness.errorType(json) == "ERROR_NETWORK")
    }

    @Test("Handler wrappers return the handler unchanged for the no-op span")
    func wrappersPassThroughForNoopSpan() {
        manager.overrideSampledForTesting(false)
        let noop = RadarTraceSpan.start("root", manager: manager)

        #expect(noop.endingTrackHandler(nil) == nil)
        #expect(noop.endingTrackVerifiedHandler(nil) == nil)
        var called = false
        noop.tracingLocationHandler { _, _, _ in called = true }(.success, nil, false)
        #expect(called)
    }

    @Test("markReplayed sets radar.track.replayed")
    func markReplayed() async throws {
        let root = RadarTraceSpan.start("root", manager: manager)
        root.markReplayed()
        root.end(status: .success)

        #expect(TraceTestHarness.boolAttribute(try await harness.uploadedSpans()["root"], "radar.track.replayed") == true)
    }

    // MARK: - Location

    @Test("tracingLocationHandler records radar.location.get with the location's age and accuracy")
    func locationHandlerRecordsLocationGet() async throws {
        let root = RadarTraceSpan.start("root", manager: manager)
        var received: CLLocation?
        let handler = root.tracingLocationHandler { _, location, _ in received = location }
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 2), altitude: 0, horizontalAccuracy: 12.5,
            verticalAccuracy: -1, timestamp: Date(timeIntervalSinceNow: -5))

        handler(.success, location, false)
        root.end(status: .success)

        #expect(received === location)
        let spans = try await harness.uploadedSpans()
        let get = try #require(spans["radar.location.get"])
        #expect(get["parentSpanId"] as? String == root.spanId)
        #expect(get["kind"] as? Int == RadarSpanKind.internal.rawValue)
        let ageMs = try #require(TraceTestHarness.intAttribute(get, "radar.location.age_ms"))
        #expect((5_000..<10_000).contains(ageMs))
        #expect(TraceTestHarness.doubleAttribute(get, "radar.location.accuracy_m") == 12.5)
        #expect(get["status"] == nil)
    }

    @Test("A failed location ends radar.location.get with the error and no location attributes")
    func locationHandlerRecordsFailure() async throws {
        let root = RadarTraceSpan.start("root", manager: manager)

        root.tracingLocationHandler { _, _, _ in }(.errorLocation, nil, false)
        root.end(status: .errorLocation)

        let get = try await harness.uploadedSpans()["radar.location.get"]
        #expect(TraceTestHarness.errorType(get) == "ERROR_LOCATION")
        #expect(TraceTestHarness.attribute(get, "radar.location.age_ms") == nil)
    }

    // MARK: - Beacons

    @Test("tracingBeaconHandler records radar.beacon.range with the mode and ranged count")
    func beaconHandlerRecordsRange() async throws {
        let root = RadarTraceSpan.start("root", manager: manager)
        root.setBeaconSource("search")

        // Ranging that finds nothing records a count of 0.
        root.tracingBeaconHandler({ _, _ in }, mode: "uuids")(.success, [])
        root.tracingBeaconHandler({ _, _ in }, mode: "beacons")(.errorBluetooth, nil)
        root.end(status: .success)

        let spans = try await harness.uploadedSpans()
        #expect(TraceTestHarness.stringAttribute(spans["root"], "radar.beacon.source") == "search")
        let ranges = harness.allSpans()
            .filter { $0["name"] as? String == "radar.beacon.range" }
        let byMode = Dictionary(uniqueKeysWithValues: ranges.map { (TraceTestHarness.stringAttribute($0, "radar.beacon.mode") ?? "", $0) })
        #expect(TraceTestHarness.intAttribute(byMode["uuids"], "radar.beacon.ranged_count") == 0)
        #expect(TraceTestHarness.attribute(byMode["beacons"], "radar.beacon.ranged_count") == nil)
        #expect(TraceTestHarness.errorType(byMode["beacons"]) == "ERROR_BLUETOOTH")
    }

    // MARK: - Verification

    @Test("radar.fraud.prepare ends with the status trackVerified reports")
    func fraudPrepareStatus() async throws {
        let root = RadarTraceSpan.start("root", manager: manager)
        root.setVerifiedFailover(true)

        // A success without a payload fails trackVerified with ERROR_UNKNOWN.
        root.tracingFraudPrepareHandler { _, _, _ in }(.success, nil, nil)
        root.end(status: .success)

        let spans = try await harness.uploadedSpans()
        #expect(TraceTestHarness.boolAttribute(spans["root"], "radar.verified.failover") == true)
        #expect(spans["radar.fraud.prepare"]?["parentSpanId"] as? String == root.spanId)
        #expect(TraceTestHarness.errorType(spans["radar.fraud.prepare"]) == "ERROR_UNKNOWN")
    }

    @Test("radar.fraud.prepare keeps an error status from the fraud SDK")
    func fraudPrepareKeepsErrorStatus() async throws {
        let root = RadarTraceSpan.start("root", manager: manager)

        root.tracingFraudPrepareHandler { _, _, _ in }(.errorPlugin, nil, nil)
        root.end(status: .errorPlugin)

        #expect(TraceTestHarness.errorType(try await harness.uploadedSpans()["radar.fraud.prepare"]) == "ERROR_PLUGIN")
    }

    // MARK: - HTTP

    @Test("requestStarted records the host, connection type, and queue time")
    func requestStartedRecordsHTTPAttributes() async throws {
        let root = RadarTraceSpan.start("root", manager: manager)
        let client = root.child("GET /v1/config", kind: .client)

        client.requestStarted(
            url: "https://api.radar.io/v1/config?installId=abc", headers: ["X-Radar-Network-Type": "cellular-lte"],
            queueNanos: 1_500_000_000)
        client.setResendCount(1)
        client.end(status: .success)
        root.end(status: .success)

        let json = try await harness.uploadedSpans()["GET /v1/config"]
        #expect(TraceTestHarness.stringAttribute(json, "server.address") == "api.radar.io")
        #expect(TraceTestHarness.stringAttribute(json, "network.connection.type") == "cell")
        #expect(TraceTestHarness.intAttribute(json, "radar.http.queue_ms") == 1_500)
        #expect(TraceTestHarness.intAttribute(json, "http.request.resend_count") == 1)
    }

    @Test(
        "network.connection.type maps the SDK's network type header",
        arguments: [
            ("wifi", "wifi"), ("cellular", "cell"), ("cellular-5g", "cell"), ("unknown", "unknown"), (nil, "unknown"),
        ] as [(String?, String)])
    func connectionType(header: String?, expected: String) {
        #expect(RadarTraceSpan.connectionType(header) == expected)
    }

    @Test(
        "radar.network.error_kind maps URL errors",
        arguments: [
            (NSURLErrorCannotFindHost, "dns_failure"), (NSURLErrorDNSLookupFailed, "dns_failure"),
            (NSURLErrorTimedOut, "timeout"), (NSURLErrorCannotConnectToHost, "connect_refused"),
            (NSURLErrorSecureConnectionFailed, "ssl_failure"), (NSURLErrorServerCertificateUntrusted, "ssl_failure"),
            (NSURLErrorClientCertificateRequired, "ssl_failure"), (NSURLErrorNotConnectedToInternet, "other"),
        ])
    func networkErrorKind(code: Int, expected: String) {
        #expect(RadarTraceSpan.networkErrorKind(NSError(domain: NSURLErrorDomain, code: code)) == expected)
    }

    @Test("A network error ends the client span with ERROR_NETWORK and its kind")
    func networkErrorEndsSpan() async throws {
        let root = RadarTraceSpan.start("root", manager: manager)
        let client = root.child("POST /v1/track", kind: .client)

        client.end(networkError: NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut))
        root.end(status: .errorNetwork)

        let json = try await harness.uploadedSpans()["POST /v1/track"]
        #expect(TraceTestHarness.errorType(json) == "ERROR_NETWORK")
        #expect(TraceTestHarness.stringAttribute(json, "radar.network.error_kind") == "timeout")
        #expect(RadarTraceSpan.networkErrorKind(NSError(domain: "other", code: NSURLErrorTimedOut)) == "other")
    }

    @Test("Objective-C can reach the instrumentation API")
    func objectiveCSurface() {
        let selectors = [
            "recordTrackWithDesiredAccuracy:beacons:foreground:", "recordAppContextWithForeground:", "markReplayed",
            "endingTrackHandler:", "tracingLocationHandler:", "recordLocationQuality:", "setBeaconSource:",
            "tracingBeaconHandler:mode:", "setVerifiedFailover:", "endingTrackVerifiedHandler:",
            "tracingFraudPrepareHandler:", "requestStartedWithURL:headers:queueNanos:", "setResendCount:",
            "endWithNetworkError:",
        ]
        for selector in selectors {
            #expect(RadarTraceSpan.instancesRespond(to: NSSelectorFromString(selector)), "\(selector)")
        }
    }
}
