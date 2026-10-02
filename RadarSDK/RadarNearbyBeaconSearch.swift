//
//  RadarNearbyBeaconSearch.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

/// The nearby beacon search shared by one-shot ranging (`RadarOneShotBeaconManager`) and
/// continuous ranging (`RadarContinuousBeaconManager`).
///
/// When continuous ranging can't serve `trackVerified`, `trackVerified` makes one search, ranges
/// its result once with the one-shot manager, and hands the same result to the continuous manager
/// with `RadarContinuousBeaconManager.onSearched`. The continuous manager uses this search for its
/// own periodic refreshes too, so both managers range the same beacons, and a request that
/// continuous ranging can't serve searches only once.
@objc(RadarNearbyBeaconSearch)
final class RadarNearbyBeaconSearch: NSObject {

    /// Radius in meters and maximum number of beacons for nearby beacon searches. `CInt` to match
    /// the Objective-C search.
    @objc static let radius: CInt = 1000
    @objc static let limit: CInt = 10

    /// Searches iBeacons near `location`. Objective-C callers search with
    /// `-[RadarAPIClient searchBeaconsNear:radius:limit:completionHandler:]` and these constants.
    static func search(near location: CLLocation) async throws -> RadarAPIClient.SearchBeaconsResponse {
        try await RadarAPIClient.shared.searchBeacons(near: location, radius: Int(radius), limit: Int(limit))
    }
}
