//
//  TestPreset.swift
//  Example
//
//  Created by Alan Charles on 5/4/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import RadarSDK

/// A bundled scenario for functional testing. Applies identity, tracking, and
/// (eventually) UI state in one shot so a tester doesn't have to set them
/// individually.
///
/// Presets are pure value objects. The side effects of applying one (writing
/// through to the SDK and `SettingsStore`) live in `SettingsStore.apply(_:)`.
///
/// To add a preset, define it as a `static let` extension on `TestPreset` and
/// append it to `TestPreset.all`.
struct TestPreset: Identifiable {

    /// What to do with the SDK's tracking state when a preset is applied.
    enum TrackingAction {
        /// Don't touch the SDK's tracking state.
        case leaveUnchanged
        /// Call `Radar.startTracking(trackingOptions:)`.
        case start(RadarTrackingOptions)
        /// Call `Radar.stopTracking()`.
        case stop
    }

    let id: String
    let name: String
    let summary: String

    let userId: String?
    let userDescription: String?
    let metadata: [String: String]

    let trackingAction: TrackingAction

    /// Suggested raw value for `MainView.TabIdentifier` to switch to after applying.
    /// `nil` leaves the current tab alone. Tab navigation is the caller's concern;
    /// `apply(_:)` does not navigate.
    let suggestedTabRaw: String?

    init(
        id: String,
        name: String,
        summary: String,
        userId: String? = nil,
        userDescription: String? = nil,
        metadata: [String: String] = [:],
        trackingAction: TrackingAction = .leaveUnchanged,
        suggestedTabRaw: String? = nil
    ) {
        self.id = id
        self.name = name
        self.summary = summary
        self.userId = userId
        self.userDescription = userDescription
        self.metadata = metadata
        self.trackingAction = trackingAction
        self.suggestedTabRaw = suggestedTabRaw
    }
}

// MARK: - Built-in catalog
//
// `RadarTrackingOptions.presetContinuous` / `.presetResponsive` / `.presetEfficient`
// are declared `(class, copy)` in the SDK, so each access returns a fresh instance.
// The static lets below capture private copies; mutating one would not affect
// anything else in the app.

extension TestPreset {

    /// All built-in presets, in display order. Append new entries here.
    static let all: [TestPreset] = [
        .defaultPreset,
        .continuous,
        .responsive,
        .efficient,
    ]

    /// Clean slate: clear identity, stop tracking.
    static let defaultPreset = TestPreset(
        id: "default",
        name: "Default",
        summary: "Clear identity and stop tracking.",
        trackingAction: .stop
    )

    /// Continuous tracking — updates every ~30s. Highest battery cost.
    static let continuous = TestPreset(
        id: "continuous",
        name: "Continuous",
        summary: "Updates every ~30s. Highest battery cost.",
        userId: "test-continuous",
        metadata: ["preset": "continuous"],
        trackingAction: .start(.presetContinuous)
    )

    /// Responsive tracking — wakes on movement. Moderate battery cost.
    static let responsive = TestPreset(
        id: "responsive",
        name: "Responsive",
        summary: "Wakes on movement. Moderate battery cost.",
        userId: "test-responsive",
        metadata: ["preset": "responsive"],
        trackingAction: .start(.presetResponsive)
    )

    /// Efficient tracking — visit-monitoring only. Lowest battery cost.
    static let efficient = TestPreset(
        id: "efficient",
        name: "Efficient",
        summary: "Visit-monitoring only. Lowest battery cost.",
        userId: "test-efficient",
        metadata: ["preset": "efficient"],
        trackingAction: .start(.presetEfficient)
    )
}
