//
//  ConsoleEntry+UI.swift
//  Example
//
//  Created by Alan Charles on 5/5/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import SwiftUI

/// SwiftUI presentation hooks for `ConsoleEntry.Kind`. Used by `LogsView`
/// (full timeline rows) and the recent-activity preview in `TestsView`.
///
/// Kept out of `LogStream.swift` so the service layer stays free of SwiftUI imports.
extension ConsoleEntry.Kind {
    var iconName: String {
        switch self {
        case .action: return "play.fill"
        case .result: return "checkmark.circle"
        case .event: return "bolt"
        case .location: return "location.fill"
        case .log: return "text.alignleft"
        case .error: return "exclamationmark.triangle.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .action: return .blue
        case .result: return .green
        case .event: return .purple
        case .location: return Color(.systemTeal)
        case .log: return .gray
        case .error: return .red
        }
    }

    var label: String {
        switch self {
        case .action: return "ACTION"
        case .result: return "RESULT"
        case .event: return "EVENT"
        case .location: return "LOCATION"
        case .log: return "LOG"
        case .error: return "ERROR"
        }
    }
}
