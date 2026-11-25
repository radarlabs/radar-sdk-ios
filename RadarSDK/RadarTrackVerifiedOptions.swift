//
//  RadarTrackVerifiedOptions.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

/// Options for `Radar.trackVerified(options:completionHandler:)`.
@objc(RadarTrackVerifiedOptions)
@objcMembers
public class RadarTrackVerifiedOptions: NSObject {
    /// A boolean indicating whether to range beacons. Default `false`.
    public var beacons: Bool = false

    /// The desired accuracy. Default `.medium`.
    public var desiredAccuracy: RadarTrackingOptionsDesiredAccuracy = .medium

    /// An optional reason, displayed in the dashboard and reports.
    public var reason: String?

    /// An optional transaction ID, displayed in the dashboard and reports.
    public var transactionId: String?

    public override init() {
        super.init()
    }
}
