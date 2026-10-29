//
//  RadarSDKAutocompleteSelectTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

extension RadarSerializedTests {
    /// Covers the opaque result handle on autocomplete results and reporting which one the user chose.
    @Suite(.serialized)
    @MainActor
    struct RadarSDKAutocompleteSelectTests {
        private let fixture = RadarSDKTestFixture()

        private static let resultId = "v1_QUJDREVGR0hJSktMTU5PUFFSU1RVVldYWVowMTIzNDU2"
        private static let sessionToken = "11111111-2222-3333-4444-555555555555"

        /// Mocks an autocomplete response. The API returns a selection handle on each result only when the
        /// request named a session, so a nil `resultId` here stands for a request that carried no token.
        private func mockAutocompleteResponse(resultId: String?) {
            var address: [AnyHashable: Any] = [
                "latitude": 40.7039,
                "longitude": -73.9867,
                "formattedAddress": "Brooklyn Roasting Company, Brooklyn, New York, NY 11201 USA",
                "countryCode": "US",
                "confidence": "exact",
            ]
            address["resultId"] = resultId

            fixture.apiHelperMock.mockStatus = .success
            fixture.apiHelperMock.mockResponse = ["meta": ["code": 200], "addresses": [address]]
        }

        /// The `autocomplete` variant that names a session, the only one whose results are selectable.
        private func autocomplete(sessionToken: String?) async -> (RadarStatus, [RadarAddress]?) {
            await awaitCompletion { resume in
                Radar.autocomplete(
                    query: "brooklyn roasting", near: nil, layers: nil, limit: 10, country: nil,
                    mailable: false, sessionToken: sessionToken
                ) { status, addresses in
                    resume((status, addresses))
                }
            }
        }

        /// An `autocomplete` variant that predates sessions and takes no token.
        private func autocompleteWithoutSession() async -> (RadarStatus, [RadarAddress]?) {
            await awaitCompletion { resume in
                Radar.autocomplete(query: "brooklyn roasting", near: nil, limit: 10) { status, addresses in
                    resume((status, addresses))
                }
            }
        }

        private func select(_ address: RadarAddress) async -> (RadarStatus, RadarAddress?) {
            await awaitCompletion { resume in
                Radar.selectAutocompleteAddress(address: address) { status, selected in
                    resume((status, selected))
                }
            }
        }

        private var lastSessionToken: String? {
            guard let url = fixture.apiHelperMock.lastUrl, let components = URLComponents(string: url) else {
                return nil
            }
            return components.queryItems?.first { $0.name == "sessionToken" }?.value
        }

        /// Clears the captured request so a later assertion can tell that no new request was made.
        private func forgetLastRequest() {
            fixture.apiHelperMock.lastMethod = nil
            fixture.apiHelperMock.lastUrl = nil
            fixture.apiHelperMock.lastParams = nil
        }

        @Test("autocomplete sends the session token it was given")
        func autocompleteSendsGivenSessionToken() async {
            mockAutocompleteResponse(resultId: Self.resultId)

            _ = await autocomplete(sessionToken: Self.sessionToken)

            #expect(lastSessionToken == Self.sessionToken)
        }

        @Test("autocomplete parses the opaque selection handle off each result")
        func autocompleteParsesResultId() async {
            mockAutocompleteResponse(resultId: Self.resultId)

            let (status, addresses) = await autocomplete(sessionToken: Self.sessionToken)

            #expect(status == .success)
            #expect(addresses?.first?.resultId == Self.resultId)
        }

        @Test("autocomplete sends no session token when none is given")
        func autocompleteSendsNoSessionTokenByDefault() async {
            mockAutocompleteResponse(resultId: nil)

            _ = await autocompleteWithoutSession()
            #expect(lastSessionToken == nil)

            _ = await autocomplete(sessionToken: nil)
            #expect(lastSessionToken == nil)
        }

        @Test("autocomplete without a session token returns results with no handle")
        func autocompleteWithoutSessionTokenReturnsNoResultId() async {
            mockAutocompleteResponse(resultId: nil)

            let (status, addresses) = await autocompleteWithoutSession()

            #expect(status == .success)
            #expect(addresses?.isEmpty == false)
            #expect(addresses?.first?.resultId == nil)
        }

        @Test("autocomplete rejects a non-UUID session token without a request")
        func autocompleteRejectsNonUuidSessionToken() async {
            mockAutocompleteResponse(resultId: Self.resultId)
            forgetLastRequest()

            let (status, addresses) = await autocomplete(sessionToken: "not-a-uuid")

            #expect(status == .errorBadRequest)
            #expect(addresses == nil)
            #expect(fixture.apiHelperMock.lastUrl == nil)
        }

        @Test("selectAutocompleteAddress posts the handle and nothing else")
        func selectAutocompleteAddressPostsResultId() async throws {
            mockAutocompleteResponse(resultId: Self.resultId)
            let address = try #require(await autocomplete(sessionToken: Self.sessionToken).1?.first)

            // The server records the selection and answers 204 with no body.
            fixture.apiHelperMock.mockResponse = [:]
            let (status, selected) = await select(address)

            #expect(status == .success)
            #expect(selected == nil)
            #expect(fixture.apiHelperMock.lastMethod == "POST")
            #expect(fixture.apiHelperMock.lastUrl?.hasSuffix("/v1/search/autocomplete/select") == true)
            #expect(fixture.apiHelperMock.lastParams as? [String: String] == ["resultId": Self.resultId])
        }

        @Test("selectAutocompleteAddress returns the enriched address when the server sends one")
        func selectAutocompleteAddressReturnsEnrichedAddress() async throws {
            mockAutocompleteResponse(resultId: Self.resultId)
            let address = try #require(await autocomplete(sessionToken: Self.sessionToken).1?.first)

            fixture.apiHelperMock.mockResponse = [
                "meta": ["code": 200],
                "address": [
                    "latitude": 40.7039, "longitude": -73.9867,
                    "formattedAddress": "25 Jay St, Brooklyn, NY 11201 USA",
                ],
            ]
            let (status, selected) = await select(address)

            #expect(status == .success)
            #expect(selected?.formattedAddress == "25 Jay St, Brooklyn, NY 11201 USA")
        }

        @Test("selectAutocompleteAddress makes no request for a result from a session-less request")
        func selectAutocompleteAddressWithoutResultIdMakesNoRequest() async throws {
            mockAutocompleteResponse(resultId: nil)
            let address = try #require(await autocompleteWithoutSession().1?.first)
            #expect(address.resultId == nil)

            forgetLastRequest()
            let (status, selected) = await select(address)

            #expect(status == .errorBadRequest)
            #expect(selected == nil)
            #expect(fixture.apiHelperMock.lastMethod == nil)
            #expect(fixture.apiHelperMock.lastUrl == nil)
        }

        @Test("selectAutocompleteAddress surfaces a per-session cap as a status")
        func selectAutocompleteAddressSurfacesRateLimit() async throws {
            mockAutocompleteResponse(resultId: Self.resultId)
            let address = try #require(await autocomplete(sessionToken: Self.sessionToken).1?.first)

            fixture.apiHelperMock.mockStatus = .errorRateLimit
            let (status, selected) = await select(address)

            #expect(status == .errorRateLimit)
            #expect(selected == nil)
        }
    }
}
