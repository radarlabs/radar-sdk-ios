//
//  ConsoleEntryRow.swift
//  Example
//
//  Created by Alan Charles on 5/14/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import SwiftUI

/// Single row in the Logs tab's console timeline. Renders kind icon,
/// timestamp, kind label, and summary, with tap-to-expand revealing
/// the optional detail block.
struct ConsoleEntryRow: View {
    let entry: ConsoleEntry
    @Binding var isExpanded: Bool

    var body: some View {
        let canExpand = entry.detail != nil

        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: entry.kind.iconName)
                    .foregroundColor(entry.kind.tintColor)
                    .frame(width: 18)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(timeString)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                        Text(entry.kind.label)
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(entry.kind.tintColor)
                    }
                    Text(entry.summary)
                        .font(.callout)
                        .lineLimit(isExpanded ? nil : 2)
                }
                Spacer(minLength: 0)
                if canExpand {
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }

            if isExpanded, let detail = entry.detail {
                Text(detail)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(6)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard canExpand else { return }
            withAnimation {
                isExpanded.toggle()
            }
        }
    }

    // MARK: - Formatting

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    private var timeString: String {
        Self.timeFormatter.string(from: entry.timestamp)
    }
}
