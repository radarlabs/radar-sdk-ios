//
//  MainView.swift
//  Example
//
//  Created by ShiCheng Lu on 9/5/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import SwiftUI
import MapKit
import RadarSDK

struct MainView: View {
    
    enum TabIdentifier {
        case Map
        case Debug
        case Tests
    }
    
    @State var monitoringRegions: [CLCircularRegion] = [];
    @State var pendingNotifications: [UNNotificationRequest] = [];
    @State private var selectedTab: TabIdentifier = .Tests;
    
    var regionListFont = {
        if #available(iOS 15.0, *) {
            Font.system(size: 12).monospaced()
        } else {
            Font.system(size: 12)
        }
    }()
    
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    func getMonitoredRegions() {
        monitoringRegions = Array(CLLocationManager().monitoredRegions) as? [CLCircularRegion] ?? []
    }
    
    func getPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            pendingNotifications = requests
        }
    }
    
    
    var body: some View {
        TabView(selection: $selectedTab) {
            if #available(iOS 17.0, *) {
                Map(initialPosition: .userLocation(fallback: .automatic)) {
                    UserAnnotation()
                    ForEach(monitoringRegions, id:\.self) {region in
                        let color = region.identifier.contains("bubble") ? Color.blue : Color.orange
                        MapCircle(center: region.center, radius: region.radius)
                            .foregroundStyle(color.opacity(0.2))
                            .stroke(color, lineWidth: 2)
                            
                    }
                }.onAppear {
                    
                }.tabItem {
                    Text("Map")
                }.tag(TabIdentifier.Map)
            } else {
                // Fallback on earlier versions
                Text("Map unavailable")
                    .tabItem { Text("Map") }
                    .tag(TabIdentifier.Map)
            }
            
            VStack {
                Text("logs/events will go here")
                ScrollView {
                    ForEach(monitoringRegions, id:\.self) {region in
                        Text(region.identifier)
                    }
                }
                
                StyledButton("refresh") {
                    getMonitoredRegions()
                    getPendingNotifications()
                }.onReceive(timer) { _ in
                    getMonitoredRegions()
                    getPendingNotifications()
                }
            }.tabItem {
                Text("Debug")
            }.tag(TabIdentifier.Debug)

            TestsView()
            .tabItem {
                Text("Tests")
            }.tag(TabIdentifier.Tests)
        }
        
        
        
    }
}

#Preview {
    if #available(iOS 15.0, *) {
        MainView()
    } else {
        // Fallback on earlier versions
    }
}
