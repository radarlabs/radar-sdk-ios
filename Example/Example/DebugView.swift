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
    @StateObject var state: ViewState
    
    var regionListFont = {
        if #available(iOS 15.0, *) {
            Font.system(size: 12).monospaced()
        } else {
            Font.system(size: 12)
        }
    }()
    
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            Text("Monitoring regions: \(state.monitoringRegions.count)")
            List(state.monitoringRegions, id: \.self) { region in
                HStack {
                    Text(region.identifier).font(regionListFont)
                    Button("X") {
                        CLLocationManager().stopMonitoring(for: region)
                    }
                }
            }
            
            Text("Pending notifications: \(state.pendingNotifications.count)")
            List(state.pendingNotifications, id: \.self) { notification in
                HStack {
                    Text(notification.identifier).font(regionListFont)
                    Button("X") {
                        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notification.identifier])
                    }
                }
            }
        }
    }
}

#Preview {
    DebugView(state: ViewState())
}
