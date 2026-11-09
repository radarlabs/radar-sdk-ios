//
//  RadarTrackVerifiedTraceTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import XCTest

@testable import RadarSDK

private final class TraceLocationManagerMock: RadarLocationManager {
    override func getLocationWith(
        _ desiredAccuracy: RadarTrackingOptionsDesiredAccuracy,
        completionHandler: RadarLocationCompletionHandler?
    ) {
        completionHandler?(.success, CLLocation(latitude: 40.0, longitude: -73.0), false)
    }
}

/// Answers config requests to the primary verified host without a Radar response, so trackVerified fails over.
private final class FailoverAPIHelperMock: RadarAPIHelperMock {
    override func request(
        withMethod method: String,
        url: String,
        headers: [AnyHashable: Any]?,
        params: [AnyHashable: Any]?,
        sleep: Bool,
        logPayload: Bool,
        extendedTimeout: Bool,
        completionHandler: RadarAPICompletionHandler?
    ) {
        let primary = url.hasPrefix("\(RadarSettings.verifiedHost)/v1/config")
        let status: RadarStatus = primary ? .errorServer : .errorUnauthorized
        completionHandler?(status, [:], nil)
    }
}

/// Span trees for `trackVerified`. XCTest, since the cases swap the shared API client's helper and
/// `RadarTraceSpan.defaultManager`.
final class RadarTrackVerifiedTraceTests: XCTestCase {
    private var harness: TraceTestHarness!
    private var restoreState: (() -> Void)?

    override func setUp() {
        super.setUp()
        harness = TraceTestHarness()
        let client = RadarAPIClient.sharedInstance()
        let originalHelper = client.apiHelper
        let originalKey = RadarSettings.publishableKey
        let originalAnonymous = RadarSettings.anonymousTrackingEnabled
        restoreState = {
            client.apiHelper = originalHelper
            RadarSettings.publishableKey = originalKey
            RadarSettings.anonymousTrackingEnabled = originalAnonymous
            RadarTraceSpan.defaultManager = .shared
        }
        RadarSettings.publishableKey = "prj_test_pk_radar_sdk_ios"
        RadarSettings.anonymousTrackingEnabled = false
        RadarTraceSpan.defaultManager = harness.manager
    }

    override func tearDown() {
        restoreState?()
        restoreState = nil
        harness = nil
        super.tearDown()
    }

    @MainActor
    func test_trackVerified_tracesEachStep() async throws {
        let helper = MainQueueAPIHelperMock()
        helper.mockStatus = .success
        helper.mockResponse = ["meta": ["config": [:]], "nonce": "trace-test-nonce"]
        let trackURL = "\(RadarSettings.verifiedHost)/v1/track"
        helper.setMockStatus(.errorServer, forMethod: trackURL)
        RadarAPIClient.sharedInstance().apiHelper = helper
        let manager = try makeVerificationManager(result: ["payload": MockFraudEnvelope.payload])

        let status = await trackVerified(manager)

        XCTAssertEqual(status, .errorServer)
        try await harness.manager.flushAndWaitForTesting()
        let spans = harness.spansByName()
        XCTAssertEqual(
            Set(spans.keys), ["radar.track_verified", "GET /v1/config", "radar.location.get", "radar.fraud.prepare", "POST /v1/track"])
        let root = try XCTUnwrap(spans["radar.track_verified"])
        let rootId = try XCTUnwrap(root["spanId"] as? String)
        for name in ["GET /v1/config", "radar.location.get", "radar.fraud.prepare", "POST /v1/track"] {
            XCTAssertEqual(spans[name]?["parentSpanId"] as? String, rootId, name)
        }
        XCTAssertEqual(TraceTestHarness.errorType(root), "ERROR_SERVER")
        XCTAssertEqual(TraceTestHarness.stringAttribute(root, "radar.location.desired_accuracy"), "medium")
        XCTAssertEqual(TraceTestHarness.boolAttribute(root, "radar.beacons"), false)
        XCTAssertEqual(TraceTestHarness.boolAttribute(root, "radar.verified.failover"), false)
        XCTAssertNotNil(TraceTestHarness.boolAttribute(root, "radar.app.foreground"))
        XCTAssertNil(spans["radar.fraud.prepare"]?["status"])
        XCTAssertEqual(TraceTestHarness.errorType(spans["POST /v1/track"]), "ERROR_SERVER")

        // The verified track keeps traceparent as a plain header next to the sealed body.
        let trackSpanId = try XCTUnwrap(spans["POST /v1/track"]?["spanId"] as? String)
        let traceId = try XCTUnwrap(root["traceId"] as? String)
        XCTAssertEqual(helper.lastUrl, trackURL)
        XCTAssertEqual(helper.lastHeaders?["traceparent"] as? String, "00-\(traceId)-\(trackSpanId)-01")
    }

