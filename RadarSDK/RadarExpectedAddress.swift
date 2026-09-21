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
        
        static func from(_ value: RadarExpectedAddressConfidence) -> Self? {
            return switch value {
            case .high: .high
            case .medium: .medium
            case .low: .low
            default: nil
            }
        }
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
final class RadarExpectedAddress: NSObject {
    let data: RadarExpectedAddressData
    
    var expectedAddress: String { data.expectedAddress }
    var formattedAddress: String? { data.formattedAddress }
    var latitude: NSNumber? { data.latitude.map(NSNumber.init(value:)) }
    var longitude: NSNumber? { data.longitude.map(NSNumber.init(value:)) }
    var atAddress: Bool { data.atAddress ?? false }
    var confidence: RadarExpectedAddressConfidence { data.confidence?.toObjC() ?? .unknown }
    var distance: NSNumber? { data.distance.map(NSNumber.init(value:)) }
    
    @objc(initWithObject:)
    init?(object: Any) {
        guard let dictionary = object as? [AnyHashable: Any],
            let json = try? JSONSerialization.data(withJSONObject: dictionary),
            let data = try? JSONDecoder().decode(RadarExpectedAddressData.self, from: json)
        else {
            return nil
        }
        self.data = data
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
