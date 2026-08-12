//
//  LogsView.swift
//  Example
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import RadarSDK
import SwiftUI
import UIKit

struct LogsView: View {
    @EnvironmentObject var logStream: LogStream
    @State private var filter: Filter = .all
    @State private var expandedIds: Set<UUID> = []
    @State private var isShowingShareSheet = false
    @State private var didJustCopy = false

    enum Filter: String, CaseIterable, Identifiable {
        case all = "All"
        case actions = "Actions"
        case events = "Events"
        case locations = "Locations"
        case logs = "Logs"

        var id: String { rawValue }

        func includes(_ kind: ConsoleEntry.Kind) -> Bool {
            switch self {
            case .all: return true
            case .actions: return kind == .action || kind == .result
            case .events: return kind == .event
            case .locations: return kind == .location
            case .logs: return kind == .log || kind == .error
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            filterRow
            Divider()
            content
        }
        .sheet(isPresented: $isShowingShareSheet) {
            ActivityShareSheet(activityItems: [ConsoleEntry.formatForExport(filtered)])
        }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack(spacing: 12) {
            Text("Console").font(.title2.weight(.semibold))
            Text("\(filtered.count)")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()

            Button(action: copyToPasteboard) {
                Image(systemName: didJustCopy ? "checkmark" : "doc.on.doc")
            }
            .font(.callout)
            .buttonStyle(.borderless)
            .disabled(filtered.isEmpty)
            .accessibilityLabel(didJustCopy ? "Copied" : "Copy logs")

            Button(action: { isShowingShareSheet = true }) {
                Image(systemName: "square.and.arrow.up")
            }
            .font(.callout)
            .buttonStyle(.borderless)
            .disabled(filtered.isEmpty)
            .accessibilityLabel("Share logs")

            Button("Clear") {
                logStream.clearEntries()
                expandedIds.removeAll()
            }
            .font(.callout)
            .buttonStyle(.borderless)
            .disabled(logStream.entries.isEmpty)
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Filter.allCases) { option in
                    Button {
                        filter = option
                    } label: {
                        Text(option.rawValue)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(filter == option ? Color.accentColor : Color(.tertiarySystemFill))
                            .foregroundColor(filter == option ? .white : .primary)
                            .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }

    @ViewBuilder
    private var content: some View {
        if filtered.isEmpty {
            emptyState
        } else {
            List {
                ForEach(filtered) { entry in
                    ConsoleEntryRow(entry: entry, isExpanded: expansionBinding(for: entry))
                }
            }
            .listStyle(.plain)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Nothing yet")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Tap an action in the Tests tab to see SDK activity here.")
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private var filtered: [ConsoleEntry] {
        logStream.entries.reversed().filter { filter.includes($0.kind) }
    }

    private func expansionBinding(for entry: ConsoleEntry) -> Binding<Bool> {
        Binding(
            get: { expandedIds.contains(entry.id) },
            set: { newValue in
                if newValue {
                    expandedIds.insert(entry.id)
                } else {
                    expandedIds.remove(entry.id)
                }
            }
        )
    }

    private func copyToPasteboard() {
        UIPasteboard.general.string = ConsoleEntry.formatForExport(filtered)
        withAnimation {
            didJustCopy = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                didJustCopy = false
            }
        }
    }
}

#Preview {
    LogsView()
        .environmentObject(LogStream())
}
