//
//  MyRadarDelegate.swift
//  Example
//
//  Created by ShiCheng Lu on 10/9/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation
import RadarSDK

class MyRadarDelegate: NSObject, RadarDelegate {
    
    @Published var events: [RadarEvent] = []
    @Published var user: RadarUser? = nil
    
    func didReceiveEvents(_ events: [RadarEvent], user: RadarUser?) {
        self.events.append(contentsOf: events)
        print("EVENT SENT")
    }
    
    func didUpdateLocation(_ location: CLLocation, user: RadarUser) {
        print("LOCATION SENT")
    }
    
    func didUpdateClientLocation(_ location: CLLocation, stopped: Bool, source: RadarLocationSource) {
        print("CLIENT LOCATION SENT")
    }
    
    func didFail(status: RadarStatus) {
        
    }
    
    func didLog(message: String) {
        
    }
}
