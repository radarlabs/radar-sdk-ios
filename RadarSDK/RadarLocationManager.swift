//
//  RadarLocationManager.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objcMembers
final class RadarLocationManagerSwiftBackend: NSObject {
    func didUpdateInjectedDependencies() {
    }

    func failFast(withMethod method: String) -> Never {
        preconditionFailure("RadarLocationManager Swift backend is not implemented for \(method)")
    }
}
