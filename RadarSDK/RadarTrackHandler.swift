//
//  RadarTrackHandler.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

/// Sends track requests through `RadarAPIClient` and applies the result to SDK state: the replay
/// buffer, `RadarState`, settings, offline events, and delegate callbacks.
enum RadarTrackHandler {

    // swiftlint:disable:next function_parameter_count
    static func trackVerified(
        location: CLLocation,
        stopped: Bool,
        foreground: Bool,
        source: RadarLocationSource,
        beacons: [RadarBeacon]?,
        fraudPayload: String,
        expectedCountryCode: String?,
        expectedStateCode: String?,
        expectedAddress: String?,
        reason: String?,
        transactionId: String?,
        revealRiskId: String?,
        useSecondaryVerifiedHost: Bool,
        apiClient: RadarAPIClient = .shared
    ) async throws -> RadarTrackResponse {
        let request = try await apiClient.verifiedTrackRequest(
            location: location,
            stopped: stopped,
            foreground: foreground,
            source: source,
            beacons: beacons,
            fraudPayload: fraudPayload,
            expectedCountryCode: expectedCountryCode,
            expectedStateCode: expectedStateCode,
            expectedAddress: expectedAddress,
            reason: reason,
            transactionId: transactionId,
            revealRiskId: revealRiskId,
            useSecondaryVerifiedHost: useSecondaryVerifiedHost
        )

        let response: RadarTrackResponse
        do {
            response = try await apiClient.track(request)
        } catch {
            handleTrackFailure(status: error.status, request: request)
            throw error
        }

        return try await handleTrackResponse(response, request: request)
    }

    static func handleTrackFailure(status: RadarStatus, request: RadarTrackRequest) {
        let options = request.options
        if options.replay == .all {
            // create a copy of params that we can use to write to the buffer in case of request failure
            var bufferParams = request.params
            bufferParams["replayed"] = true

            // Skip notification removal under XCTest, matching RadarAPIClient.m.
            if NSClassFromString("XCTestCase") == nil {
                let notificationDiff = request.notificationsDelivered.isEmpty ? nil : request.notificationsDelivered
                Task {
                    await RadarNotificationHelper.shared.removeRegisteredNotifications(notifications: notificationDiff)
                }
            }

            RadarReplayBuffer.sharedInstance.writeNewReplayToBuffer(bufferParams)
        } else if options.replay == .stops && request.stopped
            && !(request.source == .foregroundLocation || request.source == .manualLocation)
        {
            RadarState().lastFailedStoppedLocation = request.location
        }

        RadarSwift.bridge?.didFail(status: status)

        // Generate offline events on track failure (gated internally by offlineEventGenerationEnabled)
        RadarOfflineEventManager.handleTrackFailure(request.location)
    }

    /// Applies a successful response to SDK state. Throws `.errorServer` when the response is
    /// missing `events` or `user`.
    static func handleTrackResponse(_ response: RadarTrackResponse, request: RadarTrackRequest) async throws -> RadarTrackResponse {
        let state = RadarState()

        RadarReplayBuffer.sharedInstance.clearBuffer()
        state.lastFailedStoppedLocation = nil
        RadarLogger.flushLogs()
        RadarSettings.updateLastTrackedTime()

        if response.res["user"] is [String: Any] {
            // Extract and store altitudeAdjustments from user object
            if let altitudeAdjustments = response.altitudeAdjustments {
                state.altitudeAdjustments = altitudeAdjustments
                RadarLogger.shared.debug("Stored \(altitudeAdjustments.count) altitude adjustments from track response")
            } else {
                state.altitudeAdjustments = nil
            }
        }

        if !response.inAppMessages.isEmpty {
            nonisolated(unsafe) let inAppMessages = response.inAppMessages
            await RadarInAppMessageManager.shared.onInAppMessageReceived(messages: inAppMessages)
        }

        if let user = response.user {
            updateTrackState(from: user, state: state)
        }

        RadarOfflineEventManager.reset()

        guard response.events != nil, let user = response.user else {
            // getNotificationDiff never reports remaining notifications, so this always clears them.
            RadarLogger.shared.info("Setting 0 notifications remaining")
            state.registeredNotifications = []
            RadarSwift.bridge?.didFail(status: .errorServer)
            throw RadarError(status: .errorServer)
        }

        RadarSettings.id = user._id
        state.radarUser = user

        updateTrip(from: user)

        RadarSettings.userDebug = user.debug

        RadarSwift.bridge?.didUpdateLocation(request.location, user: user)

        if let events = response.events, !events.isEmpty {
            RadarSwift.bridge?.didReceiveEvents(events, user: user)
        }

        if let token = response.token {
            RadarSwift.bridge?.didUpdateToken(token)
        }

        if let regions = response.nearbyBeaconRegions {
            nonisolated(unsafe) let beaconRegions = regions
            Task { @MainActor in
                RadarOneShotBeaconManager.shared.registerBeaconRegionNotifications(from: beaconRegions)
            }
        }

        return response
    }

    private static func updateTrip(from user: RadarUser) {
        // Update local trip state from server response
        if let trip = user.trip {
            // Update local trip with latest state (ETAs, leg statuses, etc.)
            RadarSettings.trip = trip
        } else if RadarSettings.tripOptions != nil {
            // Trip ended server-side - restore previous tracking options
            RadarSwift.bridge?.restartPreviousTrackingOptions()
            RadarSettings.tripOptions = nil
            RadarSettings.trip = nil
        }
    }

    private static func updateTrackState(from user: RadarUser, state: RadarState) {
        let inGeofences = !(user.geofences?.isEmpty ?? true)
        let atPlace = user.place != nil
        state.canExit = inGeofences || atPlace

        state.geofenceIds = user.geofences?.map(\._id) ?? []
        state.placeId = user.place?._id
        state.regionIds = [user.country, user.state, user.dma, user.postalCode].compactMap { $0?._id }
        state.beaconIds = user.beacons?.compactMap(\._id) ?? []
    }
}
