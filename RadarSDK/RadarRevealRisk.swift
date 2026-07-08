//
//  RadarRevealRisk.swift
//  radar-sdk-ios-old
//
//  Created by Brian Siebert on 7/8/26.
//

struct RadarRevealRisk: Codable, Sendable {
    let id: String
    let token: String
    let expiresAt: Date
    let expiresIn: Double
    let risk: RadarRevealRiskRisk?
    let network: RadarRevealRiskNetwork?
    let device: RadarRevealRiskDevice?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case token
        case expiresIn
        case expiresAt
        case risk
        case network
        case device
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        token = try container.decode(String.self, forKey: .token) ?? ""
        expiresAt = try container.decode(String.self, forKey: .expiresAt)
        expiresIn = try container.decode(String.self, forKey: .expiresIn)

        let riskJSON = try container.decode(keyedBy: .risk)
        risk = RadarRevealRiskRisk(riskJSON)
        
        let networkJSON = try container.decode(keyedBy: .network)
        network = RadarRevealRiskNetwork(networkJSON)
        
        let deviceJSON = try container.decode(keyedBy: .device)
        device = RadarRevealRiskDevice(deviceJSON)
    }

    init(id: String, token: String, expiresAt: Date, expiresIn: Double, risk: RadarRevealRiskRisk, network: RadarRevealRiskNetwork, device: RadarRevealRiskDevice) {
        self.id = id
        self.token = token
        self.expiresAt = expiresAt
        self.expiresIn = expiresIn
        self.risk = risk
        self.network = network
        self.device = device
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(token, forKey: .name)
        try container.encode(expiresAt, forKey: .expiresAt)
        try container.encode(expiresIn, forKey: .expiresIn)
        try container.encode(RadarRevealRiskRisk(risk), forKey: .risk)
        try container.encode(RadarRevealRiskNetwork(network), forKey: .network)
        try container.encode(RadarRevealRiskDevice(device), forKey: .device)
    }
}
