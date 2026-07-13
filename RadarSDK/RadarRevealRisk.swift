//
//  RadarRevealRisk.swift
//  RadarSDK
//

import Foundation

/// Objective-C compatible model for the Reveal Risk API response.
///
/// Each type is both the `@objc` interface and the `Decodable` parser: the compiler
/// synthesizes `init(from:)` for these `NSObject` subclasses, so there is no separate parsing
/// struct or mapping layer to keep in sync. `CodingKeys` is only declared where a JSON key
/// differs from the property name; the `Date` format is handled once on the decoder.
@objc(RadarRevealRisk) @objcMembers
final class RadarRevealRisk: NSObject, Decodable, @unchecked Sendable {
    @objc(_id)
    let id: String
    let token: String?
    let expiresAt: Date?
    let expiresIn: Double?
    @objc(expiresIn) var _expiresIn: NSNumber? { expiresIn.flatMap(NSNumber.init) }
    let risk: RadarRevealRiskRisk
    let network: RadarRevealRiskNetwork
    let device: RadarRevealRiskDevice
    
    // unchecked sendable, set on init, should not be modified afterwards
    var dictionaryValue: [String: Sendable]? = nil

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case token
        case expiresIn
        case expiresAt
        case risk
        case network
        case device
    }

    /// Parses a Reveal Risk API response into an Objective-C compatible object.
    /// Returns `nil` if the data cannot be decoded.
    static func fromData(_ data: Data) -> RadarRevealRisk? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let decoded = try? decoder.decode(RadarRevealRisk.self, from: data) else {
            return nil
        }
        var dict: [String: Sendable]? = (try? JSONSerialization.jsonObject(with: data)) as? [String: Sendable]
        // raw data from response returns with a meta field for the http status, ignore this for reveal risk response dict
        dict?["meta"] = nil
        decoded.dictionaryValue = dict
        return decoded
    }
}

@objc(RadarRevealRiskRisk) @objcMembers
final class RadarRevealRiskRisk: NSObject, Decodable, Sendable {
    let level: String
    let reasons: [String]
}

@objc(RadarRevealRiskNetwork) @objcMembers
final class RadarRevealRiskNetwork: NSObject, Decodable, Sendable {
    let ipAddress: RadarRevealRiskNetworkIpAddress?
    public let privacy: RadarRevealRiskNetworkPrivacy?
    let asn: RadarRevealRiskNetworkAsn?
}

@objc(RadarRevealRiskNetworkAsn) @objcMembers
final class RadarRevealRiskNetworkAsn: NSObject, Decodable, Sendable {
    let asn: String?
    let country: String?
    let domain: String?
    let name: String?
    let network: String?
    let type: String?
}

@objc(RadarRevealRiskNetworkIpAddress) @objcMembers
final class RadarRevealRiskNetworkIpAddress: NSObject, Decodable, Sendable {
    let countryCode: String?
    let country: String?
    let countryFlag: String?
    let state: String?
    let city: String?
    let postalCode: String?
    let lattiude: Double?
    @objc(lattiude) var _lattiude: NSNumber? { lattiude.flatMap(NSNumber.init)  }
    let longitude: Double?
    @objc(longitude) var _longitude: NSNumber? { longitude.flatMap(NSNumber.init) }
    let connectionType: String?
    let stateCode: String?
    let stateConfidence: String?
    let countryConfidence: String?
    let dma: String?
    let dmaCode: String?
    let stateAllowed: Bool?
    @objc(stateAllowed) var _stateAllowed: Bool { stateAllowed ?? false }
    let countryAllowed: Bool?
    @objc(countryAllowed) var _countryAllowed: Bool { countryAllowed ?? false }
    let layer: String?
    let geometry: RadarRevealRiskNetworkIpAddressGeometry?
}

@objc(RadarRevealRiskNetworkIpAddressGeometry) @objcMembers
final class RadarRevealRiskNetworkIpAddressGeometry: NSObject, Decodable, Sendable {
    let type: String
    let coordinates: [Double]
}

@objc(RadarRevealRiskNetworkPrivacy) @objcMembers
final class RadarRevealRiskNetworkPrivacy: NSObject, Decodable, Sendable {
    let hosting: Bool?
    @objc(hosting) var _hosting: Bool { hosting ?? false }
    
    let proxy: Bool?
    @objc(proxy) var _proxy: Bool { proxy ?? false }
    
    let relay: Bool?
    @objc(relay) var _relay: Bool { relay ?? false }
    
    let service: String?
    
    let tor: Bool?
    @objc(tor) var _tor: Bool { tor ?? false }
    
    let vpn: Bool?
    @objc(vpn) var _vpn: Bool { vpn ?? false }
    
    let residentialProxy: Bool?
    @objc(residentialProxy) var _residentialProxy: Bool { residentialProxy ?? false }
}

@objc(RadarRevealRiskDevice) @objcMembers
final class RadarRevealRiskDevice: NSObject, Decodable, Sendable {
    let deviceId: String?
    let deviceType: String?
    let deviceMake: String?
    let deviceModel: String?
    let deviceOSName: String?
    let deviceOSVersion: String?
    let sdkVersion: String?
    let xPlatformType: String?
    let installId: String?
    let appId: String?
    let appName: String?
    let appVersion: String?
    let appBuild: String?
}

