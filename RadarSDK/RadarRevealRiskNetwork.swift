//
//  RadarRevealRiskNetwork.swift
//  radar-sdk-ios-old
//
//  Created by Brian Siebert on 7/8/26.
//

struct RadarRevealRiskNetwork: Codable, Sendable {
    let ipAddress: RadarRevealRiskNetworkIpAddress
    let privacy: RadarRevealRiskNetworkPrivacy
    let asn: RadarRevealRiskAsn

    enum CodingKeys: String, CodingKey {
        case ipAddress
        case privacy
        case asn
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let ipAddressJSON = try container.decode(keyedBy: .ipAddress)
        ipAddress = RadarRevealRiskNetworkIpAddress(ipAddressJSON)
        
        let privacyJSON = try container.decode(keyedBy: .privacy)
        privacy = RadarRevealRiskNetworkPrivacy(privacyJSON)
        
        let asnJSON = try container.decode(keyedBy: .asn)
        asn = RadarRevealRiskNetworkAsn(asnJSON)
    }

    init(ipAddress: RadarRevealRiskNetworkIpAddress, privacy: RadarRevealRiskNetworkPrivacy, asn: RadarRevealRiskNetworkAsn) {
        self.ipAddress = ipAddress
        self.privacy = privacy
        self.asn = asn
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(RadarRevealRiskNetworkIpAddress(ipAddress), forKey: .ipAddress)
        try container.encode(RadarRevealRiskNetworkPrivacy(privacy), forKey: .privacy)
        try container.encode(RadarRevealRiskNetworkAsn(asn), forKey: .asn)
