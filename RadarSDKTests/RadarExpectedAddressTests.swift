//
//  RadarExpectedAddressTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

extension RadarSerializedTests {
    @Suite(.serialized)
    struct RadarExpectedAddressTests {

        private func fullDict() -> [String: Any] {
            return [
                "expectedAddress": "111 5th Ave, NY",
                "formattedAddress": "111 5th Ave, New York, NY 10003 USA",
                "latitude": 40.7356,
                "longitude": -73.9906,
                "atAddress": true,
                "confidence": "high",
                "distance": 12.5,
            ]
        }

        private func fullData() -> RadarExpectedAddress {
            return RadarExpectedAddress(
                expectedAddress: "111 5th Ave, NY",
                formattedAddress: "111 5th Ave, New York, NY 10003 USA",
                latitude: 40.7356,
                longitude: -73.9906,
                atAddress: true,
                confidence: .high,
                distance: 12.5
            )
        }

        @Test("Decodes the backing struct from JSON")
        func decodesBackingStruct() throws {
            let json = """
                {
                    "expectedAddress": "111 5th Ave, NY",
                    "formattedAddress": "111 5th Ave, New York, NY 10003 USA",
                    "latitude": 40.7356,
                    "longitude": -73.9906,
                    "atAddress": true,
                    "confidence": "high",
                    "distance": 12.5
                }
                """

            let data = try JSONDecoder().decode(RadarExpectedAddress.self, from: Data(json.utf8))

            #expect(data == fullData())
        }

        @Test("Leaves every optional field absent when only the address is returned")
        func decodesBackingStructWithoutOptionals() throws {
            let data = try JSONDecoder().decode(
                RadarExpectedAddress.self,
                from: Data(#"{"expectedAddress": "not an address"}"#.utf8)
            )

            #expect(data.expectedAddress == "not an address")
            #expect(data.formattedAddress == nil)
            #expect(data.latitude == nil)
            #expect(data.longitude == nil)
            #expect(data.atAddress == nil)
            #expect(data.confidence == nil)
            #expect(data.distance == nil)
        }

        @Test("Round trips the backing struct through Codable")
        func roundTripsBackingStruct() throws {
            let encoded = try JSONEncoder().encode(fullData())

            #expect(try JSONDecoder().decode(RadarExpectedAddress.self, from: encoded) == fullData())

            let dictionary = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
            #expect(dictionary?["expectedAddress"] as? String == "111 5th Ave, NY")
            #expect(dictionary?["formattedAddress"] as? String == "111 5th Ave, New York, NY 10003 USA")
            #expect(dictionary?["latitude"] as? Double == 40.7356)
            #expect(dictionary?["longitude"] as? Double == -73.9906)
            #expect(dictionary?["atAddress"] as? Bool == true)
            #expect(dictionary?["confidence"] as? String == "high")
            #expect(dictionary?["distance"] as? Double == 12.5)
        }

        @Test("Omits absent optional fields when encoding")
        func omitsAbsentOptionalsWhenEncoding() throws {
            let data = RadarExpectedAddress(
                expectedAddress: "111 5th Ave, NY",
                formattedAddress: nil,
                latitude: nil,
                longitude: nil,
                atAddress: nil,
                confidence: nil,
                distance: nil
            )

            let encoded = try JSONEncoder().encode(data)
            let dictionary = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]

            #expect(dictionary?.keys.sorted() == ["expectedAddress"])
        }

        @Test(
            "Rejects malformed payloads",
            arguments: [
                "{}",
                #"{"formattedAddress": "111 5th Ave"}"#,
                #"{"expectedAddress": 1}"#,
                #"{"expectedAddress": "111 5th Ave, NY", "latitude": "40.7356"}"#,
                #"{"expectedAddress": "111 5th Ave, NY", "atAddress": 1}"#,
                #"{"expectedAddress": "111 5th Ave, NY", "confidence": "nonsense"}"#,
            ])
        func rejectsMalformedBackingStruct(json: String) {
            #expect(throws: (any Error).self) {
                try JSONDecoder().decode(RadarExpectedAddress.self, from: Data(json.utf8))
            }
        }

        @Test("Exposes the backing struct on the Objective-C surface")
        func exposesBackingStruct() throws {
            let expectedAddress = try #require(RadarExpectedAddressObjc(object: fullDict()))
            let data = expectedAddress.data

            #expect(data == fullData())
            #expect(expectedAddress.expectedAddress == data.expectedAddress)
            #expect(expectedAddress.formattedAddress == data.formattedAddress)
            #expect(expectedAddress.latitude?.doubleValue == data.latitude)
            #expect(expectedAddress.longitude?.doubleValue == data.longitude)
            #expect(expectedAddress.atAddress == data.atAddress)
            #expect(expectedAddress.confidence == .high)
            #expect(expectedAddress.distance?.doubleValue == data.distance)
        }

        @Test("Reads an absent atAddress as false and an absent confidence as unknown")
        func readsAbsentOptionals() throws {
            let expectedAddress = try #require(
                RadarExpectedAddressObjc(object: ["expectedAddress": "not an address"]))

