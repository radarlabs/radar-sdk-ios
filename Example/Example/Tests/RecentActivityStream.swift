//
//  RecentActivityStream.swift
//  Example
//
//  Created by Alan Charles on 5/14/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import SwiftUI

/// Compact preview of the last 5 LogStream entries shown at the top of the
/// Tests tab. "View all" jumps to the Logs tab via a binding to the
/// MainView tab selection.
struct RecentActivitySection: View {
    @ObservedObject var logStream: LogStream
    @Binding var selectedTab: MainView.TabIdentifier

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            preview
        }
    }

    // MARK: - Subsections

    private var header: some View {
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
    }

    @ViewBuilder
    private var preview: some View {
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
