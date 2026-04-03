//
//  RadarTestUtils.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 4/3/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

class RadarTestUtils {
    static func data(fromResource resource: String) -> Data? {
        guard let path = Bundle(for: self).path(forResource: resource, ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path))  else {
            return nil
        }
        return data
    }
    
    static func json(fromResourse resource: String) -> [String: Any]? {
        guard let data = data(fromResource: resource),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json
    }
}
