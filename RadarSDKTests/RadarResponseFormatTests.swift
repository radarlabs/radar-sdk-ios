//
//  RadarResponseFormatTests.swift
//  RadarSDK
//
//  Created by Alan Charles on 11/11/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

@Suite("RadarResponseFormat")
struct RadarResponseFormatTests {
    @Test
    func missingFormatUsesLegacyJWS() {
        let response: [String: Any] = [:]

        #expect(
            RadarResponseFormat(responseValue: response["format"]) == .jws
        )
    }

    @Test
    func parsesSupportedFormats() {
        let cases: [(String, RadarResponseFormat)] = [
            ("jws", .jws),
            ("jwe", .jwe),
            ("id", .id),
        ]

        for (value, expected) in cases {
            #expect(
                RadarResponseFormat(responseValue: value) == expected,
                "Failed to parse \(value)"
            )
        }
    }

    @Test
    func acceptsFoundationStrings() {
        #expect(
            RadarResponseFormat(responseValue: NSString(string: "jwe")) == .jwe
        )
    }

    @Test(arguments: [
        "",
        "unknown",
        "JWS",
        "JWE",
        "ID",
        " jwe",
        "jwe ",
    ])
    func rejectsUnsupportedStrings(value: String) {
        #expect(RadarResponseFormat(responseValue: value) == nil)
    }

    @Test
    func rejectsMalformedValues() {
        let values: [Any] = [
            NSNull(),
            true,
            0,
            NSNumber(value: 1),
            ["jwe"],
            ["format": "jwe"],
        ]

        for value in values {
            #expect(
                RadarResponseFormat(responseValue: value) == nil,
                "Accepted malformed format: \(value)"
            )
        }
    }
}

@Suite("RadarVerificationLevel")
struct RadarVerificationLevelTests {
    @Test
    func parsesSupportedLevels() {
        #expect(RadarVerificationLevel(responseValue: "ip") == .ip)
        #expect(RadarVerificationLevel(responseValue: "precise") == .precise)
        #expect(RadarVerificationLevel(responseValue: NSString(string: "ip")) == .ip)
    }

    @Test
    func missingUnknownAndMalformedValuesAreUnknown() {
        let values: [Any?] = [
            nil, "", "unknown", "IP", " precise", NSNull(), true, 0, ["ip"],
        ]

        for value in values {
            #expect(
                RadarVerificationLevel(responseValue: value) == .unknown,
                "Accepted level: \(String(describing: value))"
            )
        }
    }
}
