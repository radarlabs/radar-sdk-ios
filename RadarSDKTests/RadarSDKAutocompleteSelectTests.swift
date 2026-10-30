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
    /// Covers `RadarAutocompleteSession`: the token it owns, the handle its results carry, and reporting
    /// which result the user chose.
    @Suite(.serialized)
    @MainActor
    struct RadarSDKAutocompleteSelectTests {
        private let fixture = RadarSDKTestFixture()

        private static let resultId = "v1_QUJDREVGR0hJSktMTU5PUFFSU1RVVldYWVowMTIzNDU2"

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

        private func autocomplete(_ session: RadarAutocompleteSession) async -> (RadarStatus, [RadarAddress]?) {
            await awaitCompletion { resume in
                session.autocomplete(
                    query: "brooklyn roasting", near: nil, layers: nil, limit: 10, country: nil, mailable: false
                ) { status, addresses in
                    resume((status, addresses))
                }
            }
        }

        /// An `autocomplete` class method, which predates sessions and names none.
        private func autocompleteWithoutSession() async -> (RadarStatus, [RadarAddress]?) {
            await awaitCompletion { resume in
                Radar.autocomplete(query: "brooklyn roasting", near: nil, limit: 10) { status, addresses in
                    resume((status, addresses))
                }
            }
        }

        private func select(_ session: RadarAutocompleteSession, _ address: RadarAddress) async -> (RadarStatus, RadarAutocompleteEnrichedAddress?) {
            await awaitCompletion { resume in
                session.select(address: address) { status, selected in
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

        @Test("each session mints its own token")
        func eachSessionMintsItsOwnToken() {
            let first = RadarAutocompleteSession()
            let second = RadarAutocompleteSession()

            #expect(UUID(uuidString: first.sessionToken) != nil)
            #expect(first.sessionToken != second.sessionToken)
        }

        @Test("a session sends its own token on every call")
        func sessionSendsItsOwnTokenOnEveryCall() async {
            mockAutocompleteResponse(resultId: Self.resultId)
            let session = RadarAutocompleteSession()

            _ = await autocomplete(session)
            #expect(lastSessionToken == session.sessionToken)

            _ = await autocomplete(session)
            #expect(lastSessionToken == session.sessionToken)
        }

        // A second address field gets a second session, so the two never share the server's selection cap
        // or its enrichment snapshot window.
        @Test("one session's requests never carry another's token")
        func sessionsDoNotShareTokens() async {
            mockAutocompleteResponse(resultId: Self.resultId)
            let billing = RadarAutocompleteSession()
            let shipping = RadarAutocompleteSession()

            _ = await autocomplete(billing)
            let billingToken = lastSessionToken
            _ = await autocomplete(shipping)

            #expect(billingToken == billing.sessionToken)
            #expect(lastSessionToken == shipping.sessionToken)
            #expect(lastSessionToken != billingToken)
        }

        @Test("a session's results carry a selection handle")
        func sessionResultsCarryResultId() async {
            mockAutocompleteResponse(resultId: Self.resultId)

            let (status, addresses) = await autocomplete(RadarAutocompleteSession())

            #expect(status == .success)
            #expect(addresses?.first?.resultId == Self.resultId)
        }

        @Test("the autocomplete class methods send no session token")
        func classMethodSendsNoSessionToken() async {
            mockAutocompleteResponse(resultId: nil)

            let (status, addresses) = await autocompleteWithoutSession()

            #expect(status == .success)
            #expect(lastSessionToken == nil)
            #expect(addresses?.isEmpty == false)
            #expect(addresses?.first?.resultId == nil)
        }

        @Test("select posts the handle and nothing else")
        func selectPostsResultId() async throws {
            mockAutocompleteResponse(resultId: Self.resultId)
            let session = RadarAutocompleteSession()
            let address = try #require(await autocomplete(session).1?.first)

            // A project that does not enrich answers 204 with no body.
            fixture.apiHelperMock.mockResponse = [:]
            let (status, selected) = await select(session, address)

            #expect(status == .success)
            #expect(selected == nil)
            #expect(fixture.apiHelperMock.lastMethod == "POST")
            #expect(fixture.apiHelperMock.lastUrl?.hasSuffix("/v1/search/autocomplete/select") == true)
            #expect(fixture.apiHelperMock.lastParams as? [String: String] == ["resultId": Self.resultId])
        }

        @Test("select returns the enriched address when the server sends one")
        func selectReturnsEnrichedAddress() async throws {
            mockAutocompleteResponse(resultId: Self.resultId)
            let session = RadarAutocompleteSession()
            let address = try #require(await autocomplete(session).1?.first)

            fixture.apiHelperMock.mockResponse = [
                "meta": ["code": 200],
                "address": [
                    "formattedAddress": "123 Main St, New York, NY 10001 US",
                    "locationDetails": [
                        "usage": "residential",
                        "dwelling": "single_family",
                        "grounds": ["driveway", "lawn"],
                        "places": [["name": "Joe's Deli", "categories": ["food-beverage", "restaurant"]]],
                    ],
                ],
            ]
            let (status, selected) = await select(session, address)

            #expect(status == .success)
            #expect(selected?.formattedAddress == "123 Main St, New York, NY 10001 US")
            #expect(selected?.locationDetails.usage == "residential")
            #expect(selected?.locationDetails.dwelling == "single_family")
            #expect(selected?.locationDetails.grounds == ["driveway", "lawn"])
            #expect(selected?.locationDetails.places.count == 1)
            #expect(selected?.locationDetails.places.first?.name == "Joe's Deli")
            #expect(selected?.locationDetails.places.first?.categories == ["food-beverage", "restaurant"])
        }

        // The shape a project with nothing to report gets back, captured against staging.
        @Test("select returns the enriched address when enrichment knows nothing")
        func selectReturnsEnrichedAddressWithDefaults() async throws {
            mockAutocompleteResponse(resultId: Self.resultId)
            let session = RadarAutocompleteSession()
            let address = try #require(await autocomplete(session).1?.first)

            fixture.apiHelperMock.mockResponse = [
                "meta": ["code": 200],
                "address": [
                    "formattedAddress": "123 Main St, New York, NY 10001 US",
                    "locationDetails": [
                        "usage": "unknown", "dwelling": "unknown", "grounds": [], "places": [],
                    ],
                ],
            ]
            let (status, selected) = await select(session, address)

            #expect(status == .success)
            #expect(selected?.formattedAddress == "123 Main St, New York, NY 10001 US")
            #expect(selected?.locationDetails.usage == "unknown")
            #expect(selected?.locationDetails.dwelling == "unknown")
            #expect(selected?.locationDetails.grounds.isEmpty == true)
            #expect(selected?.locationDetails.places.isEmpty == true)
        }

        @Test("select makes no request for a result with no handle")
        func selectWithoutResultIdMakesNoRequest() async throws {
            mockAutocompleteResponse(resultId: nil)
            let address = try #require(await autocompleteWithoutSession().1?.first)
            #expect(address.resultId == nil)

            forgetLastRequest()
            let (status, selected) = await select(RadarAutocompleteSession(), address)

            #expect(status == .errorBadRequest)
            #expect(selected == nil)
            #expect(fixture.apiHelperMock.lastMethod == nil)
            #expect(fixture.apiHelperMock.lastUrl == nil)
        }

        @Test("select surfaces a per-session cap as a status")
        func selectSurfacesRateLimit() async throws {
            mockAutocompleteResponse(resultId: Self.resultId)
            let session = RadarAutocompleteSession()
            let address = try #require(await autocomplete(session).1?.first)

            fixture.apiHelperMock.mockStatus = .errorRateLimit
            let (status, selected) = await select(session, address)

            #expect(status == .errorRateLimit)
            #expect(selected == nil)
        }
    }
}
