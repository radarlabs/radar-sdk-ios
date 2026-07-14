//
//  SettingsStore.swift
//  Example
//
//  Created by Alan Charles on 5/4/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Combine
import Foundation
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
///       → `activePresetId` is cleared (manual edit drifts away from any preset)
///
/// During `apply(_:)`, the `isApplyingPreset` flag suppresses the activePresetId
/// clearing so the UI doesn't flicker the chip de-highlighted then re-highlighted.
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
    static let defaultPublishableKey = "prj_test_pk_9469eca3762c311d8c0a34f1995f2ee3531528c0"

    private enum Keys {
        static let publishableKeyOverride = "settings.publishableKeyOverride"
        static let defaultTabRaw = "settings.defaultTabRaw"
    }

    // MARK: - SDK-backed (read/write)

    @Published var userId: String? {
        didSet {
            guard !isLoadingFromSDK else { return }
            Radar.setUserId(userId)
            if !isApplyingPreset { activePresetId = nil }
        }
    }

    /// Maps to Radar's `description` (renamed to avoid clashing with `NSObject.description`).
    @Published var userDescription: String? {
        didSet {
            guard !isLoadingFromSDK else { return }
            Radar.setDescription(userDescription)
            if !isApplyingPreset { activePresetId = nil }
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
            if !isApplyingPreset { activePresetId = nil }
        }
    }

    // MARK: - SDK-backed (read-only snapshots; call refresh() to update)

    @Published private(set) var isTracking: Bool = false
    @Published private(set) var isUsingRemoteOptions: Bool = false
    @Published private(set) var trackingOptionsSummary: String = "—"

    /// Last preset applied via `apply(_: TestPreset)`. Set by the preset machinery,
    /// cleared automatically when any identity field is mutated outside of `apply(_:)`.
    /// Read by the Tests view to highlight the active chip.
    @Published var activePresetId: String?

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

    /// Suppresses `activePresetId` clearing during `apply(_:)`. The didSet on each
    /// identity field would otherwise nil out the chip mid-application.
    private var isApplyingPreset = false

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
        isUsingRemoteOptions = Radar.isUsingRemoteTrackingOptions()
        trackingOptionsSummary = Self.summarize(Radar.getTrackingOptions(), remote: isUsingRemoteOptions)
    }

    /// Apply a preset: write identity through to the SDK, perform the requested
    /// tracking action, and refresh tracking snapshots. The `isApplyingPreset` flag
    /// prevents the identity didSets from clearing `activePresetId` while we set it.
    /// Tab navigation is the caller's concern — read `preset.suggestedTabRaw`.
    func apply(_ preset: TestPreset) {
        isApplyingPreset = true
        defer { isApplyingPreset = false }

        userId = preset.userId
        userDescription = preset.userDescription
        metadata = preset.metadata

        switch preset.trackingAction {
        case .leaveUnchanged:
            break
        case .start(let options):
            Radar.startTracking(trackingOptions: options)
        case .stop:
            Radar.stopTracking()
        }

        activePresetId = preset.id
        refresh()
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

    /// Match against the SDK's hand-rolled `-isEqual:` on RadarTrackingOptions, which
    /// compares fields directly (handling enum casing, optional Date interval, etc).
    /// Dict round-tripping was unreliable because the SDK's persisted representation
    /// reboxes some fields and ignores `type` in equality.
    private static func summarize(_ options: RadarTrackingOptions, remote: Bool) -> String {
        let moving = Int(options.desiredMovingUpdateInterval)
        let sync = Int(options.desiredSyncInterval)
        if remote {
            // Server-driven options take precedence over anything we pass to
            // Radar.startTracking(...). Don't try to preset-match — show concrete
            // intervals so the discrepancy with the highlighted chip is legible.
            return "Server (\(moving)s/\(sync)s)"
        }
        if options.isEqual(RadarTrackingOptions.presetContinuous) { return "Continuous" }
        if options.isEqual(RadarTrackingOptions.presetResponsive) { return "Responsive" }
        if options.isEqual(RadarTrackingOptions.presetEfficient) { return "Efficient" }
        return "Custom (\(moving)s/\(sync)s)"
    }
}

// MARK: - Tracking options field rendering

/// One row of the live tracking-options breakdown shown below the preset chips.
/// `kind` lets the view tint booleans (true=green, false=secondary) without
/// re-parsing the value string.
struct TrackingField: Identifiable {
    let label: String
    let value: String
    let kind: Kind

    var id: String { label }

    enum Kind {
        case bool(Bool)
        case other
    }

    static func bool(_ label: String, _ value: Bool) -> TrackingField {
        TrackingField(label: label, value: value ? "true" : "false", kind: .bool(value))
    }
    static func interval(_ label: String, _ secs: Int32) -> TrackingField {
        TrackingField(label: label, value: "\(secs)s", kind: .other)
    }
    static func meters(_ label: String, _ m: Int32) -> TrackingField {
        TrackingField(label: label, value: "\(m)m", kind: .other)
    }
    static func text(_ label: String, _ value: String) -> TrackingField {
        TrackingField(label: label, value: value, kind: .other)
    }
}

