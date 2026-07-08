//
//  RadarRevealRiskNetworkIpAddressGeometry.swift
//  radar-sdk-ios-old
//
//  Created by Brian Siebert on 7/8/26.
//

struct RadarRevealRiskNetworkIpAddressGeometry: Codable, Sendable {
    let type: String
    let coordinates: [Double]

    enum CodingKeys: String, CodingKey {
        case type
        case coordinates
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        level = try container.decode(String.self, forKey: .level)
        coordinates = try container.decode([String].self, forKey: .coordinates)
    }

    init(type: String, coordinates: [String]) {
        self.type = type
        self.coordinates = coordinates
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(coordinates, forKey: .coordinates)
    }
}
