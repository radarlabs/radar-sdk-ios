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
    
    @StateObject var state: ViewState
    
    var body: some View {
        if #available(iOS 17.0, *) {
            Map(initialPosition: .userLocation(fallback: .automatic)) {
                UserAnnotation()
                
                ForEach(state.monitoringRegions, id:\.self) {region in
                    let color = region.identifier.contains("bubble") ? Color.blue : Color.orange
                    MapCircle(center: region.center, radius: region.radius)
                        .foregroundStyle(color.opacity(0.2))
                        .stroke(color, lineWidth: 2)
                    
                }
                ForEach(state.pendingNotifications, id:\.self) {request in
                    if let trigger = request.trigger as? UNLocationNotificationTrigger,
                       let region = trigger.region as? CLCircularRegion {
                        let color = Color.green
                        MapCircle(center: region.center, radius: region.radius)
                            .foregroundStyle(color.opacity(0.2))
                            .stroke(color, lineWidth: 2)
                    }
                }
            }
        } else {
            // Map with SwiftUI is not available before iOS 17
            Text("Map unavailable")
        }
    }
}

#Preview {
    MapView(state: ViewState())
}
