//
//  MainView.swift
//  Example
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import SwiftUI
import RadarSDK

struct MainView: View {
    
    enum TabIdentifier {
        case Map
        case Debug
        case Logs
        case Tests
        case Settings
    }
    
    @State private var selectedTab: TabIdentifier = .Debug;
    
    @StateObject var radarDelegateState = RadarDelegateState()
    let radarDelegate = MyRadarDelegate()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MyMapView(withRadar: "").tabItem {
                Text("Map")
            }.tag(TabIdentifier.Map)
            
            DebugView(radarDelegateState: radarDelegateState).tabItem {
                Text("Debug")
            }.tag(TabIdentifier.Debug)
            
            LogsView(radarDelegateState: radarDelegateState).tabItem {
                Text("Logs")
            }.tag(TabIdentifier.Logs)
            
            SettingsView().tabItem {
                Text("Settings")
            }.tag(TabIdentifier.Settings)
            
            TestsView().tabItem {
                Text("Tests")
            }.tag(TabIdentifier.Tests)
        }.onAppear {
            radarDelegate.state = radarDelegateState
            Radar.setDelegate(radarDelegate)
        }
    }
}

//#Preview {
//    MainView()
//}
