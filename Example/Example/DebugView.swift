//
//  DebugView.swift
//  Example
//
//  Created by ShiCheng Lu on 10/22/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import SwiftUI
import RadarSDK

struct DebugView: View {
    var regionListFont = {
        if #available(iOS 15.0, *) {
            Font.system(size: 12).monospaced()
        } else {
            Font.system(size: 12)
        }
    }()
    
    @State var monitoringRegions: [CLCircularRegion] = [];
    @State var pendingNotifications: [UNNotificationRequest] = [];
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            Text("Monitoring regions: \(monitoringRegions.count)")
            List(monitoringRegions, id: \.self) { region in
                HStack {
                    Text(region.identifier).font(regionListFont)
                    Button("X") {
                        CLLocationManager().stopMonitoring(for: region)
                    }
                }
            }
            
            Text("Pending notifications: \(pendingNotifications.count)")
            List(pendingNotifications, id: \.self) { notification in
                HStack {
                    Text(notification.identifier).font(regionListFont)
                    Button("X") {
                        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notification.identifier])
                    }
                }
            }.onReceive(timer) { _ in
                monitoringRegions = Array(CLLocationManager().monitoredRegions) as? [CLCircularRegion] ?? []
                UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                    pendingNotifications = requests
                }
            }
        }
    }
}

#Preview {
    DebugView()
}
