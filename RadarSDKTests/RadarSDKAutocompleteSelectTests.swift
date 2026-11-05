//
//  RadarSDKAutocompleteSelectTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

/// Records the requests the mock session receives.
private final class RequestLog: @unchecked Sendable {
    var requests: [URLRequest] = []
}

extension RadarSerializedTests {
    /// Covers `RadarAutocompleteSession`: the token it owns, the handle its results carry, and reporting
    /// which result the user chose.
    @Suite(.serialized)
    @MainActor
    struct RadarSDKAutocompleteSelectTests {
        private let fixture = RadarSDKTestFixture()
        private let urlSession = MockURLSession()
        private let requestLog = RequestLog()

        private static let resultId = "v1_QUJDREVGR0hJSktMTU5PUFFSU1RVVldYWVowMTIzNDU2"

        /// Mocks an autocomplete response. The API returns a selection handle on each result only when the
        /// request named a session, so a nil `resultId` here stands for a request that carried no token.
        private func mockAutocompleteResponse(resultId: String?) throws {
            var response = try RadarSDKTestResources.jsonDictionary(fromResource: "search_autocomplete")
            var addresses = try #require(response["addresses"] as? [[AnyHashable: Any]])
            addresses[0]["resultId"] = resultId
            response["addresses"] = addresses

            fixture.apiHelperMock.mockStatus = .success
            fixture.apiHelperMock.mockResponse = response
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

        /// Answers every request with `body`, recording what was sent.
        private func respond(_ body: Data, statusCode: Int) {
            let requestLog = requestLog
            urlSession.handlers.append(
                .init(
                    on: { request in
                        requestLog.requests.append(request)
                        return true
                    },
                    response: body,
                    statusCode: statusCode
                )
            )
        }

        private func respond(_ body: [String: Any], statusCode: Int = 200) throws {
            respond(try JSONSerialization.data(withJSONObject: body), statusCode: statusCode)
        }

        private func select(resultId: String) async -> (RadarStatus, RadarAutocompleteEnrichedAddress?) {
            let apiClient = APIClient(apiHelper: RadarAPIHelper(session: urlSession))
            return await awaitCompletion { resume in
                RadarAutocompleteSession.select(resultId: resultId, apiClient: apiClient) { status, address in
                    #expect(Thread.isMainThread)
                    resume((status, address))
                }
            }
        }

        private var lastSessionToken: String? {
            guard let url = fixture.apiHelperMock.lastUrl, let components = URLComponents(string: url) else {
                return nil
            }
            return components.queryItems?.first { $0.name == "sessionToken" }?.value
        }

        @Test("a session resumed from a token sends that token")
        func resumedSessionSendsGivenToken() async throws {
            try mockAutocompleteResponse(resultId: Self.resultId)
            let token = UUID().uuidString
            let session = try #require(RadarAutocompleteSession(sessionToken: token))

            _ = await autocomplete(session)

            #expect(session.sessionToken == token)
            #expect(lastSessionToken == token)
        }

        @Test("a session cannot be resumed from a non-UUID token")
        func resumedSessionRejectsNonUuidToken() {
            #expect(RadarAutocompleteSession(sessionToken: "not-a-uuid") == nil)
            #expect(RadarAutocompleteSession(sessionToken: "") == nil)
        }

        // A second address field gets a second session, so the two never share the server's selection cap
        // or its enrichment snapshot window.
        @Test("each session sends its own UUID token")
        func sessionsDoNotShareTokens() async throws {
            try mockAutocompleteResponse(resultId: Self.resultId)
            let billing = RadarAutocompleteSession()
            let shipping = RadarAutocompleteSession()

            _ = await autocomplete(billing)
            let billingToken = lastSessionToken
            _ = await autocomplete(shipping)

            #expect(UUID(uuidString: billing.sessionToken) != nil)
            #expect(billingToken == billing.sessionToken)
            #expect(lastSessionToken == shipping.sessionToken)
            #expect(lastSessionToken != billingToken)
        }

        @Test("a session's results carry a selection handle")
        func sessionResultsCarryResultId() async throws {
            try mockAutocompleteResponse(resultId: Self.resultId)

            let (status, addresses) = await autocomplete(RadarAutocompleteSession())

            #expect(status == .success)
            #expect(addresses?.first?.resultId == Self.resultId)
        }

        @Test("the autocomplete class methods send no session token")
        func classMethodSendsNoSessionToken() async throws {
            try mockAutocompleteResponse(resultId: nil)

            let (status, addresses) = await autocompleteWithoutSession()

            #expect(status == .success)
            #expect(lastSessionToken == nil)
            #expect(addresses?.isEmpty == false)
            #expect(addresses?.first?.resultId == nil)
        }

        @Test("select posts the handle, and returns no address when the project doesn't enrich")
        func selectPostsResultId() async throws {
            respond(Data(), statusCode: 204)

            let (status, selected) = await select(resultId: Self.resultId)

            #expect(status == .success)
            #expect(selected == nil)
            let request = try #require(requestLog.requests.last)
            #expect(request.httpMethod == "POST")
            #expect(request.url?.path == "/v1/search/autocomplete/select")
            let body = try JSONSerialization.jsonObject(with: try #require(request.httpBody)) as? [String: String]
            #expect(body == ["resultId": Self.resultId])
        }

        @Test("select returns the enriched address when the server sends one")
        func selectReturnsEnrichedAddress() async throws {
            try respond([
                "meta": ["code": 200],
                "address": [
                    "formattedAddress": "123 Main St, New York, NY 10001 US",
                    "locationDetails": [
                        "usage": "residential",
                        "dwelling": "apartment",
                        "grounds": ["campus"],
                        "places": [["name": "Joe's Deli", "categories": ["food-beverage", "deli"]]],
                    ],
                ],
            ])

            let (status, selected) = await select(resultId: Self.resultId)

            #expect(status == .success)
            #expect(selected?.formattedAddress == "123 Main St, New York, NY 10001 US")
            #expect(selected?.locationDetails.usage == "residential")
            #expect(selected?.locationDetails.dwelling == "apartment")
            #expect(selected?.locationDetails.grounds == ["campus"])
            #expect(selected?.locationDetails.places.count == 1)
            #expect(selected?.locationDetails.places.first?.name == "Joe's Deli")
            #expect(selected?.locationDetails.places.first?.categories == ["food-beverage", "deli"])
        }

        // The selection was recorded, so the status stays success; only the enrichment is dropped.
        // A nil argument stands for a response with no locationDetails at all.
        @Test(
            "select returns no address when the enrichment is missing a required field",
            arguments: [nil, ["dwelling": "apartment"], ["usage": "residential"]] as [[String: String]?]
        )
        func selectDropsIncompleteEnrichment(locationDetails: [String: String]?) async throws {
            var address: [String: Any] = ["formattedAddress": "123 Main St, New York, NY 10001 US"]
            address["locationDetails"] = locationDetails
            try respond(["meta": ["code": 200], "address": address])

            let (status, selected) = await select(resultId: Self.resultId)

            #expect(status == .success)
            #expect(selected == nil)
        }

        @Test("select makes no request for a result with no handle")
        func selectWithoutResultIdMakesNoRequest() async {
            let (status, selected) = await select(resultId: "")

            #expect(status == .errorBadRequest)
            #expect(selected == nil)
            #expect(requestLog.requests.isEmpty)
        }

        @Test("select surfaces a per-session cap as a status")
        func selectSurfacesRateLimit() async throws {
            try respond([:], statusCode: 429)

            let (status, selected) = await select(resultId: Self.resultId)

            #expect(status == .errorRateLimit)
            #expect(selected == nil)
        }
    }
}
