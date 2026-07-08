//
//  RadarRevealRiskNetworkPrivacy.swift
//  radar-sdk-ios-old
//
//  Created by Brian Siebert on 7/8/26.
//

struct RadarRevealRiskNetworkPrivacy: Codable, Sendable {
    let hosting: Bool
    let proxy: Bool
    let relay: Bool
    let service: String
    let tor: Bool
    let vpn: Bool
    let residentialProxy: Bool


    enum CodingKeys: String, CodingKey {
        case hosting
        case proxy
        case relay
        case service
        case tor
        case vpn
        case residentialProxy
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hosting = try container.decode(Bool.self, forKey: .hosting)
        proxy = try container.decode(Bool.self, forKey: .proxy)
        relay = try container.decode(Bool.self, forKey: .relay)
        service = try container.decode(String.self, forKey: .service)
        tor = try container.decode(Bool.self, forKey: .tor)
        vpn = try container.decode(Bool.self, forKey: .vpn)
        residentialProxy = try container.decode(Bool.self, forKey: .residentialProxy)
    }

    init(hosting: Bool, proxy: Bool, relay: Bool, service: String, tor: Bool, vpn: Bool, residentialProxy: Bool) {
        self.hosting = hosting
        self.proxy = proxy
        self.relay = relay
        self.service = service
        self.tor = tor
        self.vpn = vpn
        self.residentialProxy = residentialProxy
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(hosting, forKey: .hosting)
        try container.encode(proxy, forKey: .proxy)
        try container.encode(relay, forKey: .relay)
        try container.encode(service, forKey: .service)
        try container.encode(tor, forKey: .tor)
        try container.encode(vpn, forKey: .vpn)
        try container.encode(residentialProxy, forKey: .residentialProxy)
    }
}
