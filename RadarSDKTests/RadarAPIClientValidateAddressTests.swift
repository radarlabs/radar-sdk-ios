//
//  RadarAPIClientValidateAddressTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

// The test target also sees the Objective-C RadarAPIClient through its bridging header.
typealias APIClient = RadarSDK.RadarAPIClient
typealias ValidateAddressRequest = RadarSDK.RadarValidateAddressRequest

/// Records the requests the mock session receives.
private final class RequestLog: @unchecked Sendable {
    var requests: [URLRequest] = []
}

extension RadarSerializedTests {
    @Suite("RadarAPIClient validateAddress", .serialized)
    @MainActor
    struct RadarAPIClientValidateAddressTests {
        private static let baseFields: [String: Any] = [
            "latitude": 40.70409,
            "longitude": -73.98669,
            "countryCode": "US",
            "stateCode": "NY",
            "city": "Brooklyn",
            "postalCode": "11201",
        ]

        private static let verifiedResponse: [String: Any] = [
            "address": baseFields.merging(["number": "20", "street": "Jay St"]) { _, new in new },
            "result": ["verificationStatus": "verified"],
        ]

        private let session = MockURLSession()
        private let requestLog = RequestLog()
        private let apiClient: APIClient

        init() {
            Radar.initialize(publishableKey: RadarSDKTestResources.publishableKey)
            apiClient = APIClient(apiHelper: RadarAPIHelper(session: session))
        }

        private func respond(_ response: [String: Any], statusCode: Int = 200) {
            let requestLog = requestLog
            session.on(
                { request in
                    requestLog.requests.append(request)
                    return true
                },
                response,
                statusCode: statusCode
            )
        }

        nonisolated private static func request(
            _ line: ValidateAddressRequest.Line,
            unit: String? = nil,
            postalCode: String = "11201"
        ) -> ValidateAddressRequest {
            ValidateAddressRequest(
                line: line,
                unit: unit,
                city: "Brooklyn",
                stateCode: "NY",
                postalCode: postalCode,
                countryCode: "US"
            )
        }

        /// Validates `request` against a verified response and returns the query the client sent.
        private func sentQuery(_ request: ValidateAddressRequest) async throws -> [String: String] {
            respond(Self.verifiedResponse)
            _ = try await apiClient.validateAddress(request)

            let url = try #require(requestLog.requests.last?.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) })
            #expect(url.path == "/v1/addresses/validate")
            return Dictionary((url.queryItems ?? []).map { ($0.name, $0.value ?? "") }) { first, _ in first }
        }

        private static func expectBadRequest(_ error: any Error, sourceLocation: SourceLocation = #_sourceLocation) {
            #expect((error as? RadarError)?.status == .errorBadRequest, sourceLocation: sourceLocation)
        }

        // MARK: - Request

        @Test("a street and number are sent without a label")
        func streetAndNumber_sendsStreetAndNumber() async throws {
            let query = try await sentQuery(Self.request(.streetAndNumber(street: "Jay St", number: "20")))

            #expect(query["street"] == "Jay St")
            #expect(query["number"] == "20")
            #expect(query["addressLabel"] == nil)
            #expect(query["city"] == "Brooklyn")
            #expect(query["stateCode"] == "NY")
            #expect(query["postalCode"] == "11201")
            #expect(query["countryCode"] == "US")
        }

        @Test("a label is sent without a street or number")
        func label_sendsLabel() async throws {
            let query = try await sentQuery(Self.request(.label("20 Jay St")))

            #expect(query["addressLabel"] == "20 Jay St")
            #expect(query["street"] == nil)
            #expect(query["number"] == nil)
        }

        @Test("values with &, =, and + are escaped")
        func reservedCharacters_areEscaped() async throws {
            let query = try await sentQuery(Self.request(.label("1st & Main=A+B"), unit: "#3"))

            #expect(query["addressLabel"] == "1st & Main=A+B")
            #expect(query["unit"] == "#3")
            let rawURL = try #require(requestLog.requests.last?.url?.absoluteString)
            #expect(rawURL.contains("addressLabel=1st%20%26%20Main%3DA%2BB"))
        }

