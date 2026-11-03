//
//  RadarAddressTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import Testing

@testable import RadarSDK

@Suite("RadarAddressTests")
struct RadarAddressTests {

    private static let fullJSON = """
        {
            "latitude": 40.7342,
            "longitude": -73.9911,
            "formattedAddress": "841 Broadway, New York, NY 10003 US",
            "country": "United States",
            "countryCode": "US",
            "countryFlag": "🇺🇸",
            "dma": "New York",
            "dmaCode": "501",
            "state": "New York",
            "stateCode": "NY",
            "postalCode": "10003",
            "city": "New York",
            "borough": "Manhattan",
            "county": "New York County",
            "neighborhood": "Greenwich Village",
            "number": "841",
            "street": "Broadway",
            "addressLabel": "841 Broadway",
            "placeLabel": "Radar",
            "unit": "5",
            "plus4": "1234",
            "distance": 12.5,
            "layer": "address",
            "metadata": { "foo": "bar" },
            "confidence": "exact",
            "timeZone": {
                "id": "America/New_York",
                "name": "Eastern Daylight Time",
                "code": "EDT",
                "currentTime": "2026-10-30T12:00:00-04:00",
                "utcOffset": -14400,
                "dstOffset": 3600
            },
            "categories": ["office", "tech"]
        }
        """

    private static func jsonObject(_ json: String) throws -> Any {
        try JSONSerialization.jsonObject(with: Data(json.utf8))
    }

    private static func decode(_ json: String) throws -> RadarAddress {
        try #require(RadarAddress(object: try jsonObject(json)))
    }

    private static func dictionary(_ address: RadarAddress) throws -> [String: Any] {
        try #require(address.dictionaryValue() as? [String: Any])
    }

    @Test("Decodes a fully populated address")
    func decodesFullAddress() throws {
        let address = try Self.decode(Self.fullJSON)

        #expect(address.coordinate.latitude == 40.7342)
        #expect(address.coordinate.longitude == -73.9911)
        #expect(address.formattedAddress == "841 Broadway, New York, NY 10003 US")
        #expect(address.country == "United States")
        #expect(address.countryCode == "US")
        #expect(address.countryFlag == "🇺🇸")
        #expect(address.dma == "New York")
        #expect(address.dmaCode == "501")
        #expect(address.state == "New York")
        #expect(address.stateCode == "NY")
        #expect(address.postalCode == "10003")
        #expect(address.city == "New York")
        #expect(address.borough == "Manhattan")
        #expect(address.county == "New York County")
        #expect(address.neighborhood == "Greenwich Village")
        #expect(address.number == "841")
        #expect(address.street == "Broadway")
        #expect(address.addressLabel == "841 Broadway")
        #expect(address.placeLabel == "Radar")
        #expect(address.unit == "5")
        #expect(address.plus4 == "1234")
        #expect(address.distance == 12.5)
        #expect(address.layer == "address")
        #expect(address.metadata?["foo"] as? String == "bar")
        #expect(address.confidence == .exact)
        #expect(address.timeZone?._id == "America/New_York")
        #expect(address.categories == ["office", "tech"])
    }

    @Test("An empty dictionary produces an address with an invalid coordinate and no fields")
    func emptyDictionaryUsesDefaults() throws {
        let address = try #require(RadarAddress(object: [String: Any]()))

        #expect(!CLLocationCoordinate2DIsValid(address.coordinate))
        #expect(address.formattedAddress == nil)
        #expect(address.countryCode == nil)
        #expect(address.distance == nil)
        #expect(address.metadata == nil)
        #expect(address.confidence == .none)
        #expect(address.timeZone == nil)
        #expect(address.categories == nil)
    }

    @Test("Wrongly typed fields are ignored")
    func wronglyTypedFieldsAreIgnored() throws {
        let address = try Self.decode(
            """
            {
                "latitude": 40.7,
                "longitude": "-73.9",
                "formattedAddress": 1,
                "distance": "12",
                "metadata": [1, 2],
                "confidence": 1,
                "timeZone": "America/New_York",
                "categories": ["office", 1, null, "tech"]
            }
            """)

        #expect(!CLLocationCoordinate2DIsValid(address.coordinate))
        #expect(address.formattedAddress == nil)
        #expect(address.distance == nil)
        #expect(address.metadata == nil)
        #expect(address.confidence == .none)
        #expect(address.timeZone == nil)
        // Non-string categories are dropped, keeping the remaining order.
        #expect(address.categories == ["office", "tech"])
    }

    @Test(
        "Parses each confidence string",
        arguments: [
            ("exact", RadarAddressConfidence.exact),
            ("interpolated", .interpolated),
            ("fallback", .fallback),
            ("unknown", .none),
        ])
    func parsesConfidence(string: String, expected: RadarAddressConfidence) throws {
        let address = try #require(RadarAddress(object: ["confidence": string]))
        #expect(address.confidence == expected)
        #expect(try Self.dictionary(address)["confidence"] as? String == (expected == .none ? "none" : string))
    }

