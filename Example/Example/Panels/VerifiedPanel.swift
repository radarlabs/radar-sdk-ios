//
//  VerifiedPanel.swift
//  Example
//
//  Created by Alan Charles on 5/5/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import SwiftUI
import RadarSDK

struct VerifiedPanel: View {
    var body: some View {
        TogglePanel("Verified", initiallyExpanded: false) {
            ActionButton("startTrackingVerified", style: .primary) {
                Radar.startTrackingVerified(interval: 60, beacons: false)
            }
            ActionButton("stopTrackingVerified", style: .destructive) {
                Radar.stopTrackingVerified()
            }
            ActionButton("getVerifiedLocationToken") {
                Radar.getVerifiedLocationToken() { (status, token) in
                    let tokenDesc = token?.dictionaryValue().description ?? "unable to get token"
                    print("getVerifiedLocationToken: status = \(status); token = \(tokenDesc)")
                }
            }
            ActionButton("trackVerified") {
                Radar.trackVerified() { (status, token) in
                    let tokenDesc = token?.dictionaryValue().description ?? "unable to get token"
                    print("TrackVerified: status = \(status); token = \(tokenDesc)")
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        VerifiedPanel().padding()
    }
}
