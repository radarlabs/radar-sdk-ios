//
//  TestsView.swift
//  Example
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import SwiftUI
import RadarSDK

struct TestsView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @Binding var selectedTab: MainView.TabIdentifier
    @State private var outputText: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                presetSection
                trackingSection
                Divider().padding(.vertical, 4)
                Text(outputText)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                TrackingPanel()
                TripsPanel()
                VerifiedPanel()
                SearchPanel()
                NotificationsPanel(outputText: $outputText)
                MessagingPanel()
            }
            .padding()
        }
    }
    
    // MARK: - Sections
    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preset").font(.headline)
            ForEach(TestPreset.all) { preset in
                Button {
                    apply(preset)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(preset.name).font(.body.weight(.medium))
                        Text(preset.summary)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.tertiarySystemFill))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var trackingSection: some View {
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
            ControlRow("Configured") {
                Text(settingsStore.trackingOptionsSummary)
            }
        }
    }
    
    // MARK: - Actions
    private func apply(_ preset: TestPreset) {
        settingsStore.apply(preset)
        if let raw = preset.suggestedTabRaw,
           let tab = MainView.TabIdentifier(rawValue: raw) {
            selectedTab = tab
        }
    }
}

#Preview {
    TestsView(selectedTab: .constant(.Tests))
        .environmentObject(SettingsStore())
}
