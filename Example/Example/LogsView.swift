//
//  LogsView.swift
//  Example
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import SwiftUI
import RadarSDK

struct LogsView: View {
    @EnvironmentObject var logStream: LogStream
    
    var body: some View {
        VStack {
            HStack {
                Text("Logs")
                Button("clear") { logStream.clearLogs() }
            }
            List(logStream.logs) { entry in
                Text(entry.message)
            }
            
            HStack {
                Text("Events")
                Button("clear") { logStream.clearEvents() }
            }
            List(logStream.events, id: \.self) { event in
                let type = RadarEvent.string(for: event.type) ?? "unknown-type"
                let description = event.geofence?.externalId ?? ""
                Text("\(type): \(description)")
            }
        }
    }
}

#Preview {
    LogsView()
        .environmentObject(LogStream())
}
