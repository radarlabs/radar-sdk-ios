//
//  MainView.swift
//  Example
//
//  Created by ShiCheng Lu on 9/5/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import SwiftUI
import RadarSDK

@available(iOS 15.0, *)
struct MainView: View {
    
    @State var monitoringRegions: [CLRegion] = [];
    @State var pendingNotifications: [String] = [];
    
    let regionListFont = Font.system(size: 12).monospaced()
    
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    func getMonitoredRegions() {
        monitoringRegions = Array(CLLocationManager().monitoredRegions)
    }
    
    func getPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            pendingNotifications = requests.map {
                $0.identifier
            }
        }
    }
    
    var body: some View {
        Text("Monitoring regions:")
        List(monitoringRegions, id: \.self) { region in
            HStack {
                Text(region.identifier).font(regionListFont)
                Button("X") {
                    CLLocationManager().stopMonitoring(for: region)
                    getMonitoredRegions()
                }
            }
        }
        
        Text("Pending notifications:")
        List(pendingNotifications, id: \.self) { identifier in
            HStack {
                Text(identifier).font(regionListFont)
                Button("X") {
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
                    getPendingNotifications()
                }
            }
        }
        
    
        Button("trackOnce") {
            Radar.trackOnce()
        }
        
        Button("startTracking") {
            Radar.startTracking(trackingOptions: .presetResponsive)
        }
        
        Text("").onReceive(timer) { _ in
            getMonitoredRegions()
            getPendingNotifications()
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
