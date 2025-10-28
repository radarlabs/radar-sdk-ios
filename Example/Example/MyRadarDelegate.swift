//
//  MyRadarDelegate.swift
//  Example
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import RadarSDK

class MyRadarDelegate: NSObject, RadarDelegate, ObservableObject {
    var state: ViewState? = nil
    
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
