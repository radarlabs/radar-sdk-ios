//
//  RadarVerifiedHostFailoverTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing
@testable import RadarSDK

@Suite(.serialized)
struct RadarVerifiedHostSelectorTests {

    @Test func startsOnPrimary() {
        let selector = RadarVerifiedHostSelector()
        let (host, isProbe) = selector.hostForNextRequest()
        #expect(host == .primary)
        #expect(isProbe == false)
    }

    @Test func primarySuccessStaysOnPrimary() {
        let selector = RadarVerifiedHostSelector()
        selector.recordRadarResponse(on: .primary)
        #expect(selector.hostForNextRequest().host == .primary)
    }

    @Test func primaryNonRadarFailureMovesToSecondary() {
        var now = Date(timeIntervalSince1970: 1_000_000)
        let selector = RadarVerifiedHostSelector(now: { now })

        selector.recordNonRadarFailure(on: .primary)

        let (host, isProbe) = selector.hostForNextRequest()
        #expect(host == .secondary)
        #expect(isProbe == false)

        // Advance time, but still inside the 60s probe window.
        now = now.addingTimeInterval(59)
        #expect(selector.hostForNextRequest().host == .secondary)

        // Cross the probe boundary.
        now = now.addingTimeInterval(2)
        let probe = selector.hostForNextRequest()
        #expect(probe.host == .primary)
        #expect(probe.isProbe == true)
    }

    @Test func probeSuccessReturnsToPrimary() {
        var now = Date(timeIntervalSince1970: 2_000_000)
        let selector = RadarVerifiedHostSelector(now: { now })
        selector.recordNonRadarFailure(on: .primary)
        now = now.addingTimeInterval(RadarVerifiedHostSelector.probeInterval + 1)

        // Probe primary and have it succeed.
        _ = selector.hostForNextRequest()
        selector.recordRadarResponse(on: .primary)

        // Should now stick with primary indefinitely.
        now = now.addingTimeInterval(10_000)
        #expect(selector.hostForNextRequest().host == .primary)
    }

    @Test func probeFailureReArmsTimer() {
        var now = Date(timeIntervalSince1970: 3_000_000)
        let selector = RadarVerifiedHostSelector(now: { now })

        selector.recordNonRadarFailure(on: .primary)
        now = now.addingTimeInterval(RadarVerifiedHostSelector.probeInterval + 1)

        // Probe primary and have it fail again.
        _ = selector.hostForNextRequest()
        selector.recordNonRadarFailure(on: .primary)

        // Immediately after, we're still in a fresh 60s window on secondary.
        let (host, _) = selector.hostForNextRequest()
        #expect(host == .secondary)

        now = now.addingTimeInterval(59)
        #expect(selector.hostForNextRequest().host == .secondary)

        now = now.addingTimeInterval(2)
        #expect(selector.hostForNextRequest().host == .primary)
    }

    @Test func secondaryFailureClearsTimerSoPrimaryIsProbedNext() {
        let now = Date(timeIntervalSince1970: 4_000_000)
        let selector = RadarVerifiedHostSelector(now: { now })

        selector.recordNonRadarFailure(on: .primary)
        #expect(selector.hostForNextRequest().host == .secondary)

        // Secondary also fails — should reset the probe window so the next
        // call immediately tries primary again.
        selector.recordNonRadarFailure(on: .secondary)

        let (host, isProbe) = selector.hostForNextRequest()
        #expect(host == .primary)
        #expect(isProbe == true)
    }

    @Test func resetReturnsToInitialState() {
        let selector = RadarVerifiedHostSelector()
        selector.recordNonRadarFailure(on: .primary)
        selector.reset()
        let (host, isProbe) = selector.hostForNextRequest()
        #expect(host == .primary)
        #expect(isProbe == false)
    }
}

@Suite(.serialized)
final class RadarVerifiedAPICoordinatorTests {

    private let primaryPath = "/v1/track"

    init() {
        Radar.initialize(publishableKey: "prj_test_pk_0000000000000000")
    }

