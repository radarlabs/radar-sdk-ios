//
//  RadarRevealRisk.swift
//  RadarSDK
//

import Foundation

// swiftlint:disable identifier_name

/// Objective-C compatible model for the Reveal Risk API response.
///
/// Each type is both the `@objc` interface and the `Decodable` parser: the compiler
/// synthesizes `init(from:)` for these `NSObject` subclasses, so there is no separate parsing
/// struct or mapping layer to keep in sync. `CodingKeys` is only declared where a JSON key
/// differs from the property name; the `Date` format is handled once on the decoder.
@objc(RadarRevealRiskToken) @objcMembers
final class RadarRevealRiskToken: NSObject, Decodable, @unchecked Sendable {
    @objc(_id)
    let id: String
    let token: String?
    let expiresAt: Date?
    let expiresIn: Double?
    @objc(expiresIn) var _expiresIn: NSNumber? { expiresIn.map { NSNumber(value: $0) } }
    let risk: RadarRevealRiskTokenRisk
    let network: RadarRevealRiskTokenNetwork
    let device: RadarRevealRiskTokenDevice

    // unchecked sendable, set on init, should not be modified afterwards
    var dictionaryValue: [String: Sendable]?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case token
        case expiresIn
        case expiresAt
        case risk
        case network
        case device
    }

    nonisolated(unsafe) private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    nonisolated(unsafe) private static let isoFormatterNoFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    /// Parses a Reveal Risk API response into an Objective-C compatible object.
    /// Returns `nil` if the data cannot be decoded.
    static func fromData(_ data: Data) -> RadarRevealRiskToken? {
        let decoder = JSONDecoder()

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let formatterNoFractional = ISO8601DateFormatter()
        formatterNoFractional.formatOptions = [.withInternetDateTime]

        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = isoFormatter.date(from: string) {
                return date
            }
            if let date = isoFormatterNoFractional.date(from: string) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(string)")
        }

        guard let decoded = try? decoder.decode(RadarRevealRiskToken.self, from: data) else {
            return nil
        }
        var dict: [String: Sendable]? = (try? JSONSerialization.jsonObject(with: data)) as? [String: Sendable]
        // raw data from response returns with a meta field for the http status, ignore this for reveal risk response dict
        dict?["meta"] = nil
        decoded.dictionaryValue = dict
        return decoded
    }
}

/// Risk level for a Reveal Risk token, ordered from lowest to highest.
@objc(RadarRevealRiskLevel)
enum RadarRevealRiskLevel: Int, Sendable, Decodable {
    case none
    case low
    case medium
    case high

    init(string: String) {
        switch string {
        case "low": self = .low
        case "medium": self = .medium
        case "high": self = .high
        default: self = .none
        }
    }

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer()
        let string = try value.decode(String.self)
        self.init(string: string)
    }
}

@objc(RadarRevealRiskTokenRisk) @objcMembers
final class RadarRevealRiskTokenRisk: NSObject, Decodable, Sendable {
    let level: RadarRevealRiskLevel
    let reasons: [String]
}

@objc(RadarRevealRiskTokenNetwork) @objcMembers
final class RadarRevealRiskTokenNetwork: NSObject, Decodable, Sendable {
    let ipAddress: RadarRevealRiskTokenNetworkIpAddress?
    public let privacy: RadarRevealRiskTokenNetworkPrivacy?
    let asn: RadarRevealRiskTokenNetworkAsn?
}

@objc(RadarRevealRiskTokenNetworkAsn) @objcMembers
final class RadarRevealRiskTokenNetworkAsn: NSObject, Decodable, Sendable {
    let asn: String?
    let country: String?
    let domain: String?
    let name: String?
    let network: String?
    let type: String?
}

@objc(RadarRevealRiskTokenNetworkIpAddress) @objcMembers
final class RadarRevealRiskTokenNetworkIpAddress: NSObject, Decodable, Sendable {
    let ip: String?
    let countryCode: String?
    let country: String?
    let countryFlag: String?
    let state: String?
    let city: String?
    let postalCode: String?
    let latitude: Double?
    @objc(latitude) var _latitude: NSNumber? { latitude.map { NSNumber(value: $0) } }
    let longitude: Double?
    @objc(longitude) var _longitude: NSNumber? { longitude.map { NSNumber(value: $0) } }
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
    let geometry: RadarRevealRiskIpGeometry?
}

@objc(RadarRevealRiskIpGeometry) @objcMembers
final class RadarRevealRiskIpGeometry: NSObject, Decodable, Sendable {
    let type: String
    let coordinates: [Double]
}

@objc(RadarRevealRiskTokenNetworkPrivacy) @objcMembers
final class RadarRevealRiskTokenNetworkPrivacy: NSObject, Decodable, Sendable {
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

@objc(RadarRevealRiskTokenDevice) @objcMembers
final class RadarRevealRiskTokenDevice: NSObject, Decodable, Sendable {
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

// swiftlint:enable identifier_name