            #expect(expectedAddress.atAddress == false)
            #expect(expectedAddress.confidence == .unknown)
        }

        @Test("Parses every field from a dictionary")
        func parsesEveryField() {
            let expectedAddress = RadarExpectedAddressObjc(object: fullDict())

            #expect(expectedAddress?.expectedAddress == "111 5th Ave, NY")
            #expect(expectedAddress?.formattedAddress == "111 5th Ave, New York, NY 10003 USA")
            #expect(expectedAddress?.latitude?.doubleValue == 40.7356)
            #expect(expectedAddress?.longitude?.doubleValue == -73.9906)
            #expect(expectedAddress?.atAddress == true)
            #expect(expectedAddress?.confidence == .high)
            #expect(expectedAddress?.distance?.doubleValue == 12.5)
        }

        @Test("Round trips every field through dictionaryValue")
        func roundTripsEveryField() {
            let dictionary = RadarExpectedAddressObjc(object: fullDict())?.dictionaryValue()

            #expect(dictionary?["expectedAddress"] as? String == "111 5th Ave, NY")
            #expect(dictionary?["formattedAddress"] as? String == "111 5th Ave, New York, NY 10003 USA")
            #expect(dictionary?["latitude"] as? Double == 40.7356)
            #expect(dictionary?["longitude"] as? Double == -73.9906)
            #expect(dictionary?["atAddress"] as? Bool == true)
            #expect(dictionary?["confidence"] as? String == "high")
            #expect(dictionary?["distance"] as? Double == 12.5)
        }

        /// Objective-C can always reach the inherited `-init`, so it has to be safe rather than trap.
        @Test("Survives a bare alloc/init from Objective-C")
        func survivesBareInit() throws {
            let cls = try #require(NSClassFromString("RadarExpectedAddress") as? NSObject.Type)
            let instance = try #require(cls.init() as? RadarExpectedAddressObjc)

            #expect(instance.expectedAddress == "")
            #expect(instance.formattedAddress == nil)
            #expect(instance.latitude == nil)
            #expect(instance.longitude == nil)
            #expect(instance.atAddress == false)
            #expect(instance.confidence == .unknown)
            #expect(instance.distance == nil)
            #expect(instance.dictionaryValue()["expectedAddress"] as? String == "")
        }

        @Test("Requires an expected address")
        func requiresExpectedAddress() {
            #expect(RadarExpectedAddressObjc(object: [String: Any]()) == nil)
            #expect(RadarExpectedAddressObjc(object: ["formattedAddress": "111 5th Ave"]) == nil)
            #expect(RadarExpectedAddressObjc(object: "111 5th Ave, NY") == nil)
        }

        /// `dictionaryValue` re-encodes the stored struct, so a key the API omitted stays omitted.
        @Test("Serializes only the fields the API returned")
        func serializesOnlyReturnedFields() {
            let expectedAddress = RadarExpectedAddressObjc(object: ["expectedAddress": "not an address"])

            #expect(expectedAddress?.atAddress == false)
            #expect(expectedAddress?.confidence == .unknown)

            let dictionary = expectedAddress?.dictionaryValue()
            #expect(dictionary?["expectedAddress"] as? String == "not an address")
            #expect(dictionary?["atAddress"] == nil)
            #expect(dictionary?["formattedAddress"] == nil)
            #expect(dictionary?["latitude"] == nil)
            #expect(dictionary?["longitude"] == nil)
            #expect(dictionary?["confidence"] == nil)
            #expect(dictionary?["distance"] == nil)
        }

        @Test("Parses each confidence level")
        func parsesEachConfidence() {
            let cases: [(String, RadarExpectedAddressConfidence)] = [
                ("high", .high),
                ("medium", .medium),
                ("low", .low),
            ]

            for (confidenceString, confidence) in cases {
                let expectedAddress = RadarExpectedAddressObjc(object: [
                    "expectedAddress": "111 5th Ave, NY",
                    "confidence": confidenceString,
                ])

                #expect(expectedAddress?.confidence == confidence)
                #expect(expectedAddress?.dictionaryValue()["confidence"] as? String == confidenceString)
            }
        }

        @Test("Parses and serializes the user's expected address")
        func parsesUserExpectedAddress() {
            let user = RadarUser(
                object: [
                    "_id": "user_test",
                    "userId": "user-id",
                    "deviceId": "device-id",
                    "location": [
                        "type": "Point",
                        "coordinates": [-73.9906, 40.7356],
                    ],
                    "expectedAddress": fullDict(),
                ])

            #expect(user?.expectedAddress?.expectedAddress == "111 5th Ave, NY")
            #expect(user?.expectedAddress?.atAddress == true)
            #expect(user?.expectedAddress?.confidence == .high)

            let serialized = user?.dictionaryValue()["expectedAddress"] as? [String: Any]
            #expect(serialized?["expectedAddress"] as? String == "111 5th Ave, NY")
            #expect(serialized?["confidence"] as? String == "high")
        }

        @Test("Omits the expected address when the user has none")
        func omitsMissingUserExpectedAddress() {
            let user = RadarUser(
                object: [
                    "_id": "user_test",
                    "location": [
                        "type": "Point",
                        "coordinates": [-73.9906, 40.7356],
                    ],
                ])

            #expect(user?.expectedAddress == nil)
            #expect(user?.dictionaryValue()["expectedAddress"] == nil)
        }
    }
}
