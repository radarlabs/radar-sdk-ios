//
//  IdentitySectionView.swift
//  Example
//
//  Created by Alan Charles on 5/14/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import SwiftUI

/// User-identity fields: userId, description, metadata snapshot.
struct IdentitySectionView: View {
    @ObservedObject var settingsStore: SettingsStore

    var body: some View {
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

    // MARK: - Helpers

    private var formattedMetadata: String {
        if settingsStore.metadata.isEmpty {
            return "—"
        }
        return settingsStore.metadata
            .sorted(by: { $0.key < $1.key })
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ", ")
    }
}
