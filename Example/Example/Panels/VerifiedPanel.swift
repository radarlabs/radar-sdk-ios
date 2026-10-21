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
                Radar.setExpectedJurisdiction(countryCode: "CA", stateCode: nil)
                Radar.trackVerified { (status, token) in
                    let tokenDesc = token?.dictionaryValue().description ?? "no token"
                    logStream.write(
                        status,
                        summary: "trackVerified: \(Radar.stringForStatus(status))",
                        detail: tokenDesc
                    )
                }
            }
            ActionButton("trackVerified (beacons)") {
                let start = Date()
                Radar.trackVerified(beacons: true, desiredAccuracy: .medium) { (status, token) in
                    let elapsed = Int(Date().timeIntervalSince(start) * 1000)
                    let beacons = token?.user?.beacons ?? []
                    let beaconDesc = beacons.map { "\($0.__description ?? $0._id ?? "beacon") (\($0.uuid) \($0.major)/\($0.minor))" }
                    logStream.write(
                        status,
                        summary: "trackVerified (beacons): \(Radar.stringForStatus(status)) in \(elapsed) ms, \(beacons.count) beacons",
                        detail: beaconDesc.joined(separator: "\n")
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
                    let tokenDesc = token?.dictionaryValue().description ?? "no token"
                    logStream.write(
                        status,
                        summary: "revealRisk: \(Radar.stringForStatus(status))",
                        detail: tokenDesc
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
