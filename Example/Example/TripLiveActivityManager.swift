//
//  TripLiveActivityManager.swift
//  Example
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation
import ActivityKit
import RadarSDK

@available(iOS 16.2, *)
final class TripLiveActivityManager {
    static let shared = TripLiveActivityManager()
    private init() {}
    
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
            print("No active Live Activity to update")
            return
        }
        
        Task {
            let contentState = await buildContentState(from: trip, statusOverride: statusOverride)
            await activity.update(.init(state: contentState, staleDate: nil))
        }
    }
    
    func endActivity(status: String = "completed") {
        guard let activity = currentActivity else {
            print("No active Live Activity to end")
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
            print("Live Activity ended: \(status)")
        }
    }
    
    // MARK: - Private Methods
    private func checkActivitiesEnabled() -> Bool {
        let authInfo = ActivityAuthorizationInfo()

        guard authInfo.areActivitiesEnabled else {
            print("Live Activities are not enabled - check Settings")
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
            print("Live Activity started")
        } catch {
            print("Error starting Live Activity: \(error.localizedDescription)")
        }
    }
    
    private func buildContentState(from trip: RadarTrip, statusOverride: String? = nil) async -> TripActivityExtensionAttributes.ContentState {
        let destinationAddress = await fetchDestinationAddress(from: trip)
        
        return TripActivityExtensionAttributes.ContentState(
            name: trip.externalId ?? trip._id,
            tripId: trip._id,
            status: statusOverride ?? trip.status.stringValue,
            etaDuration: Double(trip.etaDuration),
            mode: trip.mode.stringValue,
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
            Radar.reverseGeocode(location: location) { status, addresses in
                let address = addresses?.first?.formattedAddress?.truncatedAtFirstComma
                continuation.resume(returning: address)
            }
        }
    }
}

// MARK: - RadarTripStatus Extension
extension RadarTripStatus {
    var stringValue: String {
        switch self {
        case .started: return "started"
        case .approaching: return "approaching"
        case .arrived: return "arrived"
        case .expired: return "expired"
        case .completed: return "completed"
        case .canceled: return "canceled"
        default: return "unknown"
        }
    }
}

// MARK: - RadarRouteMode Extension
extension RadarRouteMode {
    var stringValue: String {
        switch self {
        case .car: return "car"
        case .bike: return "bike"
        case .foot: return "foot"
        case .truck: return "truck"
        case .motorbike: return "motorbike"
        default: return "car"
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
