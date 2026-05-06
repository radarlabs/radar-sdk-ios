//
//  TestsSettingsView.swift
//  Example
//
//  Created by Alan Charles on 5/5/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import SwiftUI
import CoreLocation
import UserNotifications
import RadarSDK

/// Modal configuration view presented from TestsView's gear icon. Houses the
/// four state-management sections (Presets, Identity, Tracking, Permissions)
/// that previously lived inline at the top of TestsView.
///
/// All edits write through to the SettingsStore / SDK immediately — there is
/// no pending state to commit on Done. Done just dismisses the sheet.
struct TestsSettingsView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var permissionsStore: PermissionsStore
    @Environment(\.presentationMode) private var presentationMode
    @State private var isOptionsExpanded: Bool = false
    @State private var isSdkConfigExpanded: Bool = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    presetSection
                    identitySection
                    trackingSection
                    permissionsSection
                }
                .padding()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Preset
    
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
                        settingsStore.apply(preset)
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
            Text(presetStatusText)
                .font(.caption)
                .foregroundColor(.secondary)
            
            DisclosureGroup(isExpanded: $isOptionsExpanded) {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(settingsStore.currentTrackingFields) { field in
                        HStack(alignment: .firstTextBaseline) {
                            Text(field.label)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                            Spacer(minLength: 8)
                            Text(field.value)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(color(for: field))
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
                .padding(.top, 4)
            } label: {
                Text("Active tracking options")
                    .font(.subheadline.weight(.medium))
            }
            
            DisclosureGroup(isExpanded: $isSdkConfigExpanded) {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(settingsStore.currentSdkConfigFields) { field in
                        HStack(alignment: .firstTextBaseline) {
                            Text(field.label)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                            Spacer(minLength: 8)
                            Text(field.value)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(color(for: field))
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
                .padding(.top, 4)
            } label: {
                Text("SDK configuration")
                    .font(.subheadline.weight(.medium))
            }
        }
    }
    
    private func color(for field: TrackingField) -> Color {
        if case .bool(let v) = field.kind {
            return v ? .green : .secondary
        }
        return .primary
    }
    
    private var presetStatusText: String {
        if let active = TestPreset.all.first(where: { $0.id == settingsStore.activePresetId }) {
            return active.summary
        }
        return "No preset active — manual identity in effect."
    }
    
    private func isActive(_ preset: TestPreset) -> Bool {
        preset.id == settingsStore.activePresetId
    }
    
    // MARK: - Identity
    
    private var identitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Identity").font(.headline)
            FieldEditor("User ID", text: $settingsStore.userId, placeholder: "—", commitOnSubmit: true)
            FieldEditor("Description", text: $settingsStore.userDescription, placeholder: "—", commitOnSubmit: true)
            ControlRow("Metadata") {
                Text(formattedMetadata)
                    .foregroundColor(settingsStore.metadata.isEmpty ? .secondary : .primary)
                    .lineLimit(2)
            }
        }
    }
    
    private var formattedMetadata: String {
        if settingsStore.metadata.isEmpty {
            return "—"
        }
        return settingsStore.metadata
            .sorted(by: { $0.key < $1.key })
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ", ")
    }
    
    // MARK: - Tracking
    
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
    
    // MARK: - Permissions
    
    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Permissions").font(.headline)
                Spacer()
                Button("Refresh") {
                    permissionsStore.refreshNotificationStatus()
                }
                .font(.caption)
                .buttonStyle(.borderless)
            }
            ControlRow("Location") {
                HStack(spacing: 8) {
                    Text(permissionsStore.locationStatus.displayName)
                        .foregroundColor(permissionsStore.locationStatus.displayColor)
                    locationActionButton
                }
            }
            ControlRow("Notifications") {
                HStack(spacing: 8) {
                    Text(permissionsStore.notificationStatus.displayName)
                        .foregroundColor(permissionsStore.notificationStatus.displayColor)
                    notificationActionButton
                }
            }
            ControlRow("Motion") {
                HStack(spacing: 8) {
                    Text("Status not exposed by OS")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Button("Request") {
                        permissionsStore.requestMotionActivity()
                    }
                    .font(.caption)
                    .buttonStyle(.borderless)
                }
            }
        }
    }
    
    @ViewBuilder
    private var locationActionButton: some View {
        switch permissionsStore.locationStatus {
        case .notDetermined:
            Button("Request") { permissionsStore.requestLocation() }
                .font(.caption).buttonStyle(.borderless)
        case .authorizedWhenInUse:
            Button("Request Always") { permissionsStore.requestLocation() }
                .font(.caption).buttonStyle(.borderless)
        case .denied, .restricted:
            Button("Open Settings") { permissionsStore.openSystemSettings() }
                .font(.caption).buttonStyle(.borderless)
        case .authorizedAlways:
            EmptyView()
        @unknown default:
            EmptyView()
        }
    }
    
    @ViewBuilder
    private var notificationActionButton: some View {
        switch permissionsStore.notificationStatus {
        case .notDetermined:
            Button("Request") { permissionsStore.requestNotifications() }
                .font(.caption).buttonStyle(.borderless)
        case .denied:
            Button("Open Settings") { permissionsStore.openSystemSettings() }
                .font(.caption).buttonStyle(.borderless)
        case .authorized, .provisional, .ephemeral:
            EmptyView()
        @unknown default:
            EmptyView()
        }
    }
}

// MARK: - Permission status display helpers

private extension CLAuthorizationStatus {
    var displayName: String {
        switch self {
        case .notDetermined:        
            return "Not determined"
        case .restricted:           
            return "Restricted"
        case .denied:               
            return "Denied"
        case .authorizedAlways:     
            return "Always"
        case .authorizedWhenInUse:  
            return "When in use"
        @unknown default:           
            return "Unknown"
        }
    }
    
    var displayColor: Color {
        switch self {
        case .authorizedAlways:
            return .green
        case .authorizedWhenInUse:
            return .blue
        case .notDetermined:
            return .secondary
        case .denied, .restricted:
            return .red
        @unknown default:
            return .secondary
        }
    }
}

private extension UNAuthorizationStatus {
    var displayName: String {
        switch self {
        case .notDetermined:                        
            return "Not determined"
        case .denied:                               
            return "Denied"
        case .authorized:                           
            return "Authorized"
        case .provisional:                          
            return "Provisional"
        case .ephemeral:                            
            return "Ephemeral"
        @unknown default:                           
            return "Unknown"
        }
    }
    
    var displayColor: Color {
        switch self {
        case .authorized, .provisional, .ephemeral:
            return .green
        case .notDetermined:
            return .secondary
        case .denied:
            return .red
        @unknown default:
            return .secondary
        }
    }
}

#Preview {
    TestsSettingsView()
        .environmentObject(SettingsStore())
        .environmentObject(PermissionsStore())
}
