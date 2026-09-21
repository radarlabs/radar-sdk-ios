//
//  RadarExpectedAddress.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

/// Owns the JSON contract for the `expectedAddress` field of a track response. `RadarExpectedAddress`
/// is the Objective-C compatibility surface over this type and copies its fields verbatim.
struct RadarExpectedAddress: Codable, Sendable, Equatable {
    enum Confidence: String, Codable, Sendable {
        case high
        case medium
        case low

        func toObjC() -> RadarExpectedAddressConfidence {
            return switch self {
            case .high: .high
            case .medium: .medium
            case .low: .low
            }
        }
    }

    let expectedAddress: String
    let formattedAddress: String?
    let latitude: Double?
    let longitude: Double?
    let atAddress: Bool?
    let confidence: Confidence?
    let distance: Double?
}

@objc(RadarExpectedAddress)
@objcMembers
final class RadarExpectedAddressObjc: NSObject {
    let data: RadarExpectedAddress

    @objc public var expectedAddress: String { data.expectedAddress }
    @objc public var formattedAddress: String? { data.formattedAddress }
    @objc public var latitude: NSNumber? { data.latitude.map(NSNumber.init(value:)) }
    @objc public var longitude: NSNumber? { data.longitude.map(NSNumber.init(value:)) }
    @objc public var atAddress: Bool { data.atAddress ?? false }
    @objc public var confidence: RadarExpectedAddressConfidence { data.confidence?.toObjC() ?? .unknown }
    @objc public var distance: NSNumber? { data.distance.map(NSNumber.init(value:)) }

    /// Keeps `[[RadarExpectedAddress alloc] init]` from trapping on Swift's unimplemented-initializer
    /// stub, matching the zero-value `init` the other Objective-C model surfaces expose.
    @objc public override init() {
        data = RadarExpectedAddress(
            expectedAddress: "",
            formattedAddress: nil,
            latitude: nil,
            longitude: nil,
            atAddress: nil,
            confidence: nil,
            distance: nil
        )
        super.init()
    }

    @objc(initWithObject:)
    init?(object: Any) {
        guard let dict = object as? [String: Any] else {
            return nil
        }
        let jsonString = RadarUtils.dictionaryToJson(dict)
        let decoder = JSONDecoder()
        guard let data = jsonString.data(using: .utf8),
            let data = try? decoder.decode(RadarExpectedAddress.self, from: data)
        else {
            return nil
        }
        self.data = data
    }

    func dictionaryValue() -> [AnyHashable: Any] {
        return RadarUtils.dictionary(from: data) ?? [:]
    }
}
