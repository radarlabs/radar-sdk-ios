//
//  RadarRevealRisk.swift
//  RadarSDK
//

import Foundation

// These types expose Objective-C compatible models and decode API responses.
// The top-level token validates the response format; nested models use
// synthesized decoding.

/// Represents device and network risk signals.
///
/// - SeeAlso: https://radar.com/documentation/fraud
@objc(RadarRevealRiskToken) @objcMembers
public final class RadarRevealRiskToken: NSObject, Decodable, @unchecked Sendable {
    // swiftlint:disable:next identifier_name
    public let _id: String
    @nonobjc var id: String { _id }
    public let token: String?
    public let expiresAt: Date?
    let expiresInValue: Double?
    public var expiresIn: NSNumber? { expiresInValue.map { NSNumber(value: $0) } }
    public let risk: RadarRevealRiskTokenRisk?
    public let network: RadarRevealRiskTokenNetwork?
    public let device: RadarRevealRiskTokenDevice?
    
    /// The response format selected by the server.
    public let format: RadarResponseFormat

    // unchecked sendable, set on init, should not be modified afterwards
    private(set) var dictionaryValueStorage: [String: Sendable]?

    enum CodingKeys: String, CodingKey {
        // swiftlint:disable:next identifier_name
        case _id
        case token
        case expiresInValue = "expiresIn"
        case expiresAt
        case risk
        case network
        case device
        case format
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let responseFormat = container.contains(.format)
            ? try container.decode(String.self, forKey: .format)
            : nil
        
        guard let format = RadarResponseFormat(responseValue: responseFormat) else {
            throw DecodingError.dataCorruptedError(
                forKey: .format,
                in: container,
                debugDescription: "Unsupported response format"
            )
        }
        
        self.format = format
        _id = try container.decode(String.self, forKey: ._id)
        
        if format != .jws && _id.isEmpty {
            throw DecodingError.dataCorruptedError(
                forKey: ._id,
                in: container,
                debugDescription: "Response ID must not be empty"
            )
        }
        
        switch format {
        case .jws:
            token = try container.decodeIfPresent(String.self, forKey: .token)
            expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt)
            expiresInValue = try container.decodeIfPresent(
                Double.self,
                forKey: .expiresInValue
            )
            risk = try container.decode(RadarRevealRiskTokenRisk.self, forKey: .risk)
            network = try container.decode(
                RadarRevealRiskTokenNetwork.self,
                forKey: .network
            )
            device = try container.decode(
                RadarRevealRiskTokenDevice.self,
                forKey: .device
            )
        case .jwe:
            let responseToken = try container.decode(String.self, forKey: .token)
            guard !responseToken.isEmpty else {
                throw DecodingError.dataCorruptedError(
                    forKey: .token,
                    in: container,
                    debugDescription: "Response token must not be empty"
                )
            }
            
            token = responseToken
            expiresAt = try container.decode(Date.self, forKey: .expiresAt)
            expiresInValue = try container.decode(
                Double.self,
                forKey: .expiresInValue
            )
            risk = nil
            network = nil
            device = nil
            
        case .id:
            token = nil
            expiresAt = nil
            expiresInValue = nil
            risk = nil
            network = nil
            device = nil
        }
        
        super.init()
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
        var dict = (try? JSONSerialization.jsonObject(with: data))
            as? [String: Sendable]
        
        switch decoded.format {
        case .jws:
            break
        case .jwe:
            let allowedKeys: Set<String> = [
                "format", "_id", "token", "expiresAt", "expiresIn"
            ]
            dict = dict?.filter { allowedKeys.contains($0.key) }
        case .id:
            let allowedKeys: Set<String> = ["format", "_id"]
            dict = dict?.filter { allowedKeys.contains($0.key) }
        }
        
        // Preserve Reveal's existing omission of response metadata
        dict?["meta"] = nil
        decoded.dictionaryValueStorage = dict
        return decoded
    }

    public func dictionaryValue() -> [AnyHashable: Any] {
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
    let latitudeValue: Double?
    public var latitude: NSNumber? { latitudeValue.map { NSNumber(value: $0) } }
    let longitudeValue: Double?
    public var longitude: NSNumber? { longitudeValue.map { NSNumber(value: $0) } }
    public let connectionType: String?
    public let stateCode: String?
    public let stateConfidence: String?
    public let countryConfidence: String?
    public let dma: String?
    public let dmaCode: String?
    let stateAllowedValue: Bool?
    public var stateAllowed: Bool { stateAllowedValue ?? false }
    let countryAllowedValue: Bool?
    public var countryAllowed: Bool { countryAllowedValue ?? false }
    public let layer: String?
    public let geometry: RadarRevealRiskIpGeometry?

    enum CodingKeys: String, CodingKey {
        // swiftlint:disable:next identifier_name
        case ip
        case countryCode
        case country
        case countryFlag
        case state
        case city
        case postalCode
        case latitudeValue = "latitude"
        case longitudeValue = "longitude"
        case connectionType
        case stateCode
        case stateConfidence
        case countryConfidence
        case dma
        case dmaCode
        case stateAllowedValue = "stateAllowed"
        case countryAllowedValue = "countryAllowed"
        case layer
        case geometry
    }
}

@objc(RadarRevealRiskIpGeometry) @objcMembers
public final class RadarRevealRiskIpGeometry: NSObject, Decodable, Sendable {
    public let type: String
    let coordinateValues: [Double]
    public var coordinates: [NSNumber] { coordinateValues.map { NSNumber(value: $0) } }

    enum CodingKeys: String, CodingKey {
        case type
        case coordinateValues = "coordinates"
    }
}

@objc(RadarRevealRiskTokenNetworkPrivacy) @objcMembers
public final class RadarRevealRiskTokenNetworkPrivacy: NSObject, Decodable, Sendable {
    let hostingValue: Bool?
    public var hosting: Bool { hostingValue ?? false }

    let proxyValue: Bool?
    public var proxy: Bool { proxyValue ?? false }

    let relayValue: Bool?
    public var relay: Bool { relayValue ?? false }

    public let service: String?

    let torValue: Bool?
    public var tor: Bool { torValue ?? false }

    let vpnValue: Bool?
    public var vpn: Bool { vpnValue ?? false }

    let residentialProxyValue: Bool?
    public var residentialProxy: Bool { residentialProxyValue ?? false }

    enum CodingKeys: String, CodingKey {
        case hostingValue = "hosting"
        case proxyValue = "proxy"
        case relayValue = "relay"
        case service
        case torValue = "tor"
        case vpnValue = "vpn"
        case residentialProxyValue = "residentialProxy"
    }
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
