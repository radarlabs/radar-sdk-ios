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
    }
    
    @State private var selectedTab: TabIdentifier = .Tests;
    
    var body: some View {
        TabView(selection: $selectedTab) {
//            MapView().tabItem {
//                Text("Map")
//            }.tag(TabIdentifier.Map)
            
            DebugView().tabItem {
                Text("Debug")
            }.tag(TabIdentifier.Debug)
            
            LogsView().tabItem {
                Text("Logs")
            }.tag(TabIdentifier.Logs)

//            TestsView().tabItem {
//                Text("Tests")
//            }.tag(TabIdentifier.Tests)
        }
    }
}

//#Preview {
//    MainView()
//}
