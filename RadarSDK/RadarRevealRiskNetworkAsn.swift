//
//  RadarRevealRiskNetworkAsn.swift
//  radar-sdk-ios-old
//
//  Created by Brian Siebert on 7/8/26.
//

struct RadarRevealRiskNetworkAsn: Codable, Sendable {
    let asn: String
    let country: String
    let domain: String
    let name: String
    let network: String
    let type: String



    enum CodingKeys: String, CodingKey {
        case asn
        case country
        case domain
        case name
        case network
        case type
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        asn = try container.decode(Bool.self, forKey: .asn)
        country = try container.decode(Bool.self, forKey: .country)
        domain = try container.decode(Bool.self, forKey: .domain)
        name = try container.decode(String.self, forKey: .name)
        network = try container.decode(Bool.self, forKey: .network)
        type = try container.decode(Bool.self, forKey: .type)
    }

    init(asn: String, country: String, domain: String, name: String, network: String, type: String) {
        self.asn = asn
        self.country = country
        self.domain = domain
        self.name = name
        self.network = network
        self.type = type
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(asn, forKey: .asn)
        try container.encode(country, forKey: .country)
        try container.encode(domain, forKey: .domain)
        try container.encode(name, forKey: .name)
        try container.encode(network, forKey: .network)
        try container.encode(type, forKey: .type)
    }
}
