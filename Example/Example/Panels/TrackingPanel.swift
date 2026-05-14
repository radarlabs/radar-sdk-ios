//
//  TrackingPanel.swift
//  Example
//
//  Created by Alan Charles on 5/5/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import RadarSDK
import SwiftUI

struct TrackingPanel: View {
    @EnvironmentObject var logStream: LogStream

    var body: some View {
        TogglePanel("Tracking") {
            ActionButton("trackOnce") {
                Radar.trackOnce()
            }
            ActionButton("startTracking (responsive)", style: .primary) {
                Radar.startTracking(trackingOptions: .presetResponsive)
            }
            ActionButton("startTracking (continuous)", style: .primary) {
                Radar.startTracking(trackingOptions: .presetContinuous)
            }
            ActionButton("stopTracking", style: .destructive) {
                Radar.stopTracking()
            }
            ActionButton("getContext") {
                Radar.getContext { (status, location, context) in
                    let detail = """
                        location: \(String(describing: location))
                        geofences: \(String(describing: context?.geofences))
                        place: \(String(describing: context?.place))
                        country: \(String(describing: context?.country))
                        """
                    logStream.write(
                        status,
                        summary: "getContext: \(Radar.stringForStatus(status))",
                        detail: detail
                    )
                }
            }
            ActionButton("mockTracking") {
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
                    let detail = """
                        location: \(String(describing: location))
                        events: \(String(describing: events))
                        user: \(String(describing: user))
                        """
                    logStream.write(
                        status,
                        summary: "mockTracking: \(Radar.stringForStatus(status))",
                        detail: detail
                    )
                    if i == 2 {
                        Radar.completeTrip()
                    }
                    i += 1
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        TrackingPanel().padding()
    }
    .environmentObject(LogStream())
}
