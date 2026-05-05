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
    @EnvironmentObject var logStream: LogStream
    @Binding var selectedTab: MainView.TabIdentifier
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                presetSection
                trackingSection
                Divider().padding(.vertical, 4)
                recentActivitySection
                TrackingPanel()
                TripsPanel()
                VerifiedPanel()
                SearchPanel()
                NotificationsPanel()
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
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recent activity").font(.headline)
                Spacer()
                Button("View all") {
                    selectedTab = .Logs
                }
                .font(.caption)
                .buttonStyle(.borderless)
                .disabled(logStream.entries.isEmpty)
            }
            
            Group {
                if logStream.entries.isEmpty {
                    Text("Tap an action below to see it flow through the console.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(logStream.entries.reversed().prefix(5))) { entry in
                            HStack(spacing: 8) {
                                Image(systemName: entry.kind.iconName)
                                    .foregroundColor(entry.kind.tintColor)
                                    .frame(width: 14)
                                Text(entry.summary)
                                    .font(.caption)
                                    .lineLimit(1)
                                Spacer(minLength: 0)
                            }
                        }
                    }
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
        .environmentObject(LogStream())
}
