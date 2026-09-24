//
//  RadarExpectedAddress.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

/// Owns the JSON contract for the `expectedAddress` field of a track response. `RadarExpectedAddress`
/// is the public surface over this type and copies its fields verbatim.
struct RadarExpectedAddressData: Codable, Sendable, Equatable {
    enum Confidence: String, Codable, Sendable {
        case high
        case medium
        case low
        case unknown

        func toObjC() -> RadarExpectedAddressConfidence {
            return switch self {
            case .high: .high
            case .medium: .medium
            case .low: .low
            case .unknown: .unknown
            }
        }
    }

    let expectedAddress: String
    let formattedAddress: String?
    let latitude: Double?
    let longitude: Double?
    let atAddress: Bool
    let confidence: Confidence
    let distance: Double?
}

/// Represents a comparison between the user's location and the expected address set with `setExpectedAddress:`.
@objc(RadarExpectedAddress)
@objcMembers
public final class RadarExpectedAddress: NSObject {
    let data: RadarExpectedAddressData

    /// The user's expected address, as passed to `setExpectedAddress:`.
    public var expectedAddress: String { data.expectedAddress }
    /// The formatted expected address, as geocoded by Radar. May be `nil` if the expected address could not be geocoded.
    public var formattedAddress: String? { data.formattedAddress }
    /// The latitude of the geocoded expected address. May be `nil` if the expected address could not be geocoded.
    public var latitude: NSNumber? { data.latitude.map(NSNumber.init(value:)) }
    /// The longitude of the geocoded expected address. May be `nil` if the expected address could not be geocoded.
    public var longitude: NSNumber? { data.longitude.map(NSNumber.init(value:)) }
    /// A boolean indicating whether the user is at their expected address.
    public var atAddress: Bool { data.atAddress }
    /// The confidence of the match between the user's location and their expected address. May be
    /// `RadarExpectedAddressConfidenceUnknown` if confidence is not available.
    public var confidence: RadarExpectedAddressConfidence { data.confidence.toObjC() }
    /// The distance in meters between the user's location and their expected address. May be `nil` if the expected
    /// address could not be geocoded.
    public var distance: NSNumber? { data.distance.map(NSNumber.init(value:)) }

    // Internal, so it isn't public API, but still an override, so an Objective-C `-init` produces
    // an empty value instead of trapping on Swift's unimplemented-initializer stub.
    override init() {
        data = RadarExpectedAddressData(
            expectedAddress: "",
            formattedAddress: nil,
            latitude: nil,
            longitude: nil,
            atAddress: false,
            confidence: .unknown,
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
            let data = try? decoder.decode(RadarExpectedAddressData.self, from: data)
        else {
            return nil
        }
        self.data = data
    }

    public func dictionaryValue() -> [AnyHashable: Any] {
        return RadarUtils.dictionary(from: data) ?? [:]
    }
}