    @MainActor
    func test_trackVerified_failoverTracesBothConfigRequests() async throws {
        RadarAPIClient.sharedInstance().apiHelper = FailoverAPIHelperMock()
        let manager = try makeVerificationManager(result: ["payload": MockFraudEnvelope.payload])

        let status = await trackVerified(manager)

        XCTAssertEqual(status, .errorUnauthorized)
        try await harness.manager.flushAndWaitForTesting()
        let spans = harness.allSpans()
        let configs = spans.filter { $0["name"] as? String == "GET /v1/config" }
        XCTAssertEqual(configs.map(TraceTestHarness.errorType), ["ERROR_SERVER", "ERROR_UNAUTHORIZED"])
        let root = try XCTUnwrap(spans.first { $0["name"] as? String == "radar.track_verified" })
        XCTAssertEqual(TraceTestHarness.boolAttribute(root, "radar.verified.failover"), true)
        XCTAssertEqual(TraceTestHarness.errorType(root), "ERROR_UNAUTHORIZED")
        XCTAssertEqual(spans.count, 3)
    }

    @MainActor
    func test_trackVerified_sealingFailureEndsTheTrackSpan() async throws {
        let helper = MainQueueAPIHelperMock()
        helper.mockStatus = .success
        helper.mockResponse = ["meta": ["config": [:]]]
        RadarAPIClient.sharedInstance().apiHelper = helper
        // Collection succeeds, and sealing the request body fails.
        let manager = try makeVerificationManager(result: ["error": "encryption failed"])

        let status = await trackVerified(manager)

        XCTAssertEqual(status, .errorBadRequest)
        try await harness.manager.flushAndWaitForTesting()
        let spans = harness.spansByName()
        XCTAssertNil(TraceTestHarness.errorType(spans["radar.fraud.prepare"]))
        XCTAssertEqual(TraceTestHarness.errorType(spans["POST /v1/track"]), "ERROR_BAD_REQUEST")
        XCTAssertEqual(TraceTestHarness.errorType(spans["radar.track_verified"]), "ERROR_BAD_REQUEST")
    }

    @MainActor
    func test_trackVerified_fraudPreparationFailureEndsTheRoot() async throws {
        let helper = MainQueueAPIHelperMock()
        helper.mockStatus = .success
        helper.mockResponse = ["meta": ["config": [:]]]
        RadarAPIClient.sharedInstance().apiHelper = helper
        let manager = try makeVerificationManager(result: nil, fraudSDKAvailable: false)

        let status = await trackVerified(manager)

        XCTAssertEqual(status, .errorPlugin)
        try await harness.manager.flushAndWaitForTesting()
        let spans = harness.spansByName()
        XCTAssertEqual(Set(spans.keys), ["radar.track_verified", "GET /v1/config", "radar.location.get", "radar.fraud.prepare"])
        XCTAssertEqual(TraceTestHarness.errorType(spans["radar.fraud.prepare"]), "ERROR_PLUGIN")
        XCTAssertEqual(TraceTestHarness.errorType(spans["radar.track_verified"]), "ERROR_PLUGIN")
    }

    // MARK: - Helpers

    /// `fraudSDKAvailable: false` makes payload preparation fail as it does without a compatible fraud SDK.
    private func makeVerificationManager(
        result: [String: Any]?, fraudSDKAvailable: Bool = true
    ) throws -> ObjCVerificationManager {
        let fraudSDK = fraudSDKAvailable ? try XCTUnwrap(RadarSDKFraud(instance: makeCollectedFraudInstance(result: result))) : nil
        let manager = try XCTUnwrap(ObjCVerificationManager.makeFresh())
        manager.instance.setValue(TraceLocationManagerMock(), forKey: "trackVerifiedLocationManager")
        let factory: @convention(block) ([String: Any]) -> NSObject = { options in
            RadarTrackVerifiedRequestPreparer(fraudSDK: fraudSDK, options: options)
        }
        manager.instance.setValue(factory as AnyObject, forKey: "trackVerifiedPayloadFactory")
        return manager
    }

    @MainActor
    private func trackVerified(_ manager: ObjCVerificationManager) async -> RadarStatus {
        await withCheckedContinuation { continuation in
            let completion: @convention(block) (RadarStatus, RadarVerifiedLocationToken?) -> Void = { status, _ in
                continuation.resume(returning: status)
            }
            manager.instance.perform(NSSelectorFromString("trackVerifiedWithCompletionHandler:"), with: completion as AnyObject)
        }
    }
}