    @Test("Non-dictionary objects are rejected")
    func rejectsNonDictionary() {
        #expect(RadarAddress(object: "address") == nil)
        #expect(RadarAddress(object: [1, 2]) == nil)
        #expect(RadarAddress(from: "address") == nil)
        #expect(RadarAddress(from: ["city": "New York"])?.city == "New York")
    }

    @Test("Parses address arrays and rejects arrays with invalid elements")
    func parsesAddressArrays() throws {
        let addresses = try #require(
            RadarAddress.addresses(fromObject: [["city": "New York"], ["city": "Boston"]]))
        #expect(addresses.map(\.city) == ["New York", "Boston"])

        #expect(RadarAddress.addresses(fromObject: [String: Any]()) == nil)
        #expect(RadarAddress.addresses(fromObject: [["city": "New York"], "Boston"]) == nil)
        #expect(RadarAddress.addresses(fromObject: [Any]())?.isEmpty == true)
    }

    @Test("Round-trips through dictionaryValue")
    func roundTripsDictionaryValue() throws {
        let original = try Self.decode(Self.fullJSON)
        let dictionary = try Self.dictionary(original)

        #expect(dictionary["latitude"] as? Double == 40.7342)
        #expect(dictionary["longitude"] as? Double == -73.9911)
        #expect(dictionary["confidence"] as? String == "exact")
        #expect((dictionary["timeZone"] as? [String: Any])?["id"] as? String == "America/New_York")
        #expect(dictionary["categories"] as? [String] == ["office", "tech"])
        #expect(JSONSerialization.isValidJSONObject(dictionary))

        let decoded = try #require(RadarAddress(object: dictionary))
        #expect(decoded.dictionaryValue() as NSDictionary == original.dictionaryValue() as NSDictionary)
    }

    @Test("dictionaryValue omits missing optional fields")
    func dictionaryValueOmitsMissingFields() throws {
        let address = try #require(RadarAddress(object: ["latitude": 1.0, "longitude": 2.0]))
        let dictionary = try Self.dictionary(address)

        #expect(Set(dictionary.keys) == ["latitude", "longitude", "confidence"])
        #expect(dictionary["confidence"] as? String == "none")
    }

    @Test("array(forAddresses:) maps each address to its dictionary")
    func arrayForAddresses() throws {
        let addresses = try #require(
            RadarAddress.addresses(fromObject: [["city": "New York"], ["city": "Boston"]]))
        let array = try #require(RadarAddress.array(forAddresses: addresses))

        #expect(array.compactMap { $0["city"] as? String } == ["New York", "Boston"])
        #expect(RadarAddress.array(forAddresses: nil) == nil)
    }

    @Test("Maps verification status strings")
    func mapsVerificationStatus() {
        #expect(RadarAddress.addressVerificationStatus(for: "verified") == .verified)
        #expect(RadarAddress.addressVerificationStatus(for: "partially verified") == .partiallyVerified)
        #expect(RadarAddress.addressVerificationStatus(for: "ambiguous") == .ambiguous)
        #expect(RadarAddress.addressVerificationStatus(for: "unverified") == .unverified)
        #expect(RadarAddress.addressVerificationStatus(for: "other") == .none)
        #expect(RadarAddress.addressVerificationStatus(for: nil) == .none)
    }

    @Test("Confidence is settable")
    func confidenceIsSettable() throws {
        let address = try #require(RadarAddress(object: [String: Any]()))
        address.confidence = .interpolated
        #expect(try Self.dictionary(address)["confidence"] as? String == "interpolated")
    }

    @Test("Keeps the Objective-C runtime names and selectors")
    func preservesObjectiveCContract() {
        #expect(NSStringFromClass(RadarAddress.self) == "RadarAddress")

        let cls: AnyClass = RadarAddress.self
        #expect(class_getClassMethod(cls, NSSelectorFromString("addressFromObject:")) != nil)
        #expect(class_getClassMethod(cls, NSSelectorFromString("addressesFromObject:")) != nil)
        #expect(class_getClassMethod(cls, NSSelectorFromString("arrayForAddresses:")) != nil)
        #expect(class_getClassMethod(cls, NSSelectorFromString("addressVerificationStatusForString:")) != nil)
        #expect(RadarAddress.instancesRespond(to: NSSelectorFromString("initWithObject:")))
        #expect(RadarAddress.instancesRespond(to: NSSelectorFromString("dictionaryValue")))
        #expect(RadarAddress.instancesRespond(to: NSSelectorFromString("setConfidence:")))
        #expect(RadarAddress.instancesRespond(to: NSSelectorFromString("coordinate")))
        #expect(RadarAddressConfidence.fallback.rawValue == 3)
    }
}
