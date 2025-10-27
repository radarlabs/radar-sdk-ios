//
//  MainView.swift
//  Example
//
//  Created by ShiCheng Lu on 9/5/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import SwiftUI
import RadarSDK

struct MainView: View {
    
    enum TabIdentifier {
        case Map
        case Logs
        case Tests
    }
    
    @State private var selectedTab: TabIdentifier = .Tests;
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MapView().tabItem {
                Text("Map")
            }.tag(TabIdentifier.Map)
            
            LogsView().tabItem {
                Text("Debug")
            }.tag(TabIdentifier.Logs)

            TestsView().tabItem {
                Text("Tests")
            }.tag(TabIdentifier.Tests)
        }
    }
}

#Preview {
    MainView()
}
