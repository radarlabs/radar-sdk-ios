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
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MyMapView(withRadar: "prj_test_pk_3508428416f485c5f54d8e8bb1f616ee405b1995").tabItem {
                Text("Map")
            }.tag(TabIdentifier.Map)
            
            DebugView().tabItem {
                Text("Debug")
            }.tag(TabIdentifier.Debug)
            
            LogsView().tabItem {
                Text("Logs")
            }.tag(TabIdentifier.Logs)
            
            SettingsView().tabItem {
                Text("Settings")
            }.tag(TabIdentifier.Settings)
            
//            TestsView().tabItem {
//                Text("Tests")
//            }.tag(TabIdentifier.Tests)
        }
    }
}

//#Preview {
//    MainView()
//}
