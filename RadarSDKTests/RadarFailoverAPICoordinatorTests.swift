//
//  RadarFailoverAPICoordinatorTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing
@testable import RadarSDK

@Suite(.serialized)
final class RadarFailoverAPICoordinatorTests {

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

    private func verifiedHostsProvider() -> () -> [String] {
        return { [RadarSettings.verifiedHost, RadarSettings.DefaultVerifiedHostSecondary] }
    }

    private func makeVerifiedCoordinator(
        now: @escaping () -> Date = Date.init
    ) -> (RadarFailoverHostSelector, RadarFailoverAPICoordinator) {
        let selector = RadarFailoverHostSelector(hostCount: 2, now: now)
        let coordinator = RadarFailoverAPICoordinator(
            selector: selector,
            hostsProvider: verifiedHostsProvider()
        )
        return (selector, coordinator)
    }

    private func runRequest(
        coordinator: RadarFailoverAPICoordinator,
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
        let (selector, coordinator) = makeVerifiedCoordinator()

        let result = runRequest(coordinator: coordinator, path: primaryPath) { _, _ in
            (.success, self.radarResponse())
        }

        #expect(result.status == .success)
        #expect(result.urls.count == 1)
        #expect(result.urls[0].contains(RadarSettings.verifiedHost))
        #expect(selector.indexForNextRequest().index == 0)
    }

    @Test func transportErrorOnPrimaryFallsOverToSecondary() {
        let (selector, coordinator) = makeVerifiedCoordinator()

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
        #expect(selector.indexForNextRequest().index == 1)
    }

    @Test func primary502WithoutMetaFailsOver() {
        let (_, coordinator) = makeVerifiedCoordinator()

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
        let (selector, coordinator) = makeVerifiedCoordinator()

        let result = runRequest(coordinator: coordinator, path: primaryPath) { _, _ in
            (.errorServer, ["meta": ["code": 500, "message": "internal"]])
        }

        // The server error is surfaced as-is; no retry on secondary because
        // the response is Radar-origin (has meta).
        #expect(result.status == .errorServer)
        #expect(result.urls.count == 1)
        // Selector stays on primary because this was a Radar response.
        #expect(selector.indexForNextRequest().index == 0)
    }

    @Test func whileOnSecondaryStaysOnSecondaryWithinProbeWindow() {
        var now = Date(timeIntervalSince1970: 5_000_000)
        let (selector, coordinator) = makeVerifiedCoordinator(now: { now })

        // Prime selector into failed-over state.
        selector.recordNonRadarFailure(onIndex: 0)

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
        let (selector, coordinator) = makeVerifiedCoordinator(now: { now })

        selector.recordNonRadarFailure(onIndex: 0)
        now = now.addingTimeInterval(RadarFailoverHostSelector.probeInterval + 1)

        let result = runRequest(coordinator: coordinator, path: primaryPath) { _, _ in
            (.success, self.radarResponse())
        }

        #expect(result.urls.count == 1)
        #expect(result.urls[0].contains(RadarSettings.verifiedHost))
        // Next request should prefer primary (no probe needed).
        let next = selector.indexForNextRequest()
        #expect(next.index == 0)
        #expect(next.isProbe == false)
    }

    @Test func probePrimaryFailsFallsBackToSecondaryAndReArms() {
        var now = Date(timeIntervalSince1970: 7_000_000)
        let (selector, coordinator) = makeVerifiedCoordinator(now: { now })

        selector.recordNonRadarFailure(onIndex: 0)
        now = now.addingTimeInterval(RadarFailoverHostSelector.probeInterval + 1)

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
        #expect(selector.indexForNextRequest().index == 1)
        now = now.addingTimeInterval(RadarFailoverHostSelector.probeInterval)
        #expect(selector.indexForNextRequest().index == 0)
    }

    @Test func bothHostsFailSurfacesSecondaryErrorAndResetsProbe() {
        let now = Date(timeIntervalSince1970: 8_000_000)
        let (selector, coordinator) = makeVerifiedCoordinator(now: { now })

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
        let (index, isProbe) = selector.indexForNextRequest()
        #expect(index == 0)
        #expect(isProbe == true)
    }

    @Test func urlPreservesQueryString() {
        let path = "/v1/config?installId=abc&verified=true"
        let (_, coordinator) = makeVerifiedCoordinator()

        let result = runRequest(coordinator: coordinator, path: path) { _, _ in
            (.success, self.radarResponse())
        }

        #expect(result.urls.count == 1)
        let url = result.urls[0]
        #expect(url.contains("installId"))
        #expect(url.contains("verified=true"))
    }
}
