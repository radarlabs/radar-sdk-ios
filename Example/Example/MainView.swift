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
    
    @State var monitoringRegions: [String] = [];
    @State var pendingNotifications: [String] = [];
    
    let regionListFont = Font.system(size: 13).monospaced()
    
    
    var body: some View {
        Text("Monitoring regions:")
        List(monitoringRegions, id: \.self) { region in
            Text(region).font(regionListFont)
        }
        
        Text("Pending notifications:")
        List(pendingNotifications, id: \.self) { region in
            Text(region).font(regionListFont)
        }
        
    
        Button("trackOnce") {
            Radar.trackOnce() { _,_,_,_ in
                monitoringRegions = CLLocationManager().monitoredRegions.map {
                    region in region.identifier
                }
            }
        }
        
        Button("startTracking") {
            Radar.startTracking(trackingOptions: .presetResponsive)
        }
        
        Button("listMonitoring regions") {
            monitoringRegions = CLLocationManager().monitoredRegions.map {
                region in region.identifier
            }
        }
        
        Button("list pending notifications") {
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                pendingNotifications = requests.map {
                    $0.identifier
                }
            }
        }
        
        Button("remove all pending notifications") {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: pendingNotifications)
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
