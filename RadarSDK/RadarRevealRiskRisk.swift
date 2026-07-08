//
//  RadarRevealRiskRisk.swift
//  radar-sdk-ios-old
//
//  Created by Brian Siebert on 7/8/26.
//

struct RadarRevealRiskRisk: Codable, Sendable {
    let level: String
    let reasons: [String]
    let score: Double

    enum CodingKeys: String, CodingKey {
        case level
        case reasons
        case score
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        level = try container.decode(String.self, forKey: .level)
        reasons = try container.decode([String].self, forKey: .reasons)
        score = try container.decode(String.self, forKey: .score)
    }

    init(level: String, reasons: [String], score: Double) {
        self.level = level
        self.reasons = reasons
        self.score = score
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(level, forKey: .level)
        try container.encode(reasons, forKey: .reasons)
        try container.encode(score, forKey: .score)
    }
}
