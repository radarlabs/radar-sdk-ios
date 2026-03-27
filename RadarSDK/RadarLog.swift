//
//  RadarLog.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 3/27/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

struct RadarLog: Codable {
    let message: String
    let level: String
    let date: Date
    let battery: Int
}
