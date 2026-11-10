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
/// (environment, per-environment publishable keys, Local URL, default tab) are persisted to
/// UserDefaults.
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

    private enum Keys {
        static let environment = "settings.environment"
        static let localURL = "settings.localURL"
        static let defaultTabRaw = "settings.defaultTabRaw"

        static func publishableKey(_ environment: RadarEnvironment) -> String {
            "settings.publishableKey.\(environment.rawValue)"
        }

        static func useAuthToken(_ environment: RadarEnvironment) -> String {
            "settings.useAuthToken.\(environment.rawValue)"
        }

        static func authToken(_ environment: RadarEnvironment) -> String {
            "settings.authToken.\(environment.rawValue)"
        }
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

    /// The environment this launch uses. Fixed for the life of the process: change it with
    /// `saveEnvironment(_:publishableKey:localURL:)` and relaunch.
    let environment: RadarEnvironment

    /// The Local server URL this launch uses.
    let localURL: String

    /// Which environments `resolvedPublishableKey` is valid on.
    @Published private(set) var keyCheck: KeyCheck = .notChecked

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
        self.environment = defaults.string(forKey: Keys.environment).flatMap(RadarEnvironment.init(rawValue:)) ?? .production
        self.localURL = defaults.string(forKey: Keys.localURL) ?? ""
        self.defaultTabRaw = defaults.string(forKey: Keys.defaultTabRaw) ?? ""

        // SDK-backed properties get neutral defaults; loadFromSDK() will populate them.
        self.userId = nil
        self.userDescription = nil
        self.metadata = [:]
    }

    // MARK: - Public API

    /// The publishable key to pass to `Radar.initialize`: the key for `environment`, or "" if
    /// none is set.
    var resolvedPublishableKey: String {
        publishableKey(for: environment)
    }

    /// Whether `environment` initializes with an auth token instead of the publishable key.
    var useAuthToken: Bool {
        useAuthToken(for: environment)
    }

    /// The auth token to pass to `Radar.initialize(authToken:)`, or nil when `environment` uses
    /// the publishable key or has no token set.
    var resolvedAuthToken: String? {
        guard useAuthToken else { return nil }
        let token = authToken(for: environment)
        return token.isEmpty ? nil : token
    }

    func useAuthToken(for environment: RadarEnvironment) -> Bool {
        UserDefaults.standard.bool(forKey: Keys.useAuthToken(environment))
    }

    /// The saved auth token (a JWT) for `environment`, or "" if none is set.
    func authToken(for environment: RadarEnvironment) -> String {
        UserDefaults.standard.string(forKey: Keys.authToken(environment)) ?? ""
    }

    /// The saved key for `environment`, falling back to its default in `AppDelegate`
    /// (placeholders count as unset).
    func publishableKey(for environment: RadarEnvironment) -> String {
        if let saved = UserDefaults.standard.string(forKey: Keys.publishableKey(environment)) {
            return saved
        }
        let key: String
        switch environment {
        case .production: key = AppDelegate.DEFAULT_PUBLISHABLE_KEY
        case .staging, .local: key = AppDelegate.DEFAULT_STAGING_PUBLISHABLE_KEY
        }
        // hooks/clean-filter replaces real keys with "prj_live_pk_..." in git.
        return key.hasSuffix("...") ? "" : key
    }

    /// Persists the environment settings. Takes effect on the next launch.
    func saveEnvironment(
        _ environment: RadarEnvironment,
        publishableKey: String,
        localURL: String,
        useAuthToken: Bool,
        authToken: String
    ) {
        let defaults = UserDefaults.standard
        defaults.set(environment.rawValue, forKey: Keys.environment)
        defaults.set(publishableKey.trimmingCharacters(in: .whitespaces), forKey: Keys.publishableKey(environment))
        defaults.set(useAuthToken, forKey: Keys.useAuthToken(environment))
        defaults.set(authToken.trimmingCharacters(in: .whitespacesAndNewlines), forKey: Keys.authToken(environment))
        defaults.set(localURL.trimmingCharacters(in: .whitespaces), forKey: Keys.localURL)
    }

    /// The value the SDK sends as `Authorization`: `Bearer <token>` in auth-token mode, otherwise
    /// the publishable key. "" if the selected credential isn't set.
    var resolvedAuthorization: String {
        if useAuthToken {
            return resolvedAuthToken.map { "Bearer \($0)" } ?? ""
        }
        return resolvedPublishableKey
    }

    /// Checks which environments the selected credential is valid on, and logs an error if it
    /// isn't valid on the selected one.
    func runKeyCheck(logStream: LogStream) {
        let key = resolvedAuthorization
        guard !key.isEmpty else {
            let what = useAuthToken ? "auth token" : "publishable key"
            logStream.write(error: "No \(what) set for \(environment.label)", detail: "Set one in Settings → Environment.")
            return
        }
        keyCheck = .checking
        KeyChecker.check(publishableKey: key) { [weak self] result in
            guard let self = self else { return }
            self.keyCheck = result
            if result.mismatches(self.environment) {
                logStream.write(
                    error: "Key \(Self.keyPrefix(key)) is not valid on \(self.environment.label)",
                    detail: "Key check: \(result.summary). Switch environment or change the key in Settings → Environment.")
            } else {
                logStream.write(result: "key check: \(result.summary)", detail: self.environmentSummary)
            }
        }
    }

    /// Where requests go, e.g. `env = Staging; host = https://…; key = prj_test_pk_ab12…; key check = …`.
    var environmentSummary: String {
        "env = \(environment.label); host = \(environment.host(localURL: localURL)); \(credentialSummary); key check = \(keyCheck.summary)"
    }

    /// `key = prj_…` or `auth token = kid …, expires …`.
    var credentialSummary: String {
        guard useAuthToken else { return "key = \(Self.keyPrefix(resolvedPublishableKey))" }
        guard let token = resolvedAuthToken else { return "auth token = (none)" }
        return "auth token = \(AuthTokenInfo.describe(token))"
    }

    /// A key shortened for display, e.g. `prj_live_pk_76b8…`.
    static func keyPrefix(_ key: String) -> String {
        if key.isEmpty { return "(none)" }
        return key.count <= 16 ? key : key.prefix(16) + "…"
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
        // `RadarSdkConfiguration` isn't public, so read the dictionary the SDK
        // persists under `radar-sdkConfiguration` directly.
        guard let config = Utils.radarUserDefaults?.dictionary(forKey: "radar-sdkConfiguration") else {
            return [.text("status", "No SDK config fetched yet")]
        }
        return Self.fields(from: config)
    }

    /// Missing keys fall back to the same defaults `RadarSdkConfiguration` uses
    /// when parsing the dictionary.
    private static func fields(from config: [String: Any]) -> [TrackingField] {
        func bool(_ key: String, default value: Bool = false) -> TrackingField {
            .bool(key, config[key] as? Bool ?? value)
        }
        var fields: [TrackingField] = [
            // Logging
            .text("logLevel", config["logLevel"] as? String ?? "none"),
            // Lifecycle
            bool("startTrackingOnInitialize"),
            bool("trackOnceOnAppOpen"),
            // Sync mode
            bool("useSyncRegion"),
            bool("syncAfterSetUser"),
            // Geofence behavior
            bool("bufferGeofenceEntries", default: true),
            bool("bufferGeofenceExits", default: true),
            .text("defaultGeofenceDwellThreshold", "\(config["defaultGeofenceDwellThreshold"] as? Int ?? 0)"),
            bool("stopDetection"),
            // Persistence / logging
            bool("usePersistence"),
            bool("useLogPersistence"),
            bool("extendFlushReplays"),
            // Misc / less-common
            bool("useRadarModifiedBeacon"),
            bool("useOpenedAppConversion"),
            bool("useForegroundLocationUpdatedAtMsDiff"),
            bool("useOfflineRTOUpdates"),
            bool("offlineEventGenerationEnabled"),
            bool("skipForegroundCheck", default: true),
        ]
        let rtoCount = (config["remoteTrackingOptions"] as? [Any])?.count ?? 0
        fields.append(.text("remoteTrackingOptions", "\(rtoCount) preset(s)"))
        return fields
    }
}

