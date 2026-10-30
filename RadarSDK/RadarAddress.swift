//
//  RadarAddress.swift
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

/// The confidence levels for geocoding results.
@objc(RadarAddressConfidence)
public enum RadarAddressConfidence: Int, Sendable {
    /// Unknown
    case none = 0
    /// Exact
    case exact = 1
    /// Interpolated
    case interpolated = 2
    /// Fallback
    case fallback = 3
}

/// Represents an address.
///
/// - SeeAlso: https://radar.com/documentation/api#geocoding
@objc(RadarAddress)
@objcMembers
public final class RadarAddress: NSObject {
    /// The location coordinate of the address.
    public let coordinate: CLLocationCoordinate2D

    /// The formatted string representation of the address.
    public let formattedAddress: String?

    /// The name of the country of the address.
    public let country: String?

    /// The unique code of the country of the address.
    public let countryCode: String?

    /// The flag of the country of the address.
    public let countryFlag: String?

    /// The name of the DMA of the address.
    public let dma: String?

    /// The unique code of the DMA of the address.
    public let dmaCode: String?

    /// The name of the state of the address.
    public let state: String?

    /// The unique code of the state of the address.
    public let stateCode: String?

    /// The postal code of the address.
    public let postalCode: String?

    /// The city of the address.
    public let city: String?

    /// The borough of the address.
    public let borough: String?

    /// The county of the address.
    public let county: String?

    /// The neighborhood of the address.
    public let neighborhood: String?

    /// The street number of the address.
    public let number: String?

    /// The street name of the address.
    public let street: String?

    /// The label of the address.
    public let addressLabel: String?

    /// The label of the place.
    public let placeLabel: String?

    /// The unit of the address.
    public let unit: String?

    /// The plus4 value for the zip of the address.
    public let plus4: String?

    /// The distance to the search anchor in meters.
    public let distance: NSNumber?

    /// The layer of the address, e.g. 'place', 'address', 'intersection', 'street', 'state', etc.
    public let layer: String?

    /// The metadata of the address.
    public let metadata: [AnyHashable: Any]?

    /// The confidence level of the geocoding result.
    public var confidence: RadarAddressConfidence

    /// The time zone information of the address.
    public let timeZone: RadarTimeZone?

    /// The categories of the address.
    public let categories: [String]?

    // Matches Objective-C `-init`, which left every field zeroed.
    override init() {
        coordinate = CLLocationCoordinate2D()
        formattedAddress = nil
        country = nil
        countryCode = nil
        countryFlag = nil
        dma = nil
        dmaCode = nil
        state = nil
        stateCode = nil
        postalCode = nil
        city = nil
        borough = nil
        county = nil
        neighborhood = nil
        number = nil
        street = nil
        addressLabel = nil
        placeLabel = nil
        unit = nil
        plus4 = nil
        distance = nil
        layer = nil
        metadata = nil
        confidence = .none
        timeZone = nil
        categories = nil
        super.init()
    }

    // Keeps the Objective-C initializer declared in RadarAddress+Internal.h working. Wrongly
    // typed fields are ignored, and a missing latitude or longitude gives an invalid coordinate.
    @objc(initWithObject:)
    init?(object: Any) {
        guard let dictionary = object as? NSDictionary else {
            return nil
        }

        if let latitude = dictionary["latitude"] as? NSNumber,
            let longitude = dictionary["longitude"] as? NSNumber
        {
            coordinate = CLLocationCoordinate2D(
                latitude: latitude.doubleValue, longitude: longitude.doubleValue)
        } else {
            coordinate = kCLLocationCoordinate2DInvalid
        }

        formattedAddress = dictionary["formattedAddress"] as? String
        country = dictionary["country"] as? String
        countryCode = dictionary["countryCode"] as? String
        countryFlag = dictionary["countryFlag"] as? String
        dma = dictionary["dma"] as? String
        dmaCode = dictionary["dmaCode"] as? String
        state = dictionary["state"] as? String
        stateCode = dictionary["stateCode"] as? String
        postalCode = dictionary["postalCode"] as? String
        city = dictionary["city"] as? String
        borough = dictionary["borough"] as? String
        county = dictionary["county"] as? String
        neighborhood = dictionary["neighborhood"] as? String
        number = dictionary["number"] as? String
        street = dictionary["street"] as? String
        addressLabel = dictionary["addressLabel"] as? String
        placeLabel = dictionary["placeLabel"] as? String
        unit = dictionary["unit"] as? String
        plus4 = dictionary["plus4"] as? String
        distance = dictionary["distance"] as? NSNumber
        layer = dictionary["layer"] as? String
        metadata = dictionary["metadata"] as? [AnyHashable: Any]

        switch dictionary["confidence"] as? String {
        case "exact":
            confidence = .exact
        case "interpolated":
            confidence = .interpolated
        case "fallback":
            confidence = .fallback
        default:
            confidence = .none
        }

        if let timeZoneObject = dictionary["timeZone"] as? NSDictionary {
            timeZone = RadarTimeZone(object: timeZoneObject)
        } else {
            timeZone = nil
        }

        categories = (dictionary["categories"] as? NSArray)?.compactMap { $0 as? String }

        super.init()
    }

