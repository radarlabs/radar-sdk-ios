//
//  RadarFileStorage.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 9/15/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

internal class RadarFileStorage {
    static func path(for filename: String) -> URL {
        let appGroupValue: String? = "" // RadarSettings.appGroup
        if let appGroup = appGroupValue, !appGroup.isEmpty {
            // has appGroup set
            let path = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)!
            return path.appendingPathComponent(filename)
        } else {
            let path = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            return path.appendingPathComponent(filename)
        }
    }
    
    static func createDirectory() throws {
        let directory = self.path(for: "")
        try FileManager.default.createDirectory(at:directory, withIntermediateDirectories: true)
    }
    
    static func readFile(at path: String) throws -> Data {
        return try Data(contentsOf: URL(fileURLWithPath: path))
    }

    static func writeFile(at path: String, with data: Data) throws {
        try data.write(to: URL(fileURLWithPath: path))
    }
    
    static func readJSON(at path: String) throws -> Any? {
        let data = try readFile(at: path)
        return try JSONSerialization.jsonObject(with: data)
    }
    
    static func writeJSON(at path: String, with json: Any) throws {
        let data = try JSONSerialization.data(withJSONObject:json)
        try writeFile(at: path, with: data)
    }
}
