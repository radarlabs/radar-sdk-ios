//
//  TripsPanel.swift
//  Example
//
//  Created by Alan Charles on 5/5/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import RadarSDK
import SwiftUI

struct TripsPanel: View {
    var body: some View {
        TogglePanel("Trips", initiallyExpanded: false) {
            ActionButton("startTrip", style: .primary) {
                let tripOptions = RadarTripOptions(externalId: "300", destinationGeofenceTag: "a", destinationGeofenceExternalId: "a")
                tripOptions.mode = .car
                tripOptions.approachingThreshold = 9
                Radar.startTrip(options: tripOptions)
            }
            ActionButton("startTrip (startTracking: false)") {
                let tripOptions = RadarTripOptions(externalId: "301", destinationGeofenceTag: "store", destinationGeofenceExternalId: "123", scheduledArrivalAt: nil, startTracking: false)
                tripOptions.mode = .car
                tripOptions.approachingThreshold = 9
                Radar.startTrip(options: tripOptions)
            }
            ActionButton("startTrip (with tracking options)") {
                let uniqueTripId = "trip_\(Int(Date().timeIntervalSince1970))"
                let tripOptions = RadarTripOptions(
                    externalId: uniqueTripId, destinationGeofenceTag: "trip_activity", destinationGeofenceExternalId: "trip12345", scheduledArrivalAt: nil, startTracking: false)
                tripOptions.mode = .car
                tripOptions.approachingThreshold = 9
                let trackingOptions = RadarTrackingOptions.presetContinuous
                Radar.startTrip(options: tripOptions, trackingOptions: trackingOptions)
            }
            ActionButton("startTrip (with startTrackingAfter)") {
                let tripOptions = RadarTripOptions(externalId: "303", destinationGeofenceTag: "store", destinationGeofenceExternalId: "123", scheduledArrivalAt: nil)
                tripOptions.startTracking = false
                tripOptions.mode = .car
                tripOptions.approachingThreshold = 9
                let trackingOptions = RadarTrackingOptions.presetContinuous
                trackingOptions.startTrackingAfter = Date().addingTimeInterval(180)
                Radar.startTrip(options: tripOptions, trackingOptions: trackingOptions)
            }
            ActionButton("completeTrip") {
                Radar.completeTrip()
            }
        }
    }
}

#Preview {
    ScrollView {
        TripsPanel().padding()
    }
    .environmentObject(LogStream())
}
