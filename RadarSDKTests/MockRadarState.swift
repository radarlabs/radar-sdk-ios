//
//  MockRadarState.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 3/26/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

@testable import RadarSDK

class MockRadarState: RadarState, @unchecked Sendable {
    private var _registeredNotifications: [NotificationValue]? = nil
    override public var registeredNotifications: [NotificationValue]? {
        get { return _registeredNotifications }
        set { _registeredNotifications = newValue }
    }
}
