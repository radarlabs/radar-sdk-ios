//
//  RadarEnvironment.swift
//  Example
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

/// The Radar API environment the example app talks to, picked in Settings → Environment.
/// `.local` points both hosts at a dev server URL: "http://localhost:8081" in the Simulator, or
/// your Mac's LAN IP (e.g. "http://192.168.0.24:8081") on a device.
enum RadarEnvironment: String, CaseIterable, Identifiable {
    case production
    case staging
    case local

    var id: String { rawValue }

    var label: String { rawValue.capitalized }

    /// Fixed API and verified hosts; nil for `.local`, which uses the Local URL for both.
    var hosts: (api: String, verified: String)? {
        switch self {
        case .production: return ("https://api.radar.io", "https://api-verified.radar.io")
        case .staging: return ("https://api.radar-staging.com", "https://api-verified.radar-staging.com")
        case .local: return nil
        }
    }

    func host(localURL: String) -> String { hosts?.api ?? localURL }

    /// Writes the host overrides the SDK reads (see RadarUserDefaults). Production clears them so
    /// the SDK uses its built-in defaults. Call after `Radar.setAppGroup`.
    func apply(localURL: String) {
        guard let defaults = Utils.radarUserDefaults else { return }
        if self == .production {
            defaults.removeObject(forKey: "radar-host")
            defaults.removeObject(forKey: "radar-verifiedHost")
        } else {
            defaults.set(host(localURL: localURL), forKey: "radar-host")
            defaults.set(hosts?.verified ?? localURL, forKey: "radar-verifiedHost")
        }
    }
}
