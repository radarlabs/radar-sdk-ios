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

    private let primaryHost = "https://primary.example.com"
    private let secondaryHost = "https://secondary.example.com"

    private func radarResponse() -> [AnyHashable: Any] {
        ["meta": ["code": 200], "user": ["_id": "u"]]
    }

    private func nonRadarResponse() -> [AnyHashable: Any] {
        ["error": "bad gateway"]
    }

    private func makeCoordinator(
        schedulesHealthChecks: Bool = false,
        healthCheck: @escaping RadarFailoverAPICoordinator.HealthCheck = { _, completion in completion(false) }
    ) -> RadarFailoverAPICoordinator {
        RadarFailoverAPICoordinator(
            hostsProvider: { [self.primaryHost, self.secondaryHost] },
            healthInterval: 15,
            schedulesHealthChecks: schedulesHealthChecks,
            healthCheck: healthCheck
        )
    }

    private func runRequest(
        coordinator: RadarFailoverAPICoordinator,
        respond: @escaping (String) -> (RadarStatus, [AnyHashable: Any]?)
    ) -> (status: RadarStatus, res: [AnyHashable: Any]?, urls: [String]) {
        var urls: [String] = []
        var finalStatus: RadarStatus = .errorUnknown
        var finalRes: [AnyHashable: Any]?

        coordinator.request(
            path: "/v1/track",
            performRequest: { url, completion in
                urls.append(url)
                let response = respond(url)
                completion(response.0, response.1)
            },
            completionHandler: { status, res in
                finalStatus = status
                finalRes = res
            }
        )

        return (finalStatus, finalRes, urls)
    }

    @Test func primaryRadarResponseStaysPrimary() {
        let coordinator = makeCoordinator()

        let result = runRequest(coordinator: coordinator) { _ in
            (.success, self.radarResponse())
        }

        #expect(result.status == .success)
        #expect(result.urls == ["https://primary.example.com/v1/track"])
        #expect(coordinator.isUsingSecondaryForTests == false)
    }

    @Test func primaryNetworkErrorSwitchesOnlyFutureRequestsToSecondary() {
        let coordinator = makeCoordinator()

        let first = runRequest(coordinator: coordinator) { _ in
            (.errorNetwork, nil)
        }

        #expect(first.status == .errorNetwork)
        #expect(first.urls == ["https://primary.example.com/v1/track"])
        #expect(coordinator.isUsingSecondaryForTests)

        let second = runRequest(coordinator: coordinator) { _ in
            (.success, self.radarResponse())
        }

        #expect(second.status == .success)
        #expect(second.urls == ["https://secondary.example.com/v1/track"])
    }

    @Test func primaryNonRadarResponseSwitchesFutureRequestsToSecondary() {
        let coordinator = makeCoordinator()

        let first = runRequest(coordinator: coordinator) { _ in
            (.errorServer, self.nonRadarResponse())
        }

        #expect(first.urls == ["https://primary.example.com/v1/track"])
        #expect(coordinator.isUsingSecondaryForTests)

        let second = runRequest(coordinator: coordinator) { _ in
            (.success, self.radarResponse())
        }

        #expect(second.urls == ["https://secondary.example.com/v1/track"])
    }

    @Test func primaryRadarErrorWithMetaDoesNotSwitch() {
        let coordinator = makeCoordinator()

        let result = runRequest(coordinator: coordinator) { _ in
            (.errorServer, ["meta": ["code": 500]])
        }

        #expect(result.status == .errorServer)
        #expect(result.urls == ["https://primary.example.com/v1/track"])
        #expect(coordinator.isUsingSecondaryForTests == false)
    }

    @Test func failoverStartsHealthTimer() {
        let coordinator = makeCoordinator(schedulesHealthChecks: true)
        defer { coordinator.reset() }

        _ = runRequest(coordinator: coordinator) { _ in
            (.errorNetwork, nil)
        }

        #expect(coordinator.isUsingSecondaryForTests)
        #expect(coordinator.isHealthTimerActiveForTests)
    }

    @Test func failedHealthCheckKeepsSecondaryActive() {
        let coordinator = makeCoordinator { _, completion in
            completion(false)
        }

        _ = runRequest(coordinator: coordinator) { _ in
            (.errorNetwork, nil)
        }

        coordinator.runHealthCheckForTests()
        coordinator.waitForHealthCheckForTests()

        #expect(coordinator.isUsingSecondaryForTests)
    }

    @Test func positiveHealthCheckReturnsToPrimary() {
        let coordinator = makeCoordinator { host, completion in
            #expect(host == self.primaryHost)
            completion(true)
        }

        _ = runRequest(coordinator: coordinator) { _ in
            (.errorNetwork, nil)
        }

        coordinator.runHealthCheckForTests()
        coordinator.waitForHealthCheckForTests()

        #expect(coordinator.isUsingSecondaryForTests == false)

        let result = runRequest(coordinator: coordinator) { _ in
            (.success, self.radarResponse())
        }

        #expect(result.urls == ["https://primary.example.com/v1/track"])
    }
}
