//
//  RadarAutocompleteSession.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

/// An autocomplete search field and the selection a user makes in it.
///
/// Create one session per address field.
///
/// - SeeAlso: https://radar.com/documentation/api#autocomplete
@objc(RadarAutocompleteSession)
@objcMembers
public final class RadarAutocompleteSession: NSObject, Sendable {
    /// The token this session sends.
    public let sessionToken: String

    public override init() {
        sessionToken = UUID().uuidString
        super.init()
    }

    /// Resumes a session from a token minted elsewhere.
    ///
    /// Intended for wrapper SDKs that cannot hold a session instance; prefer `init()`.
    ///
    /// - Parameter sessionToken: A UUID. Returns nil for anything else, which the API would reject.
    @objc(initWithSessionToken:)
    public init?(sessionToken: String) {
        guard UUID(uuidString: sessionToken) != nil else {
            RadarLogger.shared.error("Autocomplete sessionToken must be a UUID", type: .sdkError)
            return nil
        }

        self.sessionToken = sessionToken
        super.init()
    }

    /// Autocompletes partial addresses and place names within this session, sorted by relevance.
    ///
    /// - Parameters:
    ///   - query: The partial address or place name to autocomplete.
    ///   - near: A location for the search.
    ///   - layers: Optional layer filters.
    ///   - limit: The max number of addresses to return. A number between 1 and 100.
    ///   - country: An optional country filter. A string, the unique 2-letter country code.
    ///   - mailable: Whether to only include mailable addresses.
    ///   - completionHandler: A completion handler, called on the main thread.
    ///
    /// - SeeAlso: https://radar.com/documentation/api#autocomplete
    @objc(autocompleteQuery:near:layers:limit:country:mailable:completionHandler:)
    // swiftlint:disable:next function_parameter_count
    public func autocomplete(
        query: String,
        near: CLLocation?,
        layers: [String]?,
        limit: Int32,
        country: String?,
        mailable: Bool,
        completionHandler: @escaping @Sendable (RadarStatus, [RadarAddress]?) -> Void
    ) {
        RadarLogger.shared.info("autocomplete()", type: .sdkCall)
        Task { @MainActor in
            guard let bridge = RadarSwift.bridge else {
                completionHandler(.errorPublishableKey, nil)
                return
            }

            bridge.autocomplete(
                query: query, near: near, layers: layers, limit: limit, country: country,
                mailable: mailable, sessionToken: sessionToken, completionHandler: completionHandler
            )
        }
    }

    /// Reports which result the user chose. Selections are how autocomplete quality is
    /// measured and improved.
    ///
    /// Returns the enriched address where available.
    ///
    /// - Parameters:
    ///   - address: The selected result, as returned by this session's `autocomplete`. An address
    ///     from anywhere else fails with `RadarStatusErrorBadRequest` and makes no request.
    ///   - completionHandler: An optional completion handler, called on the main thread.
    ///
    /// - SeeAlso: https://radar.com/documentation/api#autocomplete
    @objc(selectAddress:completionHandler:)
    public func select(
        address: RadarAddress,
        completionHandler: (@Sendable (RadarStatus, RadarAutocompleteEnrichedAddress?) -> Void)?
    ) {
        RadarLogger.shared.info("selectAddress()", type: .sdkCall)
        Self.select(resultId: address.resultId ?? "", completionHandler: completionHandler)
    }

    static func select(
        resultId: String,
        apiClient: RadarAPIClient = .shared,
        completionHandler: (@Sendable (RadarStatus, RadarAutocompleteEnrichedAddress?) -> Void)?
    ) {
        Task { @MainActor in
            do {
                let address = try await apiClient.selectAutocompleteResult(resultId)
                completionHandler?(.success, address)
            } catch let error as RadarError {
                RadarLogger.shared.error("selectAddress() failed: \(error.message ?? Radar.stringForStatus(error.status))")
                completionHandler?(error.status, nil)
            } catch is URLError {
                completionHandler?(.errorNetwork, nil)
            } catch {
                RadarLogger.shared.error("selectAddress() failed: \(error)")
                completionHandler?(.errorServer, nil)
            }
        }
    }
}
