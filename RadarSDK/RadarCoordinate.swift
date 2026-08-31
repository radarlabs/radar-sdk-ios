//
//  RadarCoordinate.swift
//  RadarSDK
//
//  Created by Alan Charles on 3/19/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

@objc(RadarCoordinate)
@objcMembers
final class RadarCoordinateSwift: NSObject, Codable, Sendable {
    
    let latitude: Double
    let longitude: Double
    
    // in Objective-C, coordinates is the only visible property
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var clLocationCoordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var clLocation: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    init(coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
    
    static func coordinatesFrom(object: Any) -> [RadarCoordinateSwift]? {
        guard let array = object as? [Any] else {
            return nil
        }
        return array.compactMap(RadarCoordinateSwift.init)
    }
    
    func dictionaryValue() -> [String: Any] {
        return [:]
    }
    
    init?(object: Any?) {
        guard let dict = object as? [String: Any] else {
            return nil
        }
        guard let coords = dict["coordinates"] as? [Double] else {
            return nil
        }
        guard coords.count == 2 else {
            return nil
        }
        self.longitude = coords[0]
        self.latitude = coords[1]
    }
    
    
}

