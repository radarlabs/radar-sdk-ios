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
    
    @State var monitoringRegions: [CLRegion] = [];
    @State var pendingNotifications: [UNNotificationRequest] = [];
    
    var regionListFont = {
        if #available(iOS 15.0, *) {
            Font.system(size: 12).monospaced()
        } else {
            Font.system(size: 12)
        }
    }()
    
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    func getMonitoredRegions() {
        monitoringRegions = Array(CLLocationManager().monitoredRegions)
    }
    
    func getPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            pendingNotifications = requests
        }
    }
    
    var body: some View {
        TabView() {
            if #available(iOS 17.0, *) {
                Map {
                    UserAnnotation()
                    
                    ForEach(monitoringRegions, id:\.self) {region in
    //                    MapCircle(center: region.center, radius: region.radius)
                    }
                }.tabItem {
                    Text("Map")
                }
            } else {
                // Fallback on earlier versions
                Text("Map unavailable").tabItem { Text("Map") }
            }

            VStack {
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
                List(pendingNotifications, id: \.self) { notification in
                    HStack {
                        Text(notification.identifier).font(regionListFont)
                        Button("X") {
                            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notification.identifier])
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
                
                Button("stopTracking") {
                    Radar.stopTracking()
                }
                
                Button("refresh") {
                    getMonitoredRegions()
                    getPendingNotifications()
                }
                
                Button("test notification") {
                    let content = UNMutableNotificationContent()
                    content.body = "Test"
                    content.sound = UNNotificationSound.default
                    content.categoryIdentifier = "example"

                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                    UNUserNotificationCenter.current().add(request, withCompletionHandler: { (_) in })
                }
                
                Text("").onReceive(timer) { _ in
                    getMonitoredRegions()
                    getPendingNotifications()
                }
            }.tabItem {
                Text("Tests")
            }
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
