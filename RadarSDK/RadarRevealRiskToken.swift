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
@objc(RadarRevealRiskToken) @objcMembers
public final class RadarRevealRiskToken: NSObject, Decodable, @unchecked Sendable {
    // swiftlint:disable:next identifier_name
    public let _id: String
    @nonobjc var id: String { _id }
    public let token: String?
    public let expiresAt: Date?
    let expiresIn: Double?
    // swiftlint:disable:next identifier_name
    @objc(expiresIn) public var _expiresIn: NSNumber? { expiresIn.map { NSNumber(value: $0) } }
    public let risk: RadarRevealRiskTokenRisk
    public let network: RadarRevealRiskTokenNetwork
    public let device: RadarRevealRiskTokenDevice

    // unchecked sendable, set on init, should not be modified afterwards
    var dictionaryValueStorage: [String: Sendable]?

    enum CodingKeys: String, CodingKey {
        // swiftlint:disable:next identifier_name
        case _id
        case token
        case expiresIn
        case expiresAt
        case risk
        case network
        case device
    }

    nonisolated(unsafe) private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    nonisolated(unsafe) private static let isoFormatterNoFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
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
        decoded.dictionaryValueStorage = dict
        return decoded
    }

    public func dictionaryValue() -> [String: Any] {
        dictionaryValueStorage?.reduce(into: [:]) { dictionary, entry in
            dictionary[entry.key] = entry.value
        } ?? [:]
    }
}

/// Risk level for a Reveal Risk token, ordered from lowest to highest.
@objc(RadarRevealRiskLevel)
public enum RadarRevealRiskLevel: Int, Sendable, Decodable {
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

    public init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer()
        let string = try value.decode(String.self)
        self.init(string: string)
    }
}

@objc(RadarRevealRiskTokenRisk) @objcMembers
public final class RadarRevealRiskTokenRisk: NSObject, Decodable, Sendable {
    public let level: RadarRevealRiskLevel
    public let reasons: [String]
}

@objc(RadarRevealRiskTokenNetwork) @objcMembers
public final class RadarRevealRiskTokenNetwork: NSObject, Decodable, Sendable {
    public let ipAddress: RadarRevealRiskTokenNetworkIpAddress?
    public let privacy: RadarRevealRiskTokenNetworkPrivacy?
    public let asn: RadarRevealRiskTokenNetworkAsn?
}

@objc(RadarRevealRiskTokenNetworkAsn) @objcMembers
public final class RadarRevealRiskTokenNetworkAsn: NSObject, Decodable, Sendable {
    public let asn: String?
    public let country: String?
    public let domain: String?
    public let name: String?
    public let network: String?
    public let type: String?
}

@objc(RadarRevealRiskTokenNetworkIpAddress) @objcMembers
public final class RadarRevealRiskTokenNetworkIpAddress: NSObject, Decodable, Sendable {
    // swiftlint:disable:next identifier_name
    let ip: String?
    public let countryCode: String?
    public let country: String?
    public let countryFlag: String?
    public let state: String?
    public let city: String?
    public let postalCode: String?
    let latitude: Double?
    // swiftlint:disable:next identifier_name
    @objc(latitude) public var _latitude: NSNumber? { latitude.map { NSNumber(value: $0) } }
    let longitude: Double?
    // swiftlint:disable:next identifier_name
    @objc(longitude) public var _longitude: NSNumber? { longitude.map { NSNumber(value: $0) } }
    public let connectionType: String?
    public let stateCode: String?
    public let stateConfidence: String?
    public let countryConfidence: String?
    public let dma: String?
    public let dmaCode: String?
    let stateAllowed: Bool?
    // swiftlint:disable:next identifier_name
    @objc(stateAllowed) public var _stateAllowed: Bool { stateAllowed ?? false }
    let countryAllowed: Bool?
    // swiftlint:disable:next identifier_name
    @objc(countryAllowed) public var _countryAllowed: Bool { countryAllowed ?? false }
    public let layer: String?
    public let geometry: RadarRevealRiskIpGeometry?
}

@objc(RadarRevealRiskIpGeometry) @objcMembers
public final class RadarRevealRiskIpGeometry: NSObject, Decodable, Sendable {
    public let type: String
    public let coordinates: [Double]
}

@objc(RadarRevealRiskTokenNetworkPrivacy) @objcMembers
public final class RadarRevealRiskTokenNetworkPrivacy: NSObject, Decodable, Sendable {
    let hosting: Bool?
    // swiftlint:disable:next identifier_name
    @objc(hosting) public var _hosting: Bool { hosting ?? false }

    let proxy: Bool?
    // swiftlint:disable:next identifier_name
    @objc(proxy) public var _proxy: Bool { proxy ?? false }

    let relay: Bool?
    // swiftlint:disable:next identifier_name
    @objc(relay) public var _relay: Bool { relay ?? false }

    public let service: String?

    let tor: Bool?
    // swiftlint:disable:next identifier_name
    @objc(tor) public var _tor: Bool { tor ?? false }

    let vpn: Bool?
    // swiftlint:disable:next identifier_name
    @objc(vpn) public var _vpn: Bool { vpn ?? false }

    let residentialProxy: Bool?
    // swiftlint:disable:next identifier_name
    @objc(residentialProxy) public var _residentialProxy: Bool { residentialProxy ?? false }
}

@objc(RadarRevealRiskTokenDevice) @objcMembers
public final class RadarRevealRiskTokenDevice: NSObject, Decodable, Sendable {
    public let deviceId: String?
    public let deviceType: String?
    public let deviceMake: String?
    public let deviceModel: String?
    public let deviceOSName: String?
    public let deviceOSVersion: String?
    public let sdkVersion: String?
    public let xPlatformType: String?
    public let installId: String?
    public let appId: String?
    public let appName: String?
    public let appVersion: String?
    public let appBuild: String?
}
