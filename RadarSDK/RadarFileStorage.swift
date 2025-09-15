//
//  RadarFileStorage.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 9/15/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

internal class RadarFileStorage {
    func readFile(at path: String) throws -> Data {
        return try Data(contentsOf: URL(fileURLWithPath: path))
    }
    
    func writeFile(at path: String, with data: Data) throws {
        try data.write(to: URL(fileURLWithPath: path))
    }
}
