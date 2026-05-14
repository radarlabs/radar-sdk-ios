//
//  ConsoleEntry+Export.swift
//  Example
//
//  Created by Alan Charles on 5/14/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

extension ConsoleEntry {
    /// Format a list of entries as a copy-pastable plain-text dump.
    /// Each entry becomes a header line plus optional indented detail lines.
    static func formatForExport(_ entries: [ConsoleEntry]) -> String {
        entries.map { entry -> String in
            var lines = [
                "[\(Self.exportFormatter.string(from: entry.timestamp))] \(entry.kind.label): \(entry.summary)"
            ]
            if let detail = entry.detail, !detail.isEmpty {
                let indented =
                    detail
                    .split(separator: "\n", omittingEmptySubsequences: false)
                    .map { "    \($0)" }
                    .joined(separator: "\n")
                lines.append(indented)
            }
            return lines.joined(separator: "\n")
        }
        .joined(separator: "\n\n")
    }

    private static let exportFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f
    }()
}
