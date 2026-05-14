//
//  ControlRow.swift
//  Example
//
//  Created by Alan Charles on 5/4/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import SwiftUI

/// A labeled row with right-aligned content, in the style of an iOS Settings cell.
///
/// Use for read-only display of a labeled value:
///
///     ControlRow("Tracking") {
///         Text(settingsStore.isTracking ? "On" : "Off")
///     }
///
/// Wrap in a `Button` or `NavigationLink` at the use site if you need taps.
struct ControlRow<Content: View>: View {
    private let label: String
    private let content: Content

    init(_ label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            content
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    VStack(alignment: .leading) {
        ControlRow("User ID") { Text("alice@example.com") }
        ControlRow("Tracking") { Text("On") }
        ControlRow("Preset") { Text("Continuous") }
        ControlRow("Empty") { Text("—") }
    }
    .padding()
}
