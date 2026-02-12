//
//  LogsView.swift
//  Example
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import SwiftUI
import RadarSDK

struct LogsView: View {
    
    @ObservedObject var radarDelegateState: RadarDelegateState
    
    enum TabIdentifier {
        case Logs
        case IndoorLogs
        case Events
    }
    
    @State private var selectedTab: TabIdentifier = .IndoorLogs;
    
    var body: some View {
        TabView(selection: $selectedTab) {
            VStack {
                HStack {
                    Text("Logs")
                    Button("clear") {
                        radarDelegateState.logs.removeAll()
                    }
                }
                List(radarDelegateState.logs, id:\.0) { item in
                    Text("\(item.1)")
                }
            }.tabItem {
                Text("Logs")
            }.tag(TabIdentifier.Logs)
            
            VStack {
                HStack {
                    Text("Indoor Logs")
                    Button("clear") {
                        radarDelegateState.indoorLogs.removeAll()
                    }
                }
                List(Array(radarDelegateState.indoorLogs.enumerated()), id: \.offset) { index, item in
                    Text(item)
                }
            }.tabItem {
                Text("IndoorLogs")
            }.tag(TabIdentifier.IndoorLogs)
            
            VStack {
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
                
            }.tabItem {
                Text("Events")
            }.tag(TabIdentifier.Events)
        }
    }
}

#Preview {
    let radarDelegateState = RadarDelegateState()
    let radarDelegate = MyRadarDelegate()
    
    LogsView(radarDelegateState: radarDelegateState).onAppear {
        radarDelegate.state = radarDelegateState
        Radar.setDelegate(radarDelegate)
    }
}
