//
//  RadarExpectedAddress.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

/// Owns the JSON contract for the `expectedAddress` field of a track response. `RadarExpectedAddress`
/// is the Objective-C compatibility surface over this type and copies its fields verbatim.
struct RadarExpectedAddressData: Codable, Sendable, Equatable {
    enum Confidence: String, Codable, Sendable {
        case high
        case medium
        case low
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
final class RadarExpectedAddress: NSObject {
    let expectedAddress: String
    let formattedAddress: String?
    let latitude: NSNumber?
    let longitude: NSNumber?
    let atAddress: Bool
    let confidence: RadarExpectedAddressConfidence
    let distance: NSNumber?

    @objc(initWithExpectedAddress:formattedAddress:latitude:longitude:atAddress:confidence:distance:)
    init(
        expectedAddress: String,
        formattedAddress: String?,
        latitude: NSNumber?,
        longitude: NSNumber?,
        atAddress: Bool,
        confidence: RadarExpectedAddressConfidence,
        distance: NSNumber?
    ) {
        self.expectedAddress = expectedAddress
        self.formattedAddress = formattedAddress
        self.latitude = latitude
        self.longitude = longitude
        self.atAddress = atAddress
        self.confidence = confidence
        self.distance = distance

        super.init()
    }

    /// Copies the decoded fields onto the Objective-C compatibility surface.
    convenience init(data: RadarExpectedAddressData) {
        self.init(
            expectedAddress: data.expectedAddress,
            formattedAddress: data.formattedAddress,
            latitude: data.latitude.map(NSNumber.init(value:)),
            longitude: data.longitude.map(NSNumber.init(value:)),
            atAddress: data.atAddress ?? false,
            confidence: RadarExpectedAddressConfidence(data.confidence),
            distance: data.distance.map(NSNumber.init(value:))
        )
    }

    /// The `Codable` representation these fields were copied from.
    var data: RadarExpectedAddressData {
        RadarExpectedAddressData(
            expectedAddress: expectedAddress,
            formattedAddress: formattedAddress,
            latitude: latitude?.doubleValue,
            longitude: longitude?.doubleValue,
            atAddress: atAddress,
            confidence: confidence.dataConfidence,
            distance: distance?.doubleValue
        )
    }

    @objc(initWithObject:)
    convenience init?(object: Any) {
        guard let dictionary = object as? [AnyHashable: Any],
            let json = try? JSONSerialization.data(withJSONObject: dictionary),
            let data = try? JSONDecoder().decode(RadarExpectedAddressData.self, from: json),
            // An address Radar never echoed back is not a result worth surfacing.
            !data.expectedAddress.isEmpty
        else {
            return nil
        }

        self.init(data: data)
    }

    func dictionaryValue() -> [AnyHashable: Any] {
        guard let json = try? JSONEncoder().encode(data),
            let dictionary = try? JSONSerialization.jsonObject(with: json) as? [AnyHashable: Any]
        else {
            return [:]
        }

        return dictionary
    }
}

extension RadarExpectedAddressConfidence {
    fileprivate init(_ confidence: RadarExpectedAddressData.Confidence?) {
        switch confidence {
        case .high:
            self = .high
        case .medium:
            self = .medium
        case .low:
            self = .low
        case nil:
            self = .unknown
        }
    }

    fileprivate var dataConfidence: RadarExpectedAddressData.Confidence? {
        switch self {
        case .high:
            return .high
        case .medium:
            return .medium
        case .low:
            return .low
        default:
            return nil
        }
    }
}
