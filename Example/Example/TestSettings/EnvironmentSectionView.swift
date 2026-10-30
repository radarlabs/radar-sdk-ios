//
//  EnvironmentSectionView.swift
//  Example
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import SwiftUI

/// Picks the Radar environment and its publishable key. Changes are saved and applied on the next
/// launch, so the SDK never runs with a host from one environment and a key from another.
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
        _localURL = State(initialValue: settingsStore.savedLocalURL)
    }

    private var missingLocalURL: Bool {
        selected == .local && localURL.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var changed: Bool {
        selected != settingsStore.environment
            || key.trimmingCharacters(in: .whitespaces) != settingsStore.publishableKey(for: selected)
            || (selected == .local && localURL.trimmingCharacters(in: .whitespaces) != settingsStore.localURL)
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
            } else {
                Text("Host: \(selected.host(localURL: ""))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            FieldEditor("Key", text: $key, placeholder: "prj_test_pk_…")

            Button {
                settingsStore.saveEnvironment(selected, publishableKey: key, localURL: localURL)
                showQuitAlert = true
            } label: {
                Text(missingLocalURL ? "Set a local server URL" : "Apply & quit")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!changed || missingLocalURL)
        }
        .alert("Environment saved", isPresented: $showQuitAlert) {
            // iOS can't relaunch an app, so quit and let the user reopen it.
            Button("Quit") { exit(0) }
        } message: {
            Text("The app will quit. Reopen it to use \(selected.label).")
        }
    }
}

/// A strip across the top of every tab showing the environment, the key and whether the key is
/// valid there. Turns red when the key check says the key belongs somewhere else.
struct EnvironmentBadge: View {
    @EnvironmentObject var settingsStore: SettingsStore

    var body: some View {
        let env = settingsStore.environment
        let key = settingsStore.resolvedPublishableKey
        let mismatch = key.isEmpty || settingsStore.keyCheck.mismatches(env)
        let keyText = key.isEmpty ? "no key set" : SettingsStore.keyPrefix(key)
        let checkText = key.isEmpty ? "" : " · \(settingsStore.keyCheck.summary)"

        Text((mismatch ? "⚠ " : "") + "\(env.label) · \(keyText)\(checkText)")
            .font(.caption.weight(.semibold))
            .foregroundColor(.white)
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background((mismatch ? Color.red : env.color).ignoresSafeArea(edges: .top))
    }
}
