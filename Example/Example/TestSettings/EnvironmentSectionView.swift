//
//  EnvironmentSectionView.swift
//  Example
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import SwiftUI

/// Picks the Radar environment and its credential: a publishable key or an auth token. Changes apply on the next launch, so the
/// SDK never runs with a host from one environment and a key from another.
struct EnvironmentSectionView: View {
    @ObservedObject var settingsStore: SettingsStore

    @State private var selected: RadarEnvironment
    @State private var key: String
    @State private var localURL: String
    @State private var useAuthToken: Bool
    @State private var authToken: String
    @State private var showQuitAlert = false

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        _selected = State(initialValue: settingsStore.environment)
        _key = State(initialValue: settingsStore.resolvedPublishableKey)
        _localURL = State(initialValue: settingsStore.localURL)
        _useAuthToken = State(initialValue: settingsStore.useAuthToken)
        _authToken = State(initialValue: settingsStore.authToken(for: settingsStore.environment))
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
                useAuthToken = settingsStore.useAuthToken(for: env)
                authToken = settingsStore.authToken(for: env)
            }

            if selected == .local {
                FieldEditor("Local URL", text: $localURL, placeholder: "http://localhost:8081")
            }
            FieldEditor("Key", text: $key, placeholder: "prj_test_pk_…")

            Picker("Credential", selection: $useAuthToken) {
                Text("Publishable key").tag(false)
                Text("Auth token").tag(true)
            }
            .pickerStyle(.segmented)

            if useAuthToken {
                FieldEditor("Auth token (JWT)", text: $authToken, placeholder: "eyJ…")
                Text(trimmedAuthToken.isEmpty ? "No token set" : AuthTokenInfo.describe(trimmedAuthToken))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Initializes with the token instead of the publishable key. The publishable key is still used for map styles.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button {
                settingsStore.saveEnvironment(
                    selected, publishableKey: key, localURL: localURL, useAuthToken: useAuthToken, authToken: authToken)
                showQuitAlert = true
            } label: {
                Text("Apply & quit").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(
                (selected == .local && localURL.trimmingCharacters(in: .whitespaces).isEmpty)
                    || (useAuthToken && trimmedAuthToken.isEmpty))
        }
        .alert("Environment saved", isPresented: $showQuitAlert) {
            // iOS can't relaunch an app, so quit and let the user reopen it.
            Button("Quit") { exit(0) }
        } message: {
            Text("The app will quit. Reopen it to use \(selected.label).")
        }
    }

    private var trimmedAuthToken: String {
        authToken.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// A red strip across the top of every tab, shown only when the environment is misconfigured: no
/// key or auth token is set, or the key check says it isn't valid on the selected environment.
struct EnvironmentBadge: View {
    @EnvironmentObject var settingsStore: SettingsStore

    var body: some View {
        let env = settingsStore.environment
        let key = settingsStore.resolvedAuthorization
        if key.isEmpty || settingsStore.keyCheck.mismatches(env) {
            let missing = settingsStore.useAuthToken ? "no auth token set" : "no key set"
            let problem =
                key.isEmpty ? missing : "\(SettingsStore.keyPrefix(key)) · \(settingsStore.keyCheck.summary)"
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