    // MARK: - Helpers

    private func radarResponse() -> [AnyHashable: Any] {
        ["meta": ["code": 200], "user": ["_id": "u"]]
    }

    private func nonRadarResponse() -> [AnyHashable: Any] {
        ["error": "cloudflare"]
    }

    private final class Recorder {
        var urls: [String] = []
    }

    private func runRequest(
        coordinator: RadarVerifiedAPICoordinator,
        path: String,
        respond: @escaping (Int, String) -> (RadarStatus, [AnyHashable: Any]?)
    ) -> (status: RadarStatus, res: [AnyHashable: Any]?, urls: [String]) {
        let recorder = Recorder()
        var finalStatus: RadarStatus = .errorUnknown
        var finalRes: [AnyHashable: Any]?

        coordinator.request(
            path: path,
            performRequest: { url, completion in
                recorder.urls.append(url)
                let (status, body) = respond(recorder.urls.count, url)
                completion(status, body)
            },
            completionHandler: { status, res in
                finalStatus = status
                finalRes = res
            }
        )

        return (finalStatus, finalRes, recorder.urls)
    }

    // MARK: - Tests

    @Test func primarySuccessDoesNotFailover() {
        let selector = RadarVerifiedHostSelector()
        let coordinator = RadarVerifiedAPICoordinator(selector: selector)

        let result = runRequest(coordinator: coordinator, path: primaryPath) { _, _ in
            (.success, self.radarResponse())
        }

        #expect(result.status == .success)
        #expect(result.urls.count == 1)
        #expect(result.urls[0].contains(RadarSettings.verifiedHost))
        #expect(selector.hostForNextRequest().host == .primary)
    }

    @Test func transportErrorOnPrimaryFallsOverToSecondary() {
        let selector = RadarVerifiedHostSelector()
        let coordinator = RadarVerifiedAPICoordinator(selector: selector)

        let result = runRequest(coordinator: coordinator, path: primaryPath) { attempt, _ in
            if attempt == 1 {
                return (.errorNetwork, nil)
            }
            return (.success, self.radarResponse())
        }

        #expect(result.status == .success)
        #expect(result.urls.count == 2)
        #expect(result.urls[0].contains(RadarSettings.verifiedHost))
        #expect(result.urls[1].contains(RadarSettings.DefaultVerifiedHostSecondary))
        // Selector should be on secondary now.
        #expect(selector.hostForNextRequest().host == .secondary)
    }

    @Test func primary502WithoutMetaFailsOver() {
        let selector = RadarVerifiedHostSelector()
        let coordinator = RadarVerifiedAPICoordinator(selector: selector)

        let result = runRequest(coordinator: coordinator, path: primaryPath) { attempt, _ in
            if attempt == 1 {
                // Dict body but no meta (e.g. Cloudflare HTML parsed by something upstream).
                return (.errorServer, ["error": "bad gateway"])
            }
            return (.success, self.radarResponse())
        }

        #expect(result.status == .success)
        #expect(result.urls.count == 2)
        #expect(result.urls[1].contains(RadarSettings.DefaultVerifiedHostSecondary))
    }

    @Test func primary500WithMetaDoesNotFailover() {
        let selector = RadarVerifiedHostSelector()
        let coordinator = RadarVerifiedAPICoordinator(selector: selector)

        let result = runRequest(coordinator: coordinator, path: primaryPath) { _, _ in
            (.errorServer, ["meta": ["code": 500, "message": "internal"]])
        }

        // The server error is surfaced as-is; no retry on secondary because
        // the response is Radar-origin (has meta).
        #expect(result.status == .errorServer)
        #expect(result.urls.count == 1)
        // Selector stays on primary because this was a Radar response.
        #expect(selector.hostForNextRequest().host == .primary)
    }

