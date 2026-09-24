//
//  RadarRemoteTrackingOptions.swift
//  RadarSDK
//
//  Created by Alan Charles on 4/10/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc(RadarRemoteTrackingOptions) @objcMembers
class RadarRemoteTrackingOptions: NSObject {

    let type: String
    let trackingOptions: RadarTrackingOptions
    let geofenceTags: [String]?

    init?(dict: [String: Any]) {
        guard let type = dict["type"] as? String,
            let trackingOptionsDict = dict["trackingOptions"] as? [String: Any],
            let trackingOptions = RadarTrackingOptions(from: trackingOptionsDict)
        else {
            return nil
        }
        self.type = type
        self.trackingOptions = trackingOptions
        self.geofenceTags = dict["geofenceTags"] as? [String]
    }

    func dictionaryValue() -> [String: Any] {
        var dict: [String: Any] = [
            "type": type,
            "trackingOptions": trackingOptions.dictionaryValue(),
        ]
        if let geofenceTags = geofenceTags {
            dict["geofenceTags"] = geofenceTags
        }
        return dict
    }

    // MARK: - Collection helpers

    static func from(array: [[String: Any]]?) -> [RadarRemoteTrackingOptions]? {
        guard let array, !array.isEmpty else { return nil }
        return array.compactMap { RadarRemoteTrackingOptions(dict: $0) }
    }

    static func toDictionaries(_ options: [RadarRemoteTrackingOptions]?) -> [[String: Any]]? {
        return options?.map { $0.dictionaryValue() }
    }

    // MARK: - Lookup by type

    static func geofenceTags(forKey key: String, in options: [RadarRemoteTrackingOptions]?) -> [String]? {
        return options?.first { $0.type == key }?.geofenceTags
    }

    static func trackingOptions(forKey key: String, in options: [RadarRemoteTrackingOptions]?) -> RadarTrackingOptions? {
        return options?.first { $0.type == key }?.trackingOptions
    }
}
