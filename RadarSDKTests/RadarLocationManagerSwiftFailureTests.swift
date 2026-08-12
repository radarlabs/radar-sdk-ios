//
//  RadarLocationManagerSwiftFailureTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import Testing

@testable import RadarSDK

extension RadarSerializedTests {
    @Suite(.serialized)
    actor RadarLocationManagerSwiftFailureTests {

        // MARK: - didFail(error:)

        @Test("didFail notifies the delegate of a location error")
        func didFailNotifiesDelegateOfLocationError() {
            let mock = MockRadarSwiftBridge()
            let original = RadarSwift.bridge
            RadarSwift.bridge = mock
            defer { RadarSwift.bridge = original }

            let error = NSError(domain: "com.radar.test", code: 1)
            RadarLocationManagerSwift.didFail(error: error)

            #expect(mock.lastFailStatus == .errorLocation)
        }
    }
}
