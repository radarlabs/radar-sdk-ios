//
//  PresetSectionView.swift
//  Example
//
//  Created by Alan Charles on 5/14/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import SwiftUI

/// Tracking preset selector with disclosure-group reveals for the
/// currently-applied tracking options and SDK configuration.
struct PresetSectionView: View {
    @ObservedObject var settingsStore: SettingsStore
    @State private var isOptionsExpanded: Bool = false
    @State private var isSdkConfigExpanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Presets").font(.headline)
            presetGrid
            Text(presetStatusText)
                .font(.caption)
                .foregroundColor(.secondary)
            trackingOptionsDisclosure
            sdkConfigurationDisclosure
        }
    }

    // MARK: - Subsections

    private var presetGrid: some View {
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
    }

    private var trackingOptionsDisclosure: some View {
        DisclosureGroup(isExpanded: $isOptionsExpanded) {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(settingsStore.currentTrackingFields) { field in
                    fieldRow(field)
                }
            }
            .padding(.top, 4)
        } label: {
            Text("Active tracking options")
                .font(.subheadline.weight(.medium))
        }
    }

    private var sdkConfigurationDisclosure: some View {
        DisclosureGroup(isExpanded: $isSdkConfigExpanded) {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(settingsStore.currentSdkConfigFields) { field in
                    fieldRow(field)
                }
            }
            .padding(.top, 4)
        } label: {
            Text("SDK configuration")
                .font(.subheadline.weight(.medium))
        }
    }

    private func fieldRow(_ field: TrackingField) -> some View {
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

    // MARK: - Helpers

    private var presetStatusText: String {
        if let active = TestPreset.all.first(where: { $0.id == settingsStore.activePresetId }) {
            return active.summary
        }
        return "No preset active — manual identity in effect."
    }

    private func isActive(_ preset: TestPreset) -> Bool {
        preset.id == settingsStore.activePresetId
    }

    private func color(for field: TrackingField) -> Color {
        if case .bool(let v) = field.kind {
            return v ? .green : .secondary
        }
        return .primary
    }
}
