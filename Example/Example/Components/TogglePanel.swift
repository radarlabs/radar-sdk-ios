//
//  TogglePanel.swift
//  Example
//
//  Created by Alan Charles on 5/4/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import SwiftUI

/// A collapsible section with a header and a grouped set of controls. Use to
/// gather related toggles (e.g. map overlays) under a tappable header that hides
/// the detail when collapsed.
///
///     TogglePanel("Map Overlays") {
///         Toggle("User location", isOn: $showUserLocation)
///         Toggle("Sync region", isOn: $showSyncRegion)
///     }
struct TogglePanel<Content: View>: View {
    private let title: String
    private let content: Content
    @State private var isExpanded: Bool

    init(
        _ title: String,
        initiallyExpanded: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self._isExpanded = State(initialValue: initiallyExpanded)
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation { isExpanded.toggle() }
            } label: {
                HStack {
                    Text(title)
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    content
                }
                .padding(.leading, 4)
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(10)
    }
}

#Preview {
    VStack(spacing: 12) {
        TogglePanel("Map Overlays") {
            Toggle("User location", isOn: .constant(true))
            Toggle("Sync region", isOn: .constant(false))
            Toggle("Nearby geofences", isOn: .constant(true))
        }
        TogglePanel("Debug", initiallyExpanded: false) {
            Toggle("Verbose logging", isOn: .constant(false))
            Toggle("Show monitored regions", isOn: .constant(false))
        }
    }
    .padding()
}
