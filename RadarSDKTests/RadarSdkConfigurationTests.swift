//
//  RadarSdkConfigurationTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

extension RadarSerializedTests {
    @Suite(.serialized)
    @MainActor
    struct RadarSdkConfigurationTests {
        private let fixture = RadarSDKTestFixture()

        @Test("the server SDK configuration replaces the local one")
        func sdkConfigurationFromServer() async throws {
            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
                "logLevel": "warning",
                "startTrackingOnInitialize": true,
                "trackOnceOnAppOpen": true,
                "usePersistence": false,
                "extendFlushReplays": false,
                "useLogPersistence": false,
                "useRadarModifiedBeacon": false,
                "syncAfterSetUser": false,
            ])
            #expect(RadarSettings.logLevel == .warning)

            fixture.apiHelperMock.mockStatus = .success
            fixture.apiHelperMock.mockResponse = try RadarSDKTestResources.jsonDictionary(fromResource: "get_config_response")

            let (status, config) = await awaitCompletion { resume in
                RadarAPIClient.sharedInstance().getConfigForUsage("sdkConfigUpdate", verified: false) { status, config in
                    resume((status, config))
                }
            }

            #expect(status == .success)
            // The bridging header imports `RadarMeta.h`, which only forward-declares `RadarSdkConfiguration`,
            // so Swift drops the typed property. Read it through KVC instead.
            let meta = try #require(config?.meta)
            let sdkConfiguration = try #require(meta.value(forKey: "sdkConfiguration") as? RadarSdkConfiguration)
            RadarSettings.sdkConfiguration = sdkConfiguration

            #expect(sdkConfiguration.logLevel == .info)
            #expect(RadarSettings.logLevel == .info)
            #expect(sdkConfiguration.trackOnceOnAppOpen)
            #expect(sdkConfiguration.startTrackingOnInitialize)

            Radar.setLogLevel(.debug)
            let clientLogLevel = try #require(RadarSettings.clientSdkConfiguration["logLevel"] as? String)
            #expect(RadarLogger.levelFromString(clientLogLevel) == .debug)

            let saved = try #require(RadarSettings.sdkConfiguration)
            #expect(saved.trackOnceOnAppOpen)
            #expect(saved.startTrackingOnInitialize)
        }

        @Test("skipForegroundCheck defaults to true")
        func skipForegroundCheckDefault() {
            #expect(RadarSdkConfiguration(dict: [:]).skipForegroundCheck)
            #expect(!RadarSdkConfiguration(dict: ["skipForegroundCheck": false]).skipForegroundCheck)
            #expect(RadarSdkConfiguration(dict: ["skipForegroundCheck": true]).skipForegroundCheck)
        }
    }
}
