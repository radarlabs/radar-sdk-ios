//
//  DemoLog.swift
//  Example
//
//  Created by Alan Charles on 4/16/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

enum DemoLog {
    private static let suiteName = "group.waypoint.data"
    private static let key = "demoLog"
    private static let maxEntries = 500

    private static let defaults: UserDefaults = {
        UserDefaults(suiteName: suiteName) ?? .standard
    }()

    private static let queue = DispatchQueue(label: "io.radar.demoLog", qos: .utility)
    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    static func append(_ entry: String) {
        let timestamp = isoFormatter.string(from: Date())
        let line = "[\(timestamp)] \(entry)"
        queue.async {
            var log = defaults.array(forKey: key) as? [String] ?? []
            log.append(line)
            if log.count > maxEntries { log = Array(log.suffix(maxEntries)) }
            defaults.set(log, forKey: key)
        }
    }

    static func read() -> [String] {
        defaults.array(forKey: key) as? [String] ?? []
    }

    static func clear() {
        queue.async { defaults.removeObject(forKey: key) }
    }
}

