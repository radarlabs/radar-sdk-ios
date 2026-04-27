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
final class RadarFailoverAPICoordinatorTests: @unchecked Sendable {

    private let primaryHost = "https://primary.example.com"
    private let secondaryHost = "https://secondary.example.com"

    private func radarResponse() -> [AnyHashable: Any] {
        ["meta": ["code": 200], "user": ["_id": "u"]]
    }

    private func nonRadarResponse() -> [AnyHashable: Any] {
        ["error": "bad gateway"]
    }

    private func makeCoordinator(
        healthInterval: TimeInterval = 15,
        schedulesHealthChecks: Bool = false,
        healthCheck: @escaping RadarFailoverAPICoordinator.HealthCheck = { _, completion in completion(false) }
    ) -> RadarFailoverAPICoordinator {
        RadarFailoverAPICoordinator(
            hostsProvider: { [self.primaryHost, self.secondaryHost] },
            healthInterval: healthInterval,
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

        let second = runRequest(coordinator: coordinator) { _ in
            (.success, self.radarResponse())
        }

        #expect(second.urls == ["https://primary.example.com/v1/track"])
    }

    @Test func primaryNetworkErrorSwitchesOnlyFutureRequestsToSecondary() {
        let coordinator = makeCoordinator()

        let first = runRequest(coordinator: coordinator) { _ in
            (.errorNetwork, nil)
        }

        #expect(first.status == .errorNetwork)
        #expect(first.urls == ["https://primary.example.com/v1/track"])

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

        let second = runRequest(coordinator: coordinator) { _ in
            (.success, self.radarResponse())
        }

        #expect(second.urls == ["https://primary.example.com/v1/track"])
    }

    @Test func failoverStartsHealthTimer() {
        let healthCheckRan = DispatchSemaphore(value: 0)
        let coordinator = makeCoordinator(healthInterval: 0.01, schedulesHealthChecks: true) { _, completion in
            completion(false)
            healthCheckRan.signal()
        }
        defer { coordinator.reset() }

        _ = runRequest(coordinator: coordinator) { _ in
            (.errorNetwork, nil)
        }

        #expect(healthCheckRan.wait(timeout: .now() + 1) == .success)
    }

    @Test func failedHealthCheckKeepsSecondaryActive() {
        let healthCheckRan = DispatchSemaphore(value: 0)
        let coordinator = makeCoordinator(healthInterval: 0.01, schedulesHealthChecks: true) { _, completion in
            completion(false)
            healthCheckRan.signal()
        }
        defer { coordinator.reset() }

        _ = runRequest(coordinator: coordinator) { _ in
            (.errorNetwork, nil)
        }

        #expect(healthCheckRan.wait(timeout: .now() + 1) == .success)

        let result = runRequest(coordinator: coordinator) { _ in
            (.success, self.radarResponse())
        }

        #expect(result.urls == ["https://secondary.example.com/v1/track"])
    }

    @Test func positiveHealthCheckReturnsToPrimary() {
        let healthCheckRan = DispatchSemaphore(value: 0)
        let coordinator = makeCoordinator(healthInterval: 0.01, schedulesHealthChecks: true) { host, completion in
            #expect(host == self.primaryHost)
            completion(true)
            healthCheckRan.signal()
        }
        defer { coordinator.reset() }

        _ = runRequest(coordinator: coordinator) { _ in
            (.errorNetwork, nil)
        }

        #expect(healthCheckRan.wait(timeout: .now() + 1) == .success)

        let result = eventuallyRunPrimaryRequest(coordinator: coordinator) {
            (.success, self.radarResponse())
        }

        #expect(result.urls == ["https://primary.example.com/v1/track"])
    }

    private func eventuallyRunPrimaryRequest(
        coordinator: RadarFailoverAPICoordinator,
        respond: @escaping () -> (RadarStatus, [AnyHashable: Any]?)
    ) -> (status: RadarStatus, res: [AnyHashable: Any]?, urls: [String]) {
        let deadline = Date().addingTimeInterval(1)
        var latest = runRequest(coordinator: coordinator) { _ in respond() }

        while latest.urls.last != "https://primary.example.com/v1/track" && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.01)
            latest = runRequest(coordinator: coordinator) { _ in respond() }
        }

        return latest
    }
}
