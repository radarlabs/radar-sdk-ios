//
//  RadarAPIClientWiringTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing
@testable import RadarSDK

extension RadarSerializedTests {

    /// Proves that the verified branches of RadarAPIClient actually route
    /// through RadarFailoverAPICoordinator — a pure-unit test of the
    /// coordinator can't catch a regression where someone rewires
    /// RadarAPIClient to call RadarAPIHelper directly again.
    @Suite(.serialized)
    final class RadarAPIClientWiringTests {

        private let apiHelperMock: RadarAPIHelperMock

        init() {
            Radar.initialize(publishableKey: "prj_test_pk_0000000000000000")
            self.apiHelperMock = RadarAPIHelperMock()
            RadarAPIClient.sharedInstance().apiHelper = self.apiHelperMock
            // Prevent the log buffer's background flush from racing our capture.
            RadarLogBuffer.sharedInstance().clear()
        }

        private func setFailoverFlag(_ enabled: Bool) {
            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: ["useVerifiedHostFailover": enabled])
        }

        /// Snapshot lastUrl at getConfig completion. Reading it after the await
        /// can race with background log flushes that also hit the mock.
        private func capturedLastUrl(verified: Bool) async -> String? {
            let mock = apiHelperMock
            return await withCheckedContinuation { continuation in
                RadarAPIClient.sharedInstance().getConfigForUsage(
                    "wiring-test",
                    verified: verified
                ) { _, _ in
                    continuation.resume(returning: mock.lastUrl)
                }
            }
        }

        @Test
        func verifiedGetConfig_failsOverToSecondary_whenFlagEnabled() async {
            // Primary returns a response that doesn't look like it came from Radar
            // (no top-level `meta`). The coordinator should retry on the secondary
            // host. Secondary returns the same shape — coordinator then surfaces
            // the error. We only care that the final URL was the secondary host,
            // which can only happen if the coordinator is in the path.
            setFailoverFlag(true)
            apiHelperMock.mockStatus = .errorServer

            let lastUrl = await capturedLastUrl(verified: true)

            #expect(lastUrl?.contains("api-verified.radar.com") == true,
                    "expected final URL to be on the secondary host after failover, got: \(lastUrl ?? "nil")")
        }

        @Test
        func verifiedGetConfig_skipsCoordinator_whenFlagDisabled() async {
            // Same non-Radar response that would trigger failover with the flag on —
            // with the flag off, the request must bypass the coordinator entirely and
            // stay on the primary verified host. If the coordinator is in the path,
            // the URL would flip to the secondary.
            setFailoverFlag(false)
            apiHelperMock.mockStatus = .errorServer

            let lastUrl = await capturedLastUrl(verified: true)

            #expect(lastUrl?.contains("api-verified.radar.io") == true,
                    "expected URL to stay on the primary verified host, got: \(lastUrl ?? "nil")")
            #expect(lastUrl?.contains("api-verified-cf.use1.radar-staging.com") == false,
                    "expected no failover to secondary when flag is off, got: \(lastUrl ?? "nil")")
        }
    }

}
