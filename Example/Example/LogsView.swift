//
//  LogsView.swift
//  Example
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import SwiftUI
import RadarSDK

struct LogsView: View {
    @StateObject var radarDelegateState = RadarDelegateState()
    let radarDelegate = MyRadarDelegate()
    
    var body: some View {
        VStack {
            HStack {
                Text("Logs")
                Button("clear") {
                    radarDelegateState.logs.removeAll()
                }
            }
            List(radarDelegateState.logs, id:\.0) { item in
                return Text("\(item.1)")
            }

            HStack {
                Text("Events")
                Button("clear") {
                    radarDelegateState.events.removeAll()
                }
            }
            List(radarDelegateState.events, id:\.self) { item in
                let type = RadarEvent.string(for: item.type) ?? "unknown-type"
                var description = ""
                if let geofence = item.geofence {
                    description = geofence.externalId ?? ""
                }
                return Text("\(type): \(description)")
            }

        }.onAppear {
            radarDelegate.state = radarDelegateState
            Radar.setDelegate(radarDelegate)
        }
    }
}

#Preview {
    LogsView()
}
