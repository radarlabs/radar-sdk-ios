//
//  RadarSite.swift
//  Example
//
//  Created by ShiCheng Lu on 10/30/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//
import Foundation
import RadarSDK
//
@objc protocol GeoJSON {
    var type: String { get }
}

@objc public class GeoJSONPoint: NSObject, GeoJSON, Codable {
    let coordinates: [Double]
    var type: String = "Point"
}

@objc public class GeoJSONPolygon: NSObject, GeoJSON, Codable {
    let coordinates: [[[Double]]]
    var type: String = "Polygon"
}

@objc public class RadarFloorplanCalibration: NSObject, Codable {
    let imageSize: [String: Int]
}

@objc public class RadarFloorplan: NSObject, Codable {
    let path: String
    let mimeType: String
    let geometry: GeoJSONPolygon
    let calibration: RadarFloorplanCalibration
}

@objc public class RadarSite: NSObject, Codable {
    let id: String
    let createdAt: Date
    let updatedAt: Date
    let project: String
    let live: Bool
    let _description: String
    let geometry: GeoJSONPoint
    //let geofences: [RadarGeofence]
    //let beacons: [RadarBeacon]
    let floorplan: RadarFloorplan
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case createdAt
        case updatedAt
        case project
        case live
        case _description = "description"
        case geometry
        case floorplan
    }
}

struct RadarSiteResponse: Codable {
    let site: RadarSite
}
