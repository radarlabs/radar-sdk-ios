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
                    logStream.writeVerifiedResponse(
                        status,
                        action: "getVerifiedLocationToken",
                        response: token.map(VerifiedResponse.init)
                    )
                }
            }
            ActionButton("clearVerifiedLocationToken") {
                Radar.clearVerifiedLocationToken()
                logStream.write(result: "Verified token cache cleared; the next token request will fetch a fresh response.")
            }
            ActionButton("trackVerified") {
                Radar.trackVerified { (status, token) in
                    logStream.writeVerifiedResponse(
                        status,
                        action: "trackVerified",
                        response: token.map(VerifiedResponse.init)
                    )
                }
            }
            ActionButton("trackVerified (options)") {
                // Exercises trackVerified(options:completionHandler:).
                let options = RadarTrackVerifiedOptions()
                options.reason = "example"
                options.transactionId = "example-tx"
                Radar.trackVerified(options: options) { (status, token) in
                    logStream.writeVerifiedResponse(
                        status,
                        action: "trackVerified (options)",
                        response: token.map(VerifiedResponse.init)
                    )
                }
            }
            ActionButton("trackVerified (beacons)") {
                let start = Date()
                Radar.trackVerified(beacons: true, desiredAccuracy: .medium) { (status, token) in
                    let elapsed = Int(Date().timeIntervalSince(start) * 1000)
                    logStream.writeVerifiedResponse(
                        status,
                        action: "trackVerified (beacons)",
                        response: token.map(VerifiedResponse.init),
                        elapsedMilliseconds: elapsed,
                        includeBeacons: true
                    )
                }
            }
            ActionButton("startRangingBeacons", style: .primary) {
                Radar.startRangingBeacons()
                logStream.write(.success, summary: "startRangingBeacons")
            }
            ActionButton("stopRangingBeacons", style: .destructive) {
                Radar.stopRangingBeacons()
                logStream.write(.success, summary: "stopRangingBeacons")
            }
            ActionButton("revealRisk") {
                Radar.revealRisk { (status, token) in
                    logStream.writeVerifiedResponse(
                        status,
                        action: "revealRisk",
                        response: token.map(VerifiedResponse.init)
                    )
                }
            }
            ActionButton("setExpectedAddress") {
                Radar.setExpectedAddress("111 5th Ave, NY")
            }
            ActionButton("setExpectedJurisdiction") {
                Radar.setExpectedJurisdiction(countryCode: "US", stateCode: "CA")
            }
            ActionButton("isSharing") {
                let x = Radar.isSharing()
                logStream.write(.success, summary: "isSharing: \(x)")
            }
            ActionButton("clearSharing") {
                Radar.clearSharing()
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
