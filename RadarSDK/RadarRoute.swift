//
//  RadarRoute.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

struct RadarRoute: Codable {
    struct Distance: Codable {
        let value: Double
        let text: String
    }
    let distance: Distance
    
    struct Duration: Codable {
        let value: Double
        let text: String
    }
    let duration: Duration
    
    struct Geometry: Codable {
        let coordinates: [RadarCoordinateSwift]
    }
    let geometry: Geometry
}

// ObjC classes, backed by RadarRoute struct
@objc(RadarRouteDistance)
class RadarRouteDistance: NSObject {
    @objc public var value: Double { route.distance.value }
    @objc public var text: String { route.distance.text }
    
    @objc public func dictionaryValue() -> [String: Any] {
        return RadarUtils.dictionary(from: route.distance) ?? [:]
    }
    
    let route: RadarRoute
    init(route: RadarRoute) {
        self.route = route
    }
    
    @objc
    internal convenience init?(object: Any) {
        guard let dict = object as? [String: Any] else {
            return nil
        }
        guard let value = dict["value"] as? Double,
              let text = dict["text"] as? String else {
            return nil
        }
        self.init(route: RadarRoute(
            distance: RadarRoute.Distance(value: value, text: text),
            duration: RadarRoute.Duration(value: 0, text: ""),
            geometry: RadarRoute.Geometry(coordinates: []))
        )
    }
}

@objc(RadarRouteDuration)
class RadarRouteDuration: NSObject {
    @objc public var value: Double { route.duration.value }
    @objc public var text: String { route.duration.text }
    
    @objc public func dictionaryValue() -> [String: Any] {
        return RadarUtils.dictionary(from: route.duration) ?? [:]
    }
    
    let route: RadarRoute
    init(route: RadarRoute) {
        self.route = route
    }
}

@objc(RadarRouteGeometry)
class RadarRouteGeometry: NSObject {
    @objc public var coordinates: [RadarCoordinate] { route.geometry.coordinates as? [RadarCoordinate] ?? [] }
    
    let route: RadarRoute
    init(route: RadarRoute) {
        self.route = route
    }
}

@objc(RadarRoute)
class RadarRouteObjc: NSObject {
    let route: RadarRoute
    
    @objc public let distance: RadarRouteDistance
    @objc public let duration: RadarRouteDuration
    @objc public let geometry: RadarRouteGeometry
    
    init(route: RadarRoute) {
        self.route = route
        self.distance = RadarRouteDistance(route: route)
        self.duration = RadarRouteDuration(route: route)
        self.geometry = RadarRouteGeometry(route: route)
    }
    
    @objc
    internal convenience init?(object: Any) {
        guard let dict = object as? [String: Any] else {
            print("Cannot convert to dict")
            return nil
        }
        
        let jsonString = RadarUtils.dictionaryToJson(dict)
        
        let decoder = JSONDecoder()
        decoder.userInfo[RadarCoordinateSwift.codingStrategy] = RadarCoordinateSwift.CodingStrategy.LngLatArray
        
        guard let data = jsonString.data(using: .utf8),
              let route = try? decoder.decode(RadarRoute.self, from: data) else {
            print("Cannot decode")
            return nil
        }
        self.init(route: route)
    }
}
