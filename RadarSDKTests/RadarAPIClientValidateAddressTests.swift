//
//  RadarAPIClientValidateAddressTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

extension RadarSerializedTests {
    @Suite("RadarAPIClient validateAddress", .serialized)
    @MainActor
    struct RadarAPIClientValidateAddressTests {
        private let fixture = RadarSDKTestFixture()

        private static let baseFields: [String: Any] = [
            "latitude": 40.70409,
            "longitude": -73.98669,
            "countryCode": "US",
            "stateCode": "NY",
            "city": "Brooklyn",
            "postalCode": "11201",
        ]

        private func validate(_ fields: [String: Any]) async throws -> (RadarStatus, [String: String]) {
            let address = try #require(RadarAddress(from: Self.baseFields.merging(fields) { _, new in new }))
            fixture.apiHelperMock.mockStatus = .success
            fixture.apiHelperMock.mockResponse = [:]

            let status = await awaitCompletion { resume in
                RadarAPIClient.sharedInstance().validate(address) { status, _, _, _ in
                    resume(status)
                }
            }

            let url = try #require(fixture.apiHelperMock.lastUrl.flatMap(URLComponents.init(string:)))
            #expect(url.path == "/v1/addresses/validate")
            let query = Dictionary((url.queryItems ?? []).map { ($0.name, $0.value ?? "") }) { first, _ in first }
            return (status, query)
        }

        @Test("an address with a street, number, and label sends only the street and number")
        func streetNumberAndLabel_sendsStreetAndNumber() async throws {
            let (_, query) = try await validate([
                "street": "Jay St", "number": "20", "addressLabel": "20 Jay St",
            ])

            #expect(query["street"] == "Jay St")
            #expect(query["number"] == "20")
            #expect(query["addressLabel"] == nil)
            #expect(query["postalCode"] == "11201")
        }

        @Test("an address with only a label sends the label")
        func labelOnly_sendsLabel() async throws {
            let (_, query) = try await validate(["addressLabel": "20 Jay St"])

            #expect(query["addressLabel"] == "20 Jay St")
            #expect(query["street"] == nil)
            #expect(query["number"] == nil)
        }

        @Test("an address with a street but no number sends the label")
        func streetWithoutNumber_sendsLabel() async throws {
            let (_, query) = try await validate(["street": "Jay St", "addressLabel": "20 Jay St"])

            #expect(query["addressLabel"] == "20 Jay St")
            #expect(query["street"] == nil)
        }

        @Test("an address without a postal code fails before sending a request")
        func missingPostalCode_returnsBadRequest() async throws {
            var fields = Self.baseFields
            fields["postalCode"] = nil
            fields["addressLabel"] = "20 Jay St"
            let address = try #require(RadarAddress(from: fields))

            let status = await awaitCompletion { resume in
                RadarAPIClient.sharedInstance().validate(address) { status, _, _, _ in
                    resume(status)
                }
            }

            #expect(status == .errorBadRequest)
            #expect(fixture.apiHelperMock.lastUrl == nil)
        }
    }
}
