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
    @EnvironmentObject var permissionsStore: PermissionsStore
    @Binding var selectedTab: MainView.TabIdentifier
    @State private var isShowingSettings = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
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
}

#Preview {
    TestsView(selectedTab: .constant(.Tests))
        .environmentObject(SettingsStore())
        .environmentObject(LogStream())
        .environmentObject(PermissionsStore())
}
