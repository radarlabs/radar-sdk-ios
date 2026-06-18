//
//  TrackingSectionView.swift
//  Example
//
//  Created by Alan Charles on 5/14/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import SwiftUI

/// Tracking status snapshot: on/off, local vs remote, configured-options summary.
struct TrackingSectionView: View {
    @ObservedObject var settingsStore: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tracking").font(.headline)
                Spacer()
                Button("Refresh") {
                    settingsStore.refresh()
                }
                .font(.caption)
                .buttonStyle(.borderless)
            }
            ControlRow("Status") {
                Text(settingsStore.isTracking ? "On" : "Off")
                    .foregroundColor(settingsStore.isTracking ? .green : .secondary)
            }
            ControlRow("Source") {
                Text(settingsStore.isUsingRemoteOptions ? "Remote (server)" : "Local")
                    .foregroundColor(settingsStore.isUsingRemoteOptions ? .blue : .secondary)
            }
            ControlRow("Configured") {
                Text(settingsStore.trackingOptionsSummary)
            }
        }
    }
}
