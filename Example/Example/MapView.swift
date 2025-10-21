//
//  MapView.swift
//  Example
//
//  Created by ShiCheng Lu on 10/21/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import SwiftUI
import MapKit

struct MapView: View {
    
    @State var monitoringRegions: [CLCircularRegion] = [];
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        if #available(iOS 17.0, *) {
            Map(initialPosition: .userLocation(fallback: .automatic)) {
                UserAnnotation()
                
                ForEach(monitoringRegions, id:\.self) {region in
                    let color = region.identifier.contains("bubble") ? Color.blue : Color.orange
                    MapCircle(center: region.center, radius: region.radius)
                        .foregroundStyle(color.opacity(0.2))
                        .stroke(color, lineWidth: 2)
                    
                }
            }.onReceive(timer) { _ in
                monitoringRegions = Array(CLLocationManager().monitoredRegions) as? [CLCircularRegion] ?? []
            }
        } else {
            // Map with SwiftUI is not available before iOS 17
            Text("Map unavailable")
        }
    }
}
