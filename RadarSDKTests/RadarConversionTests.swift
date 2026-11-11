//
//  RadarConversionTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import ObjectiveC
import Testing

@testable import RadarSDK

private let createdAtString = "2026-07-20T12:00:00.000Z"
private let actualCreatedAtString = "2026-07-20T12:00:01.000Z"

// The fields every conversion needs: `_id`, `type`, and `createdAt`.
private func baseConversionObject() -> [String: Any] {
    [
        "_id": "conversion-id",
        "type": "opened_app",
        "createdAt": createdAtString,
    ]
}

struct RadarConversionTests {

    private func parse(_ object: [String: Any]) throws -> RadarConversion {
        try #require(RadarConversion(object: object))
    }

    @Test("Parses every field")
    func parsesEveryField() throws {
        var object = baseConversionObject()
        object["actualCreatedAt"] = actualCreatedAtString
        object["live"] = true
        object["metadata"] = ["campaign": "spring"]

        let conversion = try parse(object)

        #expect(conversion._id == "conversion-id")
        #expect(conversion.name == "opened_app")
        #expect(conversion.createdAt == RadarUtils.isoDateFormatter.date(from: createdAtString))
        #expect(conversion.actualCreatedAt == RadarUtils.isoDateFormatter.date(from: actualCreatedAtString))
        #expect(conversion.live)
        #expect(conversion.metadata?["campaign"] as? String == "spring")
    }

    @Test("Leaves optional fields empty when only the required fields are present")
    func defaultsOptionalFields() throws {
        let conversion = try parse(baseConversionObject())

        #expect(conversion.actualCreatedAt == nil)
        #expect(!conversion.live)
        #expect(conversion.metadata == nil)
    }

    @Test("Ignores wrongly typed optional fields")
    func ignoresWronglyTypedFields() throws {
        var object = baseConversionObject()
        object["actualCreatedAt"] = 12
        object["live"] = "yes"
        object["metadata"] = ["not", "a", "dictionary"]

        let conversion = try parse(object)

        #expect(conversion.actualCreatedAt == nil)
        #expect(!conversion.live)
        #expect(conversion.metadata == nil)
    }

    @Test("Parses metadata from a JSON object string")
    func parsesMetadataString() throws {
        var object = baseConversionObject()
        object["metadata"] = #"{"revenue": 0.2}"#

        #expect(try parse(object).metadata?["revenue"] as? Double == 0.2)
    }

    @Test("Returns nil for a non-dictionary, or without _id, type, or a valid createdAt")
    func rejectsMissingRequiredFields() {
        #expect(RadarConversion(object: "conversion") == nil)
        #expect(RadarConversion(object: nil) == nil)

        for key in ["_id", "type", "createdAt"] {
            var object = baseConversionObject()
            object[key] = nil
            #expect(RadarConversion(object: object) == nil, "missing \(key)")
        }

        var badCreatedAt = baseConversionObject()
        badCreatedAt["createdAt"] = "yesterday"
        #expect(RadarConversion(object: badCreatedAt) == nil)

        var numericType = baseConversionObject()
        numericType["type"] = 3
        #expect(RadarConversion(object: numericType) == nil)
    }

    @Test("Serializes the keys hybrid SDKs read, plus name")
    func serializes() throws {
        var object = baseConversionObject()
        object["actualCreatedAt"] = actualCreatedAtString
        object["live"] = true
        object["metadata"] = ["campaign": "spring"]

        let dict = try parse(object).dictionaryValue()

        #expect(dict["_id"] as? String == "conversion-id")
        #expect(dict["type"] as? String == "custom")
        #expect(dict["name"] as? String == "opened_app")
        #expect(dict["live"] as? Bool == true)
        #expect((dict["metadata"] as? [AnyHashable: Any])?["campaign"] as? String == "spring")
        #expect(dict["createdAt"] as? String == "2026-07-20T12:00:00.000+0000")
        #expect(dict["actualCreatedAt"] as? String == "2026-07-20T12:00:01.000+0000")
        for key in ["location", "confidence", "replayed"] {
            #expect(dict[key] == nil, "\(key) should be omitted")
        }
    }

    @Test("Omits metadata and actualCreatedAt when absent")
    func serializationOmitsMissingFields() throws {
        let dict = try parse(baseConversionObject()).dictionaryValue()

        #expect(dict["metadata"] == nil)
        #expect(dict["actualCreatedAt"] == nil)
    }

    @Test("Parses the documented sample response, which has no actualCreatedAt")
    func parsesDocumentedSampleResponse() throws {
        let conversion = try parse([
            "_id": "56db1f4613012711002229f6",
            "createdAt": "2016-06-10T13:44:10.535Z",
            "live": true,
            "type": "conversion",
            "confidence": 3,
            "user": ["_id": "56db1f4613012711002229f4", "userId": "user123"],
        ])

        #expect(conversion.name == "conversion")
        #expect(conversion.actualCreatedAt == nil)
        #expect(conversion.live)
    }

    @Test("Keeps the Objective-C runtime name and selectors")
    func objectiveCSurface() {
        #expect(NSStringFromClass(RadarConversion.self) == "RadarConversion")
        let cls: AnyClass = RadarConversion.self
        for selector in ["_id", "name", "createdAt", "actualCreatedAt", "live", "metadata", "dictionaryValue", "initWithObject:"] {
            #expect(class_getInstanceMethod(cls, NSSelectorFromString(selector)) != nil, "missing -\(selector)")
        }
    }
}