        @Test("an empty unit isn't sent")
        func emptyUnit_isOmitted() async throws {
            let query = try await sentQuery(Self.request(.label("20 Jay St"), unit: ""))

            #expect(query["unit"] == nil)
        }

        @Test(
            "an empty required field fails before sending a request",
            arguments: [
                request(.label("20 Jay St"), postalCode: ""),
                request(.label("")),
                request(.streetAndNumber(street: "", number: "20")),
                request(.streetAndNumber(street: "Jay St", number: "")),
            ]
        )
        func emptyRequiredField_throwsBadRequest(request: ValidateAddressRequest) async {
            respond(Self.verifiedResponse)

            do {
                _ = try await apiClient.validateAddress(request)
                Issue.record("Expected validateAddress to throw")
            } catch {
                Self.expectBadRequest(error)
            }
            #expect(requestLog.requests.isEmpty)
        }

        // MARK: - Response

        @Test("a verified response returns the address and verification status")
        func verifiedResponse_returnsAddressAndStatus() async throws {
            respond(Self.verifiedResponse)

            let response = try await apiClient.validateAddress(Self.request(.label("20 Jay St")))

            #expect(response.address.number == "20")
            #expect(response.verificationStatus == .verified)
        }

        @Test("a response without a verification status fails")
        func responseWithoutVerificationStatus_throws() async {
            respond(["address": Self.baseFields])

            await #expect(throws: APIClient.APIError.self) {
                _ = try await apiClient.validateAddress(Self.request(.label("20 Jay St")))
            }
        }

        @Test("a 400 response fails with a bad request error")
        func badRequestResponse_throwsBadRequest() async {
            respond(["meta": ["code": 400]], statusCode: 400)

            do {
                _ = try await apiClient.validateAddress(Self.request(.label("20 Jay St")))
                Issue.record("Expected validateAddress to throw")
            } catch {
                Self.expectBadRequest(error)
            }
        }

        // MARK: - RadarAddress

        private static func line(for fields: [String: Any]) throws -> ValidateAddressRequest.Line {
            let address = try #require(RadarAddress(from: baseFields.merging(fields) { _, new in new }))
            return ValidateAddressRequest(address: address).line
        }

        @Test("an address with a street, number, and label uses the street and number")
        func addressWithAllThree_usesStreetAndNumber() throws {
            let line = try Self.line(for: ["street": "Jay St", "number": "20", "addressLabel": "20 Jay St"])

            guard case let .streetAndNumber(street, number) = line else {
                Issue.record("Expected a street and number, got \(line)")
                return
            }
            #expect(street == "Jay St")
            #expect(number == "20")
        }

        @Test(
            "an address without both a street and number uses the label",
            arguments: [
                ["addressLabel": "20 Jay St"],
                ["street": "Jay St", "addressLabel": "20 Jay St"],
                ["street": "", "number": "20", "addressLabel": "20 Jay St"],
            ] as [[String: String]]
        )
        func addressWithoutStreetAndNumber_usesLabel(fields: [String: String]) throws {
            let line = try Self.line(for: fields)

            guard case let .label(label) = line else {
                Issue.record("Expected a label, got \(line)")
                return
            }
            #expect(label == "20 Jay St")
        }

        // MARK: - Radar

        private func radarValidate(_ request: ValidateAddressRequest) async -> RadarStatus {
            await awaitCompletion { resume in
                Radar.validateAddress(request, apiClient: apiClient) { status, _, _ in
                    #expect(Thread.isMainThread)
                    resume(status)
                }
            }
        }

        @Test("Radar.validateAddress returns success on the main thread")
        func radarValidateAddress_success() async {
            respond(Self.verifiedResponse)

            #expect(await radarValidate(Self.request(.label("20 Jay St"))) == .success)
        }

        @Test("Radar.validateAddress returns a bad request status for an empty field")
        func radarValidateAddress_emptyField_returnsBadRequest() async {
            #expect(await radarValidate(Self.request(.label(""))) == .errorBadRequest)
        }

        @Test("Radar.validateAddress returns a server error for a 500 response")
        func radarValidateAddress_serverError() async {
            respond([:], statusCode: 500)

            #expect(await radarValidate(Self.request(.label("20 Jay St"))) == .errorServer)
        }
    }
}
