//
//  MainView.swift
//  Example
//
//  Created by ShiCheng Lu on 9/5/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import SwiftUI
import RadarSDK

class ViewState: ObservableObject {
    @Published var logs: [(Int, String)] = []
    @Published var events: [RadarEvent] = []
    @Published var user: RadarUser? = nil
    @Published var lastTrackedLocation: CLLocation? = nil
    @Published var monitoringRegions = [CLCircularRegion]()
    @Published var pendingNotifications = [UNNotificationRequest]()
}

struct MainView: View {
    
    enum TabIdentifier {
        case Map
        case Debug
        case Logs
        case Tests
    }
    
    @State private var selectedTab: TabIdentifier = .Tests;
    var state = ViewState()
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    let radarDelegate = MyRadarDelegate()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MapView(state: state).tabItem {
                Text("Map")
            }.tag(TabIdentifier.Map)
            
            DebugView(state: state).tabItem {
                Text("Debug")
            }.tag(TabIdentifier.Debug)
            
            LogsView(state: state).tabItem {
                Text("Logs")
            }.tag(TabIdentifier.Logs)

            TestsView().tabItem {
                Text("Tests")
            }.tag(TabIdentifier.Tests)
        }.onAppear {
            radarDelegate.state = self.state
            Radar.setDelegate(radarDelegate)
        }.onReceive(timer) { _ in
            state.monitoringRegions = Array(CLLocationManager().monitoredRegions) as? [CLCircularRegion] ?? []
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                DispatchQueue.main.async {
                    state.pendingNotifications = requests
                }
            }
        }
    }
}

#Preview {
    MainView()
}
