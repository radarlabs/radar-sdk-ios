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

        private static let verifiedResponse: [AnyHashable: Any] = [
            "address": baseFields.merging(["number": "20", "street": "Jay St"]) { _, new in new },
            "result": ["verificationStatus": "verified"],
        ]

        private func validate(
            _ fields: [String: Any],
            response: [AnyHashable: Any] = verifiedResponse
        ) async throws -> (RadarStatus, [String: String]) {
            let address = try #require(RadarAddress(from: Self.baseFields.merging(fields) { _, new in new }))
            fixture.apiHelperMock.mockStatus = .success
            fixture.apiHelperMock.mockResponse = response

            let status = await awaitCompletion { resume in
                RadarAPIClient.sharedInstance().validate(address) { status, _, _, _ in
                    #expect(Thread.isMainThread)
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

        @Test("a verified response returns the address and verification status")
        func verifiedResponse_returnsSuccess() async throws {
            let address = try #require(RadarAddress(from: Self.baseFields.merging(["addressLabel": "20 Jay St"]) { _, new in new }))
            fixture.apiHelperMock.mockStatus = .success
            fixture.apiHelperMock.mockResponse = Self.verifiedResponse

            let (status, number, verificationStatus) = await awaitCompletion { resume in
                RadarAPIClient.sharedInstance().validate(address) { status, _, address, verificationStatus in
                    resume((status, address?.number, verificationStatus))
                }
            }

            #expect(status == .success)
            #expect(number == "20")
            #expect(verificationStatus == .verified)
        }

        @Test("a response without a verification status returns a server error")
        func responseWithoutVerificationStatus_returnsServerError() async throws {
            let (status, _) = try await validate(["addressLabel": "20 Jay St"], response: ["address": Self.baseFields])

            #expect(status == .errorServer)
        }

        @Test("values with &, =, and + are escaped")
        func reservedCharacters_areEscaped() async throws {
            let (_, query) = try await validate(["addressLabel": "1st & Main=A+B", "unit": "#3"])

            #expect(query["addressLabel"] == "1st & Main=A+B")
            #expect(query["unit"] == "#3")
            #expect(fixture.apiHelperMock.lastUrl?.contains("A%2BB") == true)
        }

        @Test("an empty street or number sends the label")
        func emptyStreet_sendsLabel() async throws {
            let (_, query) = try await validate(["street": "", "number": "20", "addressLabel": "20 Jay St"])

            #expect(query["addressLabel"] == "20 Jay St")
            #expect(query["street"] == nil)
            #expect(query["number"] == nil)
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

        /// Validates an address built from `fields` alone and returns the status, checking that no request was sent.
        private func validateLocallyRejected(_ fields: [String: Any]) async throws -> RadarStatus {
            let address = try #require(RadarAddress(from: fields))

            let status = await awaitCompletion { resume in
                RadarAPIClient.sharedInstance().validate(address) { status, _, _, _ in
                    #expect(Thread.isMainThread)
                    resume(status)
                }
            }

            #expect(fixture.apiHelperMock.lastUrl == nil)
            return status
        }

        @Test("an address without a postal code fails before sending a request")
        func missingPostalCode_returnsBadRequest() async throws {
            var fields = Self.baseFields
            fields["postalCode"] = nil
            fields["addressLabel"] = "20 Jay St"

            #expect(try await validateLocallyRejected(fields) == .errorBadRequest)
        }

        @Test("an address with an empty postal code fails before sending a request")
        func emptyPostalCode_returnsBadRequest() async throws {
            let fields = Self.baseFields.merging(["postalCode": "", "addressLabel": "20 Jay St"]) { _, new in new }

            #expect(try await validateLocallyRejected(fields) == .errorBadRequest)
        }

        @Test("a label that isn't valid UTF-16 fails before sending a request")
        func malformedLabel_returnsBadRequest() async throws {
            // "20 Jay St " followed by the first half of an emoji's surrogate pair.
            let label = NSString(characters: Array("20 Jay St ".utf16) + [0xD83D], length: 11)
            let fields = Self.baseFields.merging(["addressLabel": label]) { _, new in new }

            #expect(try await validateLocallyRejected(fields) == .errorBadRequest)
        }

        @Test("an empty unit isn't sent")
        func emptyUnit_isOmitted() async throws {
            let (_, query) = try await validate(["addressLabel": "20 Jay St", "unit": ""])

            #expect(query["unit"] == nil)
        }
    }
}