    @Test func whileOnSecondaryStaysOnSecondaryWithinProbeWindow() {
        var now = Date(timeIntervalSince1970: 5_000_000)
        let selector = RadarVerifiedHostSelector(now: { now })
        let coordinator = RadarVerifiedAPICoordinator(selector: selector)

        // Prime selector into failed-over state.
        selector.recordNonRadarFailure(on: .primary)

        // Advance time but stay inside the window.
        now = now.addingTimeInterval(30)

        let result = runRequest(coordinator: coordinator, path: primaryPath) { _, _ in
            (.success, self.radarResponse())
        }

        #expect(result.status == .success)
        #expect(result.urls.count == 1)
        #expect(result.urls[0].contains(RadarSettings.DefaultVerifiedHostSecondary))
    }

    @Test func probePrimarySucceedsReturnsToPrimary() {
        var now = Date(timeIntervalSince1970: 6_000_000)
        let selector = RadarVerifiedHostSelector(now: { now })
        let coordinator = RadarVerifiedAPICoordinator(selector: selector)

        selector.recordNonRadarFailure(on: .primary)
        now = now.addingTimeInterval(RadarVerifiedHostSelector.probeInterval + 1)

        let result = runRequest(coordinator: coordinator, path: primaryPath) { _, _ in
            (.success, self.radarResponse())
        }

        #expect(result.urls.count == 1)
        #expect(result.urls[0].contains(RadarSettings.verifiedHost))
        // Next request should prefer primary (no probe needed).
        let next = selector.hostForNextRequest()
        #expect(next.host == .primary)
        #expect(next.isProbe == false)
    }

    @Test func probePrimaryFailsFallsBackToSecondaryAndReArms() {
        var now = Date(timeIntervalSince1970: 7_000_000)
        let selector = RadarVerifiedHostSelector(now: { now })
        let coordinator = RadarVerifiedAPICoordinator(selector: selector)

        selector.recordNonRadarFailure(on: .primary)
        now = now.addingTimeInterval(RadarVerifiedHostSelector.probeInterval + 1)

        let result = runRequest(coordinator: coordinator, path: primaryPath) { attempt, _ in
            if attempt == 1 {
                return (.errorNetwork, nil)
            }
            return (.success, self.radarResponse())
        }

        // Probe failed → coordinator retried on secondary.
        #expect(result.urls.count == 2)
        #expect(result.urls[0].contains(RadarSettings.verifiedHost))
        #expect(result.urls[1].contains(RadarSettings.DefaultVerifiedHostSecondary))

        // New probe window should be in effect.
        now = now.addingTimeInterval(30)
        #expect(selector.hostForNextRequest().host == .secondary)
        now = now.addingTimeInterval(RadarVerifiedHostSelector.probeInterval)
        #expect(selector.hostForNextRequest().host == .primary)
    }

    @Test func bothHostsFailSurfacesSecondaryErrorAndResetsProbe() {
        let now = Date(timeIntervalSince1970: 8_000_000)
        let selector = RadarVerifiedHostSelector(now: { now })
        let coordinator = RadarVerifiedAPICoordinator(selector: selector)

        let result = runRequest(coordinator: coordinator, path: primaryPath) { attempt, _ in
            if attempt == 1 {
                return (.errorNetwork, nil)
            }
            return (.errorServer, ["html": "cloudflare"])
        }

        #expect(result.urls.count == 2)
        #expect(result.status == .errorServer)

        // Next request should probe primary immediately — the 60s timer was
        // cleared by the secondary failure.
        let (host, isProbe) = selector.hostForNextRequest()
        #expect(host == .primary)
        #expect(isProbe == true)
    }

    @Test func urlPreservesQueryString() {
        let path = "/v1/config?installId=abc&verified=true"
        let selector = RadarVerifiedHostSelector()
        let coordinator = RadarVerifiedAPICoordinator(selector: selector)

        let result = runRequest(coordinator: coordinator, path: path) { _, _ in
            (.success, self.radarResponse())
        }

        #expect(result.urls.count == 1)
        let url = result.urls[0]
        #expect(url.contains("installId"))
        #expect(url.contains("verified=true"))
    }
}