extension SettingsStore {
    /// Ordered field/value pairs for the currently-effective tracking options.
    /// Re-evaluated on each access; view re-renders triggered by `refresh()`
    /// (which mutates `trackingOptionsSummary`) pick up new values.
    var currentTrackingFields: [TrackingField] {
        Self.fields(from: Radar.getTrackingOptions())
    }

    private static func fields(from o: RadarTrackingOptions) -> [TrackingField] {
        var fields: [TrackingField] = [
            // Intervals
            .interval("desiredStoppedUpdateInterval", o.desiredStoppedUpdateInterval),
            .interval("desiredMovingUpdateInterval", o.desiredMovingUpdateInterval),
            .interval("desiredSyncInterval", o.desiredSyncInterval),
            // Accuracy & sync
            .text("desiredAccuracy", RadarTrackingOptions.string(for: o.desiredAccuracy)),
            .text("syncLocations", RadarTrackingOptions.string(for: o.syncLocations)),
            .text("replay", RadarTrackingOptions.string(for: o.replay)),
            // Stop detection
            .interval("stopDuration", o.stopDuration),
            .meters("stopDistance", o.stopDistance),
            // Geofence-based detection
            .bool("useStoppedGeofence", o.useStoppedGeofence),
            .meters("stoppedGeofenceRadius", o.stoppedGeofenceRadius),
            .bool("useMovingGeofence", o.useMovingGeofence),
            .meters("movingGeofenceRadius", o.movingGeofenceRadius),
            .bool("syncGeofences", o.syncGeofences),
            // Sensors
            .bool("beacons", o.beacons),
            .bool("useVisits", o.useVisits),
            .bool("useSignificantLocationChanges", o.useSignificantLocationChanges),
            .bool("useMotion", o.useMotion),
            .bool("useIndoorScan", o.useIndoorScan),
            .bool("usePressure", o.usePressure),
            // Misc
            .bool("showBlueBar", o.showBlueBar),
            .interval("batchInterval", o.batchInterval),
            .text("batchSize", "\(o.batchSize)"),
            .text("type", RadarTrackingOptions.string(for: o.type)),
        ]
        if let start = o.startTrackingAfter {
            fields.append(.text("startTrackingAfter", isoFormatter.string(from: start)))
        }
        if let stop = o.stopTrackingAfter {
            fields.append(.text("stopTrackingAfter", isoFormatter.string(from: stop)))
        }
        return fields
    }

    private static let isoFormatter = ISO8601DateFormatter()

    /// Ordered field/value pairs for the live SDK configuration (server-driven
    /// settings). Returns a single placeholder row if no config has been fetched
    /// yet. Re-evaluated on each access; refresh via `settingsStore.refresh()`.
    var currentSdkConfigFields: [TrackingField] {
        guard let c = RadarSdkConfiguration.current() else {
            return [.text("status", "No SDK config fetched yet")]
        }
        return Self.fields(from: c)
    }

    private static func fields(from c: RadarSdkConfiguration) -> [TrackingField] {
        var fields: [TrackingField] = [
            // Logging
            .text("logLevel", logLevelString(c.logLevel())),
            // Lifecycle
            .bool("startTrackingOnInitialize", c.startTrackingOnInitialize()),
            .bool("trackOnceOnAppOpen", c.trackOnceOnAppOpen()),
            // Sync mode
            .bool("useSyncRegion", c.useSyncRegion()),
            .bool("syncAfterSetUser", c.syncAfterSetUser()),
            // Geofence behavior
            .bool("bufferGeofenceEntries", c.bufferGeofenceEntries()),
            .bool("bufferGeofenceExits", c.bufferGeofenceExits()),
            .text("defaultGeofenceDwellThreshold", "\(c.defaultGeofenceDwellThreshold())"),
            .bool("stopDetection", c.stopDetection()),
            // Persistence / logging
            .bool("usePersistence", c.usePersistence()),
            .bool("useLogPersistence", c.useLogPersistence()),
            .bool("extendFlushReplays", c.extendFlushReplays()),
            // Misc / less-common
            .bool("useRadarModifiedBeacon", c.useRadarModifiedBeacon()),
            .bool("useOpenedAppConversion", c.useOpenedAppConversion()),
            .bool("useForegroundLocationUpdatedAtMsDiff", c.useForegroundLocationUpdatedAtMsDiff()),
            .bool("useOfflineRTOUpdates", c.useOfflineRTOUpdates()),
            .bool("offlineEventGenerationEnabled", c.offlineEventGenerationEnabled()),
            .bool("skipForegroundCheck", c.skipForegroundCheck()),
        ]
        let rtoCount = c.remoteTrackingOptions()?.count ?? 0
        fields.append(.text("remoteTrackingOptions", "\(rtoCount) preset(s)"))
        return fields
    }

    /// `RadarLogLevel.toString()` is internal in the SDK module, so duplicate
    /// the mapping here. If the SDK ever exposes it publicly (or adds
    /// `+stringForLogLevel:` like the other tracking-options enums), drop this.
    private static func logLevelString(_ level: RadarLogLevel) -> String {
        switch level {
        case .none: return "none"
        case .error: return "error"
        case .warning: return "warning"
        case .info: return "info"
        case .debug: return "debug"
        @unknown default: return "unknown"
        }
    }
}
