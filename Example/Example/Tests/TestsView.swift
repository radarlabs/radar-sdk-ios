//
//  TestsView.swift
//  Example
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import RadarSDK
import SwiftUI

struct TestsView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var logStream: LogStream
    @EnvironmentObject var permissionsStore: PermissionsStore
    @Binding var selectedTab: MainView.TabIdentifier
    @State private var isShowingSettings = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                RecentActivitySection(logStream: logStream, selectedTab: $selectedTab)
                TrackingPanel()
                TripsPanel()
                VerifiedPanel()
                SearchPanel()
                NotificationsPanel()
                MessagingPanel()
            }
            .padding()
        }
        .sheet(isPresented: $isShowingSettings) {
            TestsSettingsView()
                .environmentObject(settingsStore)
                .environmentObject(logStream)
                .environmentObject(permissionsStore)
        }
    }

    /// Right-aligned gear button. Single entry point to TestsSettingsView.
    private var header: some View {
        HStack {
            Spacer()
            Button {
                isShowingSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    TestsView(selectedTab: .constant(.Tests))
        .environmentObject(SettingsStore())
        .environmentObject(LogStream())
        .environmentObject(PermissionsStore())
}
