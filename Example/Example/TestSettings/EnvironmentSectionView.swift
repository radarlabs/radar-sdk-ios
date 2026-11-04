//
//  EnvironmentSectionView.swift
//  Example
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import SwiftUI

/// Picks the Radar environment and its publishable key. Changes apply on the next launch, so the
/// SDK never runs with a host from one environment and a key from another.
struct EnvironmentSectionView: View {
    @ObservedObject var settingsStore: SettingsStore

    @State private var selected: RadarEnvironment
    @State private var key: String
    @State private var localURL: String
    @State private var showQuitAlert = false

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        _selected = State(initialValue: settingsStore.environment)
        _key = State(initialValue: settingsStore.resolvedPublishableKey)
        _localURL = State(initialValue: settingsStore.localURL)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Environment").font(.headline)
            Text("Running: \(settingsStore.environmentSummary)")
                .font(.caption)
                .foregroundColor(.secondary)

            Picker("Environment", selection: $selected) {
                ForEach(RadarEnvironment.allCases) { env in
                    Text(env.label).tag(env)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selected) { env in
                key = settingsStore.publishableKey(for: env)
            }

            if selected == .local {
                FieldEditor("Local URL", text: $localURL, placeholder: "http://localhost:8081")
            }
            FieldEditor("Key", text: $key, placeholder: "prj_test_pk_…")

            Button {
                settingsStore.saveEnvironment(selected, publishableKey: key, localURL: localURL)
                showQuitAlert = true
            } label: {
                Text("Apply & quit").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(selected == .local && localURL.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .alert("Environment saved", isPresented: $showQuitAlert) {
            // iOS can't relaunch an app, so quit and let the user reopen it.
            Button("Quit") { exit(0) }
        } message: {
            Text("The app will quit. Reopen it to use \(selected.label).")
        }
    }
}

/// A red strip across the top of every tab, shown only when the environment is misconfigured: no
/// key is set, or the key check says the key isn't valid on the selected environment.
struct EnvironmentBadge: View {
    @EnvironmentObject var settingsStore: SettingsStore

    var body: some View {
        let env = settingsStore.environment
        let key = settingsStore.resolvedPublishableKey
        if key.isEmpty || settingsStore.keyCheck.mismatches(env) {
            let problem =
                key.isEmpty ? "no key set" : "\(SettingsStore.keyPrefix(key)) · \(settingsStore.keyCheck.summary)"
            Text("⚠ \(env.label) · \(problem)")
                .font(.caption.weight(.semibold))
                .foregroundColor(.white)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.red.ignoresSafeArea(edges: .top))
        }
    }
}
