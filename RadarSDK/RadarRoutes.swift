//
//  RadarRoute.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

// Swift implementation of RadarRoute + RadarRoutes

struct RadarCoordinate: Codable {
    let latitude: Double
    let longitude: Double
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.longitude = try container.decode(Double.self)
        self.latitude = try container.decode(Double.self)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(longitude)
        try container.encode(latitude)
    }
}

struct RadarRoute: Codable {
    let distance: Distance
    struct Distance: Codable {
        let text: String
        let value: Double
    }
    
    let duration: Duration
    struct Duration: Codable {
        let text: String
        let value: Double
    }
    
    let geometry: Geometry
    struct Geometry: Codable {
        let coordinates: [RadarCoordinate]
    }
    
    
}

struct RadarRoutes: Codable {
    let geodesic: Geodesic?
    struct Geodesic: Codable {
        let distance: Distance
        struct Distance: Codable {
            let text: String
            let value: Double
        }
    }
    
    let foot: RadarRoute?
    let bike: RadarRoute?
    let car: RadarRoute?
    let truck: RadarRoute?
    let motorbike: RadarRoute?
}

extension RadarRouteMode {
    func commaSeparatedString() -> String {
        var modes = [String]()
        if rawValue & RadarRouteMode.foot.rawValue != 0 {
            modes.append("foot")
        }
        if rawValue & RadarRouteMode.bike.rawValue != 0 {
            modes.append("bike")
        }
        if rawValue & RadarRouteMode.car.rawValue != 0 {
            modes.append("car")
        }
        if rawValue & RadarRouteMode.truck.rawValue != 0 {
            modes.append("truck")
        }
        if rawValue & RadarRouteMode.motorbike.rawValue != 0 {
            modes.append("motorbike")
        }
        return String(modes.joined(separator: ","))
    }
}

extension RadarRouteUnits {
    func toString() -> String {
        switch self {
        case .metric:
            return "metric"
        case .imperial:
            return "imperial"
        default:
            return "unknown"
        }
    }
}
