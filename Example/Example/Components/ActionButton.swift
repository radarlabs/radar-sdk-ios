//
//  ActionButton.swift
//  Example
//
//  Created by Alan Charles on 5/4/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import SwiftUI

/// Replacement for StyledButton with three visual styles, designed for the
/// vertical stacks of test actions in TestsView and similar.
///
///     ActionButton("trackOnce") { Radar.trackOnce() }
///     ActionButton("startTracking", style: .primary) { ... }
///     ActionButton("stopTracking", style: .destructive) { ... }
struct ActionButton: View {
    @EnvironmentObject var logStream: LogStream

    enum Style {
        case primary
        case secondary
        case destructive
    }

    private let title: String
    private let style: Style
    private let action: () -> Void

    init(
        _ title: String,
        style: Style = .secondary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.action = action
    }

    var body: some View {
        Button {
            logStream.write(action: title)
            action()
        } label: {
            Text(title)
                .font(.body.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(backgroundColor)
                .foregroundColor(foregroundColor)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return .blue
        case .secondary: return Color(.tertiarySystemFill)
        case .destructive: return Color.red.opacity(0.12)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .primary
        case .destructive: return .red
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        ActionButton("trackOnce") {}
        ActionButton("startTracking", style: .primary) {}
        ActionButton("stopTracking", style: .destructive) {}
    }
    .padding()
    .environmentObject(LogStream())
}
