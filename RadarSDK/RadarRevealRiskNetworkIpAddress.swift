//
//  RadarRevealRiskNetworkIpAddress.swift
//  radar-sdk-ios-old
//
//  Created by Brian Siebert on 7/8/26.
//

struct RadarRevealRiskNetworkIpAddress: Codable, Sendable {
    let countryCode: String
    let country: String
    let countryFlag: String
    let state: String
    let city: String
    let postalCode: String
    let latitude: Double
    let longitude: Double
    let connectionType: String
    let stateCode: String
    let stateConfidence: String
    let countryConfidence: String
    let dma: String
    let dmaCode: String
    let stateAllowed: boolean
    let countryAllowed: boolean
    let layer: String
    let geometry: RadarRevealRiskNetworkIpAddressGeometry
    
    
    enum CodingKeys: String, CodingKey {
        case countryCode
        case country
        case countryFlag
        case state
        case city
        case postalCode
        case latitude
        case longitude
        case connectionType
        case stateCode
        case stateConfidence
        case countryConfidence
        case dma
        case dmaCode
        case stateAllowed
        case countryAllowed
        case layer
        case geometry
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        countryCode = try container.decode(String.self, forKey: .countryCode)
        country = try container.decode(String.self, forKey: .country)
        countryFlag = try container.decode(String.self, forKey: .countryFlag)
        state = try container.decode(String.self, forKey: .state)
        city = try container.decode(String.self, forKey: .city)
        postalCode = try container.decode(String.self, forKey: .postalCode)
        latitude = try container.decode(String.self, forKey: .latitude)
        longitude = try container.decode(String.self, forKey: .longitude)
        connectionType = try container.decode(String.self, forKey: .connectionType)
        stateCode = try container.decode(String.self, forKey: .stateCode)
        stateConfidence = try container.decode(String.self, forKey: .stateConfidence)
        countryConfidence = try container.decode(String.self, forKey: .countryConfidence)
        dma = try container.decode(String.self, forKey: .dma)
        dmaCode = try container.decode(String.self, forKey: .dmaCode)
        stateAllowed = try container.decode(String.self, forKey: .stateAllowed)
        countryAllowed = try container.decode(String.self, forKey: .countryAllowed)
        layer = try container.decode(String.self, forKey: .layer)
        
        let geometryJSON = try container.decode(keyedBy: .geometry)
        geometry = RadarRevealRiskNetworkIpAddressGeometry(geometryJSON)
    }
    
    init(countryCode: String, country: String, countryFlag: String, state: String, city: String, postalCode: String, latitude: String, longitude: String, connectionType: String, stateCode: String, stateConfidence: String, countryConfidence: String, dma: String, dmaCode: String, stateAllowed: String, countryAllowed: String, layer: String, geometry: RadarRevealRiskNetworkIpAddressGeometry) {
        self.countryCode = countryCode
        self.country = country
        self.countryFlag = countryFlag
        self.state = state
        self.city = city
        self.postalCode = postalCode
        self.latitude = latitude
        self.longitude = longitude
        self.connectionType = connectionType
        self.stateCode = stateCode
        self.stateConfidence = stateConfidence
        self.countryConfidence = countryConfidence
        self.dma = dma
        self.dmaCode = dmaCode
        self.stateAllowed = stateAllowed
        self.countryAllowed = countryAllowed
        self.layer = layer
        self.geometry = geometry
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(countryCode, forKey: .countryCode)
        try container.encode(country, forKey: .country)
        try container.encode(countryFlag, forKey: .countryFlag)
        try container.encode(state, forKey: .state)
        try container.encode(city, forKey: .city)
        try container.encode(postalCode, forKey: .postalCode)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(connectionType, forKey: .connectionType)
        try container.encode(stateCode, forKey: .stateCode)
        try container.encode(stateConfidence, forKey: .stateConfidence)
        try container.encode(countryConfidence, forKey: .countryConfidence)
        try container.encode(dma, forKey: .dma)
        try container.encode(dmaCode, forKey: .dmaCode)
        try container.encode(stateAllowed, forKey: .stateAllowed)
        try container.encode(countryAllowed, forKey: .countryAllowed)
        try container.encode(layer, forKey: .layer)
        try container.encode(RadarRevealRiskNetworkIpAddressGeometry(geometry), forKey: .geometry)
    }
}
