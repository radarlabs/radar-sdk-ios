//
//  MyRadarDelegate.swift
//  Example
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import RadarSDK

class RadarDelegateState: ObservableObject {
    @Published var logs: [(Int, String)] = []
    @Published var events: [RadarEvent] = []
    @Published var user: RadarUser? = nil
    @Published var lastTrackedLocation: CLLocation? = nil
    @Published var clientLocation: CLLocation? = nil
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
        if source == .indoors {
            DispatchQueue.main.async {
                self.state?.clientLocation = location
            }
        }
    }

    func didFail(status: RadarStatus) {

    }

    func didLog(message: String) {
        if let state {
            state.logs.append((state.logs.count, message))
        }
    }
}
