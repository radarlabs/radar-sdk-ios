//
//  RadarVerificationLevel.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

/// The level of a verified location check.
@objc(RadarVerificationLevel)
public enum RadarVerificationLevel: Int {
    /// No known level. For `requiredVerificationLevel`, this means that no step-up is required.
    case unknown = 0

    /// A check that uses device, network, and IP signals, but not the device location.
    case ip = 1  // swiftlint:disable:this identifier_name

    /// A check that uses the device location.
    case precise = 2

    /// A missing, non-string, or unknown value gives `unknown`.
    init(responseValue: Any?) {
        switch responseValue as? String {
        case "ip":
            self = .ip
        case "precise":
            self = .precise
        default:
            self = .unknown
        }
    }
}
