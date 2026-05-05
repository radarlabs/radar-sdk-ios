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
                consoleSection
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
            Text("Presets").font(.headline)
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 110), spacing: 8)],
                alignment: .leading,
                spacing: 8
            ) {
                ForEach(TestPreset.all) { preset in
                    Button {
                        apply(preset)
                    } label: {
                        Text(preset.name)
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(isActive(preset) ? Color.accentColor : Color(.tertiarySystemFill))
                            .foregroundColor(isActive(preset) ? .white : .primary)
                            .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                }
            }
            if let active = TestPreset.all.first(where: { $0.id == settingsStore.activePresetId }) {
                Text(active.summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func isActive(_ preset: TestPreset) -> Bool {
        preset.id == settingsStore.activePresetId
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
            ControlRow("Source") {
                Text(settingsStore.isUsingRemoteOptions ? "Remote (server)" : "Local")
                    .foregroundColor(settingsStore.isUsingRemoteOptions ? .blue : .secondary)
            }
            ControlRow("Configured") {
                Text(settingsStore.trackingOptionsSummary)
            }
        }
    }
    
    private var consoleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Console").font(.headline)
                Spacer()
                if !outputText.isEmpty {
                    Button("Clear") { outputText = "" }
                        .font(.caption)
                        .buttonStyle(.borderless)
                }
            }
            Group {
                if outputText.isEmpty {
                    Text("Output from notification-permission and pending-request actions appears here. (Step 6 wires every action to a real in-app console.)")
                        .font(.callout)
                        .foregroundColor(.secondary)
                } else {
                    Text(outputText)
                        .font(.system(.body, design: .monospaced))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
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
