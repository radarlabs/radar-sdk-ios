//
//  TestsSettingsView.swift
//  Example
//
//  Created by Alan Charles on 5/5/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import SwiftUI

/// Modal configuration view presented from TestsView's gear icon. Composes
/// five sections (Environment, Presets, Identity, Tracking, Permissions).
///
/// Environment changes are saved by its Apply button and take effect on relaunch. All other
/// edits write through to the SettingsStore / SDK immediately — Done just dismisses the sheet.
struct TestsSettingsView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var permissionsStore: PermissionsStore
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    EnvironmentSectionView(settingsStore: settingsStore)
                    PresetSectionView(settingsStore: settingsStore)
                    IdentitySectionView(settingsStore: settingsStore)
                    TrackingSectionView(settingsStore: settingsStore)
                    PermissionsSectionView(permissionsStore: permissionsStore)
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
}

#Preview {
    TestsSettingsView()
        .environmentObject(SettingsStore())
        .environmentObject(PermissionsStore())
}
