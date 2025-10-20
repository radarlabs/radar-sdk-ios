//
//  MyRadarDelegate.swift
//  Example
//
//  Created by ShiCheng Lu on 10/20/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import RadarSDK

class RadarDelegateState: ObservableObject {
    @Published var logs: [(Int, String)] = []
    @Published var events: [RadarEvent] = []
    @Published var user: RadarUser? = nil
    @Published var lastTrackedLocation: CLLocation? = nil
}

class MyRadarDelegate: NSObject, RadarDelegate, ObservableObject {
    var state: RadarDelegateState? = nil
    
    func didReceiveEvents(_ events: [RadarEvent], user: RadarUser?) {
        state?.events.append(contentsOf: events)
        state?.user = user
    }
    
    func didUpdateLocation(_ location: CLLocation, user: RadarUser) {
        state?.lastTrackedLocation = location
        state?.user = user
    }
    
    func didUpdateClientLocation(_ location: CLLocation, stopped: Bool, source: RadarLocationSource) {
        
    }
    
    func didFail(status: RadarStatus) {
        
    }
    
    func didLog(message: String) {
        state?.logs.append((state?.logs.count ?? 0, message))
    }
}
