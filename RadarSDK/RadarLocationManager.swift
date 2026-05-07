//
//  RadarLocationManager.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc(RadarLocationManagerImplementation)
@objcMembers
public final class RadarLocationManagerImplementation: NSObject {
    public func didUpdateInjectedDependencies() {
    }

    @objc(failFastWithMethod:)
    public func failFast(withMethod method: String) {
        preconditionFailure("RadarLocationManager implementation is not implemented for \(method)")
    }
}
