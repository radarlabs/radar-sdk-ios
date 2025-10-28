//
//  LogsView.swift
//  Example
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import SwiftUI
import RadarSDK

struct LogsView: View {
    @StateObject var state: ViewState
    
    var body: some View {
        VStack {
            HStack {
                Text("Logs")
                Button("clear") {
                    state.logs.removeAll()
                }
            }
            List(state.logs, id:\.0) { item in
                return Text("\(item.1)")
            }

            HStack {
                Text("Events")
                Button("clear") {
                    state.events.removeAll()
                }
            }
            List(state.events, id:\.self) { item in
                let type = RadarEvent.string(for: item.type) ?? "unknown-type"
                var description = ""
                if let geofence = item.geofence {
                    description = geofence.externalId ?? ""
                }
                return Text("\(type): \(description)")
            }

        }
    }
}

#Preview {
    LogsView(state: ViewState())
}