// MARK: - Auth token display

/// Reads the unverified header and payload of an auth token (a JWT), for display only.
enum AuthTokenInfo {
    /// e.g. `kid 65f0…, expires 14:05:12 (in 9m)`, or why the token can't be read.
    static func describe(_ token: String, now: Date = Date()) -> String {
        let parts = token.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3 else { return "not a JWT" }
        guard let header = decode(parts[0]) else { return "unreadable header" }
        let payload = decode(parts[1])
        let kid = (header["kid"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? "(no kid)"
        guard let exp = (payload?["exp"] as? NSNumber)?.doubleValue, exp != 0 else { return "kid \(kid), no exp" }
        let expiry = Date(timeIntervalSince1970: exp)
        let remaining = Int(expiry.timeIntervalSince(now))
        let relative = remaining >= 0 ? "in \(duration(remaining))" : "expired \(duration(-remaining)) ago"
        return "kid \(kid), expires \(timeFormatter.string(from: expiry)) (\(relative))"
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    /// Decodes one base64url segment (no padding) into a JSON object.
    private static func decode(_ segment: Substring) -> [String: Any]? {
        var base64 = segment.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)
        guard let data = Data(base64Encoded: base64) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }

    private static func duration(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        if seconds < 3600 { return "\(seconds / 60)m" }
        return "\(seconds / 3600)h"
    }
}
