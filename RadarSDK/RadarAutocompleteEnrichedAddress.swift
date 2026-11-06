//
//  RadarAutocompleteEnrichedAddress.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

/// The enriched form of a selected address.
///
/// Carries only these two fields. It is not a `RadarAddress`, and none of that type's other fields
/// are returned.
///
/// - SeeAlso: https://radar.com/documentation/api#autocomplete
@objc(RadarAutocompleteEnrichedAddress)
@objcMembers
public final class RadarAutocompleteEnrichedAddress: NSObject, Sendable {
    /// The formatted string representation of the address.
    public let formattedAddress: String?

    /// What address enrichment knows about the location.
    public let locationDetails: RadarAddressLocationDetails

    init?(object: Any?) {
        guard let dictionary = object as? NSDictionary,
            let locationDetails = RadarAddressLocationDetails(object: dictionary["locationDetails"])
        else {
            return nil
        }

        self.formattedAddress = dictionary["formattedAddress"] as? String
        self.locationDetails = locationDetails

        super.init()
    }

    public func dictionaryValue() -> [AnyHashable: Any] {
        var dictionary: [AnyHashable: Any] = ["locationDetails": locationDetails.dictionaryValue()]
        dictionary["formattedAddress"] = formattedAddress
        return dictionary
    }
}
