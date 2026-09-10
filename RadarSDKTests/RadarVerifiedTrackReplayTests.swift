//
//  RadarVerifiedTrackReplayTests.swift
//  RadarSDK
//
//  Created by Alan Charles on 9/10/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import XCTest

@testable import RadarSDK

extension RadarVerifiedHostOverrideTests {
    func test_preparationFailure_doesNotBufferReplay() {
        withIsolatedReplayState {
            assertReplayBehavior(preparationFails: true)
        }
    }

    func test_networkFailure_stillBuffersReplay() {
        withIsolatedReplayState {
            assertReplayBehavior(preparationFails: false)
        }
    }

    private func withIsolatedReplayState(_ body: () -> Void) {
        let buffer = RadarReplayBuffer.sharedInstance
        let originalReplays = buffer.mutableReplayBuffer
        let originalOptions = RadarSettings.trackingOptions
        let originalRemoteOptions = RadarSettings.remoteTrackingOptions
        let originalConfiguration = RadarUserDefaults.object(forKey: .sdkConfiguration)
        let originalLogLevel = RadarUserDefaults.object(forKey: .logLevel)
        let originalSyncState = RadarSyncManager.syncStore.read()

        defer {
            buffer.mutableReplayBuffer = originalReplays
            RadarSettings.trackingOptions = originalOptions
            RadarSettings.remoteTrackingOptions = originalRemoteOptions
            RadarUserDefaults.set(originalConfiguration, forKey: .sdkConfiguration)
            RadarUserDefaults.set(originalLogLevel, forKey: .logLevel)
            RadarOfflineEventManager.reset()

            if let originalSyncState {
                RadarSyncManager.syncStore.write(originalSyncState)
            } else {
                RadarSyncManager.syncStore.clear()
            }
        }

        buffer.mutableReplayBuffer = []
        RadarSettings.remoteTrackingOptions = nil
        
        let offlineOptions = RadarTrackingOptions.presetContinuous
        offlineOptions.desiredMovingUpdateInterval = 17

        RadarSettings.sdkConfiguration = RadarSdkConfiguration(
            dict: [
                "usePersistence": false,
                "offlineEventGenerationEnabled": true,
                "useOfflineRTOUpdates": true,
                "remoteTrackingOptions": [
                    [
                        "type": "inGeofence",
                        "geofenceTags": ["test"],
                        "trackingOptions": offlineOptions.dictionaryValue(),
                    ]
                ],
            ]
        )

        let options = RadarTrackingOptions.presetContinuous
        options.replay = .all
        RadarSettings.trackingOptions = options
        RadarOfflineEventManager.reset()
        seedReplayTestGeofence()

        body()
    }

    private func assertReplayBehavior(preparationFails: Bool) {
        let client = RadarAPIClient.sharedInstance()
        let originalHelper = client.apiHelper
        defer { client.apiHelper = originalHelper }

        let helper = VerifiedFailureAPIHelperMock()
        helper.failDuringPreparation = preparationFails
        client.apiHelper = helper

        let delegateHolder = RadarDelegateHolder.sharedInstance()
        let originalDelegate = delegateHolder.delegate
        let delegate = VerifiedFailureDelegate()
        delegateHolder.delegate = delegate
        defer { delegateHolder.delegate = originalDelegate }

        let finished = expectation(description: "One tracking callback")
        finished.assertForOverFulfill = true

        client.track(
            with: CLLocation(latitude: 40.0, longitude: -73.0),
            stopped: false,
            foreground: true,
            source: .foregroundLocation,
            replayed: false,
            beacons: nil,
            indoorLocation: nil,
            verified: true,
            fraudPayload: nil,
            expectedCountryCode: nil,
            expectedStateCode: nil,
            reason: nil,
            transactionId: nil,
            revealRiskId: nil,
            useSecondaryVerifiedHost: false,
            prepareRequest: { request, completion in
                completion(.success, request, nil)
            },
            completionHandler: { status, _, _, _, _, config, _ in
                let expectedStatus: RadarStatus =
                    preparationFails ? .errorUnknown : .errorNetwork
                XCTAssertEqual(status, expectedStatus)

                if preparationFails {
                    XCTAssertNil(config)
                } else {
                    XCTAssertNotNil(config?.meta?.trackingOptions)
                    XCTAssertEqual(
                        config?.meta?.trackingOptions?.desiredMovingUpdateInterval,
                        17
                    )
                }

                finished.fulfill()
            }
        )

        wait(for: [finished], timeout: 5.0)
        XCTAssertEqual(
            delegate.recordedStatuses,
            preparationFails ? [] : [.errorNetwork]
        )
        XCTAssertEqual(helper.lastMethod, "POST")
        XCTAssertEqual(helper.lastUrl, "\(RadarSettings.verifiedHost)/v1/track")

        let replays = RadarReplayBuffer.sharedInstance.flushableReplays
        XCTAssertEqual(replays.count, preparationFails ? 0 : 1)

        if !preparationFails {
            XCTAssertEqual(replays.first?.replayParams["verified"] as? Bool, true)
            XCTAssertEqual(replays.first?.replayParams["replayed"] as? Bool, true)
            XCTAssertNil(replays.first?.replayParams["fraudPayload"])
        }

        let entryTimestamp = RadarSyncManager.syncStore.read()?
            .geofenceEntryTimestamps["verified-replay-offline-test"]

        if preparationFails {
            XCTAssertNil(entryTimestamp)
        } else {
            XCTAssertNotNil(entryTimestamp)
        }
    }

    private func seedReplayTestGeofence() {
        let center = RadarCoordinateSwift(latitude: 40.0, longitude: -73.0)
        let geofence = RadarGeofenceSwift(
            id: "verified-replay-offline-test",
            description: "Replay regression test",
            tag: "test",
            externalId: "verified-replay-offline-test",
            geometry: .circle(center: center, radius: 100),
            dwellThreshold: nil,
            geofenceStopDetection: nil,
            metadata: nil
        )

        var state = RadarSyncState()
        state.syncedGeofences = [geofence]
        state.lastSyncedGeofenceIds = []
        RadarSyncManager.syncStore.write(state)
    }
}
