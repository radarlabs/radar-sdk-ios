//
//  TestsView.swift
//  Example
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import SwiftUI
import CoreLocation
import RadarSDK

struct TestsView: View {
    private let tripExternalId = "delivery-route-full-test3"
    private struct LegDestination {
        let tag: String
        let externalId: String
    }
    private let legs: [LegDestination] = [
        .init(tag: "route", externalId: "000-4"),
        .init(tag: "route", externalId: "000-2"),
        .init(tag: "route", externalId: "000-3"),
        .init(tag: "store", externalId: "0001")
    ]
    @State private var currentLegIndex: Int = 0
    
    var body: some View {
        ScrollView {
            StyledButton("startTrip") {
                currentLegIndex = 0
                let dest = legs[currentLegIndex]
                let tripOptions = RadarTripOptions(externalId: tripExternalId, destinationGeofenceTag: dest.tag, destinationGeofenceExternalId: dest.externalId)
                tripOptions.mode = .car
                Radar.startTrip(options: tripOptions)
            }

            StyledButton("startTrip with start tracking false") {
                currentLegIndex = 0
                let dest = legs[currentLegIndex]
                let tripOptions = RadarTripOptions(externalId: tripExternalId, destinationGeofenceTag: dest.tag, destinationGeofenceExternalId: dest.externalId, scheduledArrivalAt: nil, startTracking: false)
                tripOptions.mode = .car
                Radar.startTrip(options: tripOptions)
            }

            StyledButton("startTrip with tracking options") {
                currentLegIndex = 0
                let dest = legs[currentLegIndex]
                let tripOptions = RadarTripOptions(externalId: tripExternalId, destinationGeofenceTag: dest.tag, destinationGeofenceExternalId: dest.externalId, scheduledArrivalAt: nil, startTracking: false)
                tripOptions.mode = .car
                let trackingOptions = RadarTrackingOptions.presetContinuous
                Radar.startTrip(options: tripOptions, trackingOptions: trackingOptions)
            }

            StyledButton("startTrip with tracking options and startTrackingAfter") {
                currentLegIndex = 0
                let dest = legs[currentLegIndex]
                let tripOptions = RadarTripOptions(externalId: tripExternalId, destinationGeofenceTag: dest.tag, destinationGeofenceExternalId: dest.externalId, scheduledArrivalAt: nil)
                tripOptions.startTracking = false
                tripOptions.mode = .car
                let trackingOptions = RadarTrackingOptions.presetContinuous
                // startTrackingAfter 3 minutes from now
                trackingOptions.startTrackingAfter = Date().addingTimeInterval(180)
                Radar.startTrip(options: tripOptions, trackingOptions: trackingOptions)
            }

            StyledButton("Delivery complete (next leg)") {
                let nextIndex = currentLegIndex + 1
                guard legs.indices.contains(nextIndex) else {
                    print("No more legs, consider completing trip.")
                    return
                }
                
                // First, complete the current leg to get trip into inactive state
                // This allows us to transition to "started" for the next leg
                Radar.completeTrip { (status, trip, events) in
                    if status == .success {
                        // Now update to the next leg with status "started"
                        self.currentLegIndex = nextIndex
                        let dest = self.legs[self.currentLegIndex]
                        let tripOptions = RadarTripOptions(externalId: self.tripExternalId, destinationGeofenceTag: dest.tag, destinationGeofenceExternalId: dest.externalId)
                        tripOptions.mode = .car
                        Radar.updateTrip(options: tripOptions, status: .started) { (updateStatus, updatedTrip, updateEvents) in
                            if updateStatus == .success {
                                print("Successfully updated to next leg: \(dest.externalId)")
                            } else {
                                print("Failed to update trip: \(Radar.stringForStatus(updateStatus))")
                            }
                        }
                    } else {
                        print("Failed to complete current leg: \(Radar.stringForStatus(status))")
                    }
                }
            }

            StyledButton("completeTrip") {
                Radar.completeTrip()
            }

            StyledButton("mockTracking") {
                let origin = CLLocation(latitude: 40.78382, longitude: -73.97536)
                let destination = CLLocation(latitude: 40.70390, longitude: -73.98670)
                var i = 0
                Radar.mockTracking(
                    origin: origin,
                    destination: destination,
                    mode: .car,
                    steps: 3,
                    interval: 3
                ) { (status, location, events, user) in
                    print("Mock track: status = \(Radar.stringForStatus(status)); location = \(String(describing: location)); events = \(String(describing: events)); user = \(String(describing: user))")
                    
                    if (i == 2) {
                        Radar.completeTrip()
                    }
                    
                    i += 1
                }
            }
        }
    }
}

#Preview {
    TestsView()
}