    // Swift sees the Objective-C `+addressFromObject:` factory as this initializer.
    @nonobjc
    public convenience init?(from object: Any) {
        guard object is NSDictionary else {
            return nil
        }
        self.init(object: object)
    }

    @available(swift, obsoleted: 1.0, message: "Use init(from:) instead.")
    @objc(addressFromObject:)
    public static func address(fromObject object: Any) -> RadarAddress? {
        RadarAddress(from: object)
    }

    // Returns nil if the object isn't an array or any element isn't a dictionary.
    @objc(addressesFromObject:)
    static func addresses(fromObject object: Any) -> [RadarAddress]? {
        guard let array = object as? NSArray else {
            return nil
        }

        var addresses: [RadarAddress] = []
        addresses.reserveCapacity(array.count)
        for addressObject in array {
            guard let address = RadarAddress(object: addressObject) else {
                return nil
            }
            addresses.append(address)
        }
        return addresses
    }

    @objc(arrayForAddresses:)
    public static func array(forAddresses addresses: [RadarAddress]?) -> [[AnyHashable: Any]]? {
        addresses?.map { $0.dictionaryValue() }
    }

    static func string(for confidence: RadarAddressConfidence) -> String {
        switch confidence {
        case .exact:
            return "exact"
        case .interpolated:
            return "interpolated"
        case .fallback:
            return "fallback"
        default:
            return "none"
        }
    }

    @objc(addressVerificationStatusForString:)
    static func addressVerificationStatus(for string: String?) -> RadarAddressVerificationStatus {
        switch string {
        case "verified":
            return .verified
        case "partially verified":
            return .partiallyVerified
        case "ambiguous":
            return .ambiguous
        case "unverified":
            return .unverified
        default:
            return .none
        }
    }

    public func dictionaryValue() -> [AnyHashable: Any] {
        var dictionary: [AnyHashable: Any] = [
            "latitude": coordinate.latitude,
            "longitude": coordinate.longitude,
            "confidence": Self.string(for: confidence),
        ]
        dictionary["formattedAddress"] = formattedAddress
        dictionary["country"] = country
        dictionary["countryCode"] = countryCode
        dictionary["countryFlag"] = countryFlag
        dictionary["dma"] = dma
        dictionary["dmaCode"] = dmaCode
        dictionary["state"] = state
        dictionary["stateCode"] = stateCode
        dictionary["postalCode"] = postalCode
        dictionary["city"] = city
        dictionary["borough"] = borough
        dictionary["county"] = county
        dictionary["neighborhood"] = neighborhood
        dictionary["number"] = number
        dictionary["street"] = street
        dictionary["addressLabel"] = addressLabel
        dictionary["placeLabel"] = placeLabel
        dictionary["unit"] = unit
        dictionary["plus4"] = plus4
        dictionary["distance"] = distance
        dictionary["layer"] = layer
        dictionary["metadata"] = metadata
        dictionary["timeZone"] = timeZone?.dictionaryValue()
        dictionary["categories"] = categories
        return dictionary
    }
}
