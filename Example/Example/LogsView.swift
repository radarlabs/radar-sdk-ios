//
//  LogsView.swift
//  Example
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import SwiftUI
import RadarSDK

struct LogsView: View {
    @EnvironmentObject var logStream: LogStream
    @State private var filter: Filter = .all
    @State private var expandedIds: Set<UUID> = []
    
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
    }
    
    // MARK: - Subviews
    
    private var header: some View {
        HStack(spacing: 8) {
            Text("Console").font(.title2.weight(.semibold))
            Text("\(filtered.count)")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
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
                    Button { filter = option } label: {
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
                    entryRow(entry)
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
    
    private func entryRow(_ entry: ConsoleEntry) -> some View {
        let isExpanded = expandedIds.contains(entry.id)
        let canExpand = entry.detail != nil
        
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: entry.kind.iconName)
                    .foregroundColor(entry.kind.tintColor)
                    .frame(width: 18)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(timeString(entry.timestamp))
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
                if isExpanded {
                    expandedIds.remove(entry.id)
                } else {
                    expandedIds.insert(entry.id)
                }
            }
        }
    }
    
    // MARK: - Filtering
    
    private var filtered: [ConsoleEntry] {
        // Newest first; the underlying array is appended chronologically.
        logStream.entries.reversed().filter { filter.includes($0.kind) }
    }
    
    // MARK: - Formatting
    
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()
    
    private func timeString(_ date: Date) -> String {
        Self.timeFormatter.string(from: date)
    }
}

#Preview {
    LogsView()
        .environmentObject(LogStream())
}
