//
//  SettingsStore.swift
//  Example
//
//  Created by Alan Charles on 5/4/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Combine
import RadarSDK

/// Observable bridge between the example app's UI and the Radar SDK + UserDefaults.
///
/// SDK-owned settings (userId, description, metadata, tracking state) are read from
/// and written to the Radar SDK directly — the SDK persists them. App-only settings
/// (publishable-key override, default tab) are persisted to UserDefaults.
///
/// Mutation flow:
///
///     View binds to e.g. `settingsStore.userId`
///       → user edits the value
///       → `didSet` fires
///       → `Radar.setUserId(...)` writes through to the SDK
///
/// Initial load:
///
///     AppDelegate constructs `SettingsStore()` (reads UserDefaults only, because the
///     SDK isn't initialized yet), uses `resolvedPublishableKey` to initialize Radar,
///     then calls `loadFromSDK()` to populate the SDK-backed properties.
///
/// Read-only snapshots (`isTracking`, `trackingOptionsSummary`) update only on
/// explicit `refresh()` — call after any operation that may have changed tracking
/// state (start/stop tracking, mock tracking, etc).

final class SettingsStore: ObservableObject {
    // MARK: - Defaults
    
    /// Hardcoded publishable key used when no override is set.
    static let defaultPublishableKey = "prj_test_pk_0000000000000000000000000000000000000000"
    
    private enum Keys {
        static let publishableKeyOverride = "settings.publishableKeyOverride"
        static let defaultTabRaw = "settings.defaultTabRaw"
    }
    
    // MARK: - SDK-backed (read/write)
    
    @Published var userId: String? {
        didSet {
            guard !isLoadingFromSDK else { return }
            Radar.setUserId(userId)
        }
    }
    
    /// Maps to Radar's `description` (renamed to avoid clashing with `NSObject.description`).
    @Published var userDescription: String? {
        didSet {
            guard !isLoadingFromSDK else { return }
            Radar.setDescription(userDescription)
        }
    }
    
    @Published var metadata: [String: String] {
        didSet {
            guard !isLoadingFromSDK else { return }
            if metadata.isEmpty {
                Radar.setMetadata(nil)
            } else {
                Radar.setMetadata(metadata as [String: Any])
            }
        }
    }
    
    // MARK: - SDK-backed (read-only snapshots; call refresh() to update)
    
    @Published private(set) var isTracking: Bool = false
    @Published private(set) var trackingOptionsSummary: String = "—"
    
    
    // MARK: - App-only (UserDefaults)
    
    @Published var publishableKeyOverride: String {
        didSet {
            UserDefaults.standard.set(publishableKeyOverride, forKey: Keys.publishableKeyOverride)
        }
    }
    
    @Published var defaultTabRaw: String {
        didSet {
            UserDefaults.standard.set(defaultTabRaw, forKey: Keys.defaultTabRaw)
        }
    }
    
    // MARK: - Private
    
    /// Suppresses `didSet` writebacks to the SDK during `loadFromSDK()`.
    private var isLoadingFromSDK = false
    
    init() {
        // UserDefaults — safe to read before Radar is initialized.
        let defaults = UserDefaults.standard
        self.publishableKeyOverride = defaults.string(forKey: Keys.publishableKeyOverride) ?? ""
        self.defaultTabRaw = defaults.string(forKey: Keys.defaultTabRaw) ?? ""
        
        // SDK-backed properties get neutral defaults; loadFromSDK() will populate them.
        self.userId = nil
        self.userDescription = nil
        self.metadata = [:]
    }
    
    // MARK: - Public API
    
    /// The publishable key to pass to `Radar.initialize`. Returns the override if set,
    /// otherwise the hardcoded default.
    var resolvedPublishableKey: String {
        publishableKeyOverride.isEmpty ? Self.defaultPublishableKey : publishableKeyOverride
    }
    
    /// Reads SDK-backed settings into the store. Call once after `Radar.initialize`.
    func loadFromSDK() {
        isLoadingFromSDK = true
        defer { isLoadingFromSDK = false }
        
        self.userId = Radar.getUserId()
        self.userDescription = Radar.getDescription()
        self.metadata = Self.normalizeMetadata(Radar.getMetadata())
        
        refresh()
    }
    
    func refresh() {
        isTracking = Radar.isTracking()
        trackingOptionsSummary = Self.summarize(Radar.getTrackingOptions())
    }
    
    
    // MARK: - Helpers
    
    private static func normalizeMetadata(_ raw: [AnyHashable: Any]?) -> [String: String] {
        guard let raw = raw as? [String: Any] else { return [:] }
        return raw.compactMapValues { value in
            if let s = value as? String {
                return s
            } else if let n = value as? NSNumber {
                // NSNumber-wrapped Bool needs special handling — its `stringValue` is "1"/"0".
                if CFGetTypeID(n) == CFBooleanGetTypeID() {
                    return n.boolValue ? "true" : "false"
                }
                return n.stringValue
            } else {
                return String(describing: value)
            }
        }
    }
    
    private static let presetContinuousDict = RadarTrackingOptions.presetContinuous.dictionaryValue() as NSDictionary
    private static let presetResponsiveDict = RadarTrackingOptions.presetResponsive.dictionaryValue() as NSDictionary
    private static let presetEfficientDict = RadarTrackingOptions.presetEfficient.dictionaryValue() as NSDictionary
    
    private static func summarize(_ options: RadarTrackingOptions) -> String {
        let dict = options.dictionaryValue() as NSDictionary
        if dict.isEqual(presetContinuousDict) { return "Continuous" }
        if dict.isEqual(presetResponsiveDict) { return "Responsive" }
        if dict.isEqual(presetEfficientDict) { return "Efficient" }
        return "Custom"
    }
}

