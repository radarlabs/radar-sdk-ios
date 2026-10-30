//
//  RadarEnvironment.swift
//  Example
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

/// The Radar API environment the example app talks to. This is the only place the hosts are
/// defined: pick an environment in Settings → Environment instead of editing constants.
///
/// `.local` points both the regular and verified host at a dev server URL: "http://localhost:8081"
/// in the Simulator, or your Mac's LAN IP (e.g. "http://192.168.0.24:8081") on a device.
enum RadarEnvironment: String, CaseIterable, Identifiable {
    case production
    case staging
    case local

    var id: String { rawValue }

    var label: String {
        switch self {
        case .production: return "Production"
        case .staging: return "Staging"
        case .local: return "Local"
        }
    }

    func host(localURL: String) -> String {
        switch self {
        case .production: return "https://api.radar.io"
        case .staging: return "https://api.radar-staging.com"
        case .local: return localURL
        }
    }

    func verifiedHost(localURL: String) -> String {
        switch self {
        case .production: return "https://api-verified.radar.io"
        case .staging: return "https://api-verified.radar-staging.com"
        case .local: return localURL
        }
    }

    /// Environments with fixed hosts, which the key check probes.
    static let checkable: [RadarEnvironment] = [.production, .staging]

    /// Writes the host overrides the SDK reads (see RadarUserDefaults). Production clears them so
    /// the SDK falls back to its built-in defaults. Call after `Radar.setAppGroup`.
    func apply(localURL: String) {
        guard let defaults = Utils.radarUserDefaults else { return }
        if self == .production {
            defaults.removeObject(forKey: "radar-host")
            defaults.removeObject(forKey: "radar-verifiedHost")
        } else {
            defaults.set(host(localURL: localURL), forKey: "radar-host")
            defaults.set(verifiedHost(localURL: localURL), forKey: "radar-verifiedHost")
        }
    }
}

/// Which environments a publishable key is valid on. A key's string doesn't say whether it
/// belongs to staging or production, so `KeyChecker` asks each environment's `/v1/config`.
enum KeyCheck: Equatable {
    case notChecked
    case checking
    /// `unknown` lists environments that couldn't be reached or gave an unexpected response.
    case done(validOn: [RadarEnvironment], unknown: [RadarEnvironment])

    /// Whether the key is known not to work on `environment`. Local is never checked.
    func mismatches(_ environment: RadarEnvironment) -> Bool {
        guard case let .done(validOn, unknown) = self else { return false }
        return RadarEnvironment.checkable.contains(environment)
            && !validOn.contains(environment) && !unknown.contains(environment)
    }

    var summary: String {
        switch self {
        case .notChecked:
            return "not checked"
        case .checking:
            return "checking…"
        case let .done(validOn, unknown):
            let valid =
                validOn.isEmpty
                ? "valid on neither"
                : "valid on " + validOn.map(\.label).joined(separator: " and ")
            if unknown.isEmpty { return valid }
            return "\(valid) (\(unknown.map(\.label).joined(separator: ", ")) unreachable)"
        }
    }
}

enum KeyChecker {
    /// Probes every `RadarEnvironment.checkable` environment; calls back on the main queue.
    static func check(publishableKey: String, completion: @escaping (KeyCheck) -> Void) {
        Task {
            var validOn: [RadarEnvironment] = []
            var unknown: [RadarEnvironment] = []
            for environment in RadarEnvironment.checkable {
                switch await probe(host: environment.host(localURL: ""), publishableKey: publishableKey) {
                case true?: validOn.append(environment)
                case false?: break
                case nil: unknown.append(environment)
                }
            }
            let result = KeyCheck.done(validOn: validOn, unknown: unknown)
            await MainActor.run { completion(result) }
        }
    }

    /// true = accepted, false = rejected (401/403), nil = unreachable or unexpected response.
    private static func probe(host: String, publishableKey: String) async -> Bool? {
        guard let url = URL(string: "\(host)/v1/config?installId=example-key-check&usage=keyCheck") else { return nil }
        var request = URLRequest(url: url, timeoutInterval: 5)
        request.setValue(publishableKey, forHTTPHeaderField: "Authorization")
        guard let (_, response) = try? await URLSession.shared.data(for: request),
            let status = (response as? HTTPURLResponse)?.statusCode
        else { return nil }
        switch status {
        case 200..<300: return true
        case 401, 403: return false
        default: return nil
        }
    }
}
