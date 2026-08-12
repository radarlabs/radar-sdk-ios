//
//  VerifiedPanel.swift
//  Example
//
//  Created by Alan Charles on 5/5/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import RadarSDK
import SwiftUI

struct VerifiedPanel: View {
    @EnvironmentObject var logStream: LogStream

    var body: some View {
        TogglePanel("Verified", initiallyExpanded: false) {
            ActionButton("startTrackingVerified", style: .primary) {
                Radar.startTrackingVerified(interval: 60, beacons: false)
            }
            ActionButton("stopTrackingVerified", style: .destructive) {
                Radar.stopTrackingVerified()
            }
            ActionButton("getVerifiedLocationToken") {
                Radar.getVerifiedLocationToken { (status, token) in
                    let tokenDesc = token?.dictionaryValue().description ?? "no token"
                    logStream.write(
                        status,
                        summary: "getVerifiedLocationToken: \(Radar.stringForStatus(status))",
                        detail: tokenDesc
                    )
                }
            }
            ActionButton("trackVerified") {
                Radar.trackVerified { (status, token) in
                    let tokenDesc = token?.dictionaryValue().description ?? "no token"
                    logStream.write(
                        status,
                        summary: "trackVerified: \(Radar.stringForStatus(status))",
                        detail: tokenDesc
                    )
                }
            }
            ActionButton("revealRisk") {
                Radar.revealRisk { (status, token) in
                    let tokenDesc = token?.dictionaryValue().description ?? "no token"
                    logStream.write(
                        status,
                        summary: "revealRisk: \(Radar.stringForStatus(status))",
                        detail: tokenDesc
                    )
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        VerifiedPanel().padding()
    }
    .environmentObject(LogStream())
}
