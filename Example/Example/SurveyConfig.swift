// swift-format-ignore-file
//
//  SurveyConfig.swift
//  Example
//
//  Created by ShiCheng Lu on 10/30/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

/// The single place to configure an indoor survey. Edit these values to point the Survey
/// tab at a different site, beacons, or geofence.
///
enum SurveyConfig {

    /// iBeacon proximity UUID(s) the survey ranges. One UUID matches every beacon with it;
    /// individual beacons are distinguished downstream by major/minor.
    static let beaconUUIDs: [String] = []

    /// Geofence the survey attaches to. Must match a geofence in `siteJSON` below.
    static let geofenceId = ""

    /// Sent to the API with the survey record.
    static let surveyor = ""
    static let surveyDescription = ""

    /// The site being surveyed (floorplan image, geometry, calibration, geofence).
    static let siteJSON = """

"""
}
