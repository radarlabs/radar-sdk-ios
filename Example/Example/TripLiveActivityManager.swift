//
//  TripLiveActivityManager.swift
//  Example
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import ActivityKit
import Foundation
import RadarSDK

@available(iOS 16.2, *)
final class TripLiveActivityManager {
    static let shared = TripLiveActivityManager()
    private init() {}

    /// Set by AppDelegate at launch so lifecycle messages flow into the Debug
    /// tab's unified console. Optional so the singleton can construct itself
    /// before AppDelegate is ready.
    var logStream: LogStream?

    private var currentActivity: Activity<TripActivityExtensionAttributes>?

    /// Duration (in seconds) to keep the activity visible after ending
    private let dismissalDelay: TimeInterval = 5

    var hasActiveActivity: Bool {
        currentActivity != nil
    }

    // MARK: - Public Methods
    func startActivity(trip: RadarTrip) {
        guard checkActivitiesEnabled() else { return }

        // End any existing activity first
        endActivity()

        Task {
            let contentState = await buildContentState(from: trip)
            createActivity(contentState: contentState)
        }
    }

    func updateActivity(trip: RadarTrip, statusOverride: String? = nil) {
        guard let activity = currentActivity else {
            logStream?.write(error: "Live Activity update skipped", detail: "no active activity")
            return
        }

        Task {
            let contentState = await buildContentState(from: trip, statusOverride: statusOverride)
            await activity.update(.init(state: contentState, staleDate: nil))
        }
    }

    func endActivity(status: String = "completed") {
        guard let activity = currentActivity else {
            logStream?.write(error: "Live Activity end skipped", detail: "no active activity")
            return
        }

        let finalState = TripActivityExtensionAttributes.ContentState(
            name: "Trip Ended",
            tripId: "",
            status: status,
            etaDuration: nil,
            mode: nil,
            destinationAddress: nil
        )
        Task {
            await activity.end(
                .init(state: finalState, staleDate: nil),
                dismissalPolicy: .after(.now + dismissalDelay)
            )
            currentActivity = nil
            logStream?.write(result: "Live Activity ended", detail: "status: \(status)")
        }
    }

    // MARK: - Private Methods
    private func checkActivitiesEnabled() -> Bool {
        let authInfo = ActivityAuthorizationInfo()

        guard authInfo.areActivitiesEnabled else {
            logStream?.write(error: "Live Activities not enabled", detail: "Check Settings → Notifications")
            return false
        }
        return true
    }

    private func createActivity(contentState: TripActivityExtensionAttributes.ContentState) {
        do {
            let activity = try Activity.request(
                attributes: TripActivityExtensionAttributes(),
                content: .init(state: contentState, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
            logStream?.write(result: "Live Activity started")
        } catch {
            logStream?.write(error: "Live Activity start failed", detail: error.localizedDescription)
        }
    }

    private func buildContentState(from trip: RadarTrip, statusOverride: String? = nil) async -> TripActivityExtensionAttributes.ContentState {
        let destinationAddress = await fetchDestinationAddress(from: trip)

        return TripActivityExtensionAttributes.ContentState(
            name: trip.externalId ?? trip._id,
            tripId: trip._id,
            status: statusOverride ?? Radar.stringForTripStatus(trip.status),
            etaDuration: Double(trip.etaDuration),
            mode: Radar.stringForMode(trip.mode),
            destinationAddress: destinationAddress
        )
    }

    private func fetchDestinationAddress(from trip: RadarTrip) async -> String? {
        guard let destinationLocation = trip.destinationLocation else {
            return nil
        }

        let location = CLLocation(
            latitude: destinationLocation.coordinate.latitude,
            longitude: destinationLocation.coordinate.longitude
        )

        return await withCheckedContinuation { continuation in
            Radar.reverseGeocode(location: location) { _, addresses in
                let address = addresses?.first?.formattedAddress?.truncatedAtFirstComma
                continuation.resume(returning: address)
            }
        }
    }
}

// MARK: - String Extension
private extension String {
    var truncatedAtFirstComma: String {
        guard let commaIndex = firstIndex(of: ",") else { return self }
        return String(self[..<commaIndex])
    }
}
