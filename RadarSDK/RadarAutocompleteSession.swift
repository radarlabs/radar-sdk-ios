//
//  RadarAutocompleteSession.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

/// Called when an autocomplete selection report succeeds, fails, or times out.
///
/// Receives the request status and, where available, the enriched address.
///
/// - SeeAlso: https://radar.com/documentation/api#autocomplete
public typealias RadarAutocompleteSelectCompletionHandler = (RadarStatus, RadarAutocompleteEnrichedAddress?) -> Void

/// An autocomplete search field and the selection a user makes in it.
///
/// Create one session per address field.
///
/// - SeeAlso: https://radar.com/documentation/api#autocomplete
@objc(RadarAutocompleteSession)
@objcMembers
public final class RadarAutocompleteSession: NSObject {
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
    ///   - completionHandler: A completion handler.
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
        completionHandler: @escaping RadarGeocodeCompletionHandler
    ) {
        RadarLogger.shared.info("autocomplete()", type: .sdkCall)
        guard let bridge = RadarSwift.bridge else {
            Self.finish { completionHandler(.errorPublishableKey, nil) }
            return
        }

        bridge.autocomplete(
            query: query, near: near, layers: layers, limit: limit, country: country,
            mailable: mailable, sessionToken: sessionToken
        ) { status, addresses in
            Self.finish { completionHandler(status, addresses) }
        }
    }

    /// Reports which result the user chose, and returns it enriched where available.
    ///
    /// - Parameters:
    ///   - address: The selected result, as returned by this session's `autocomplete`. An address
    ///     from anywhere else fails with `RadarStatusErrorBadRequest` and makes no request.
    ///   - completionHandler: An optional completion handler.
    ///
    /// - SeeAlso: https://radar.com/documentation/api#autocomplete
    @objc(selectAddress:completionHandler:)
    public func select(
        address: RadarAddress, completionHandler: RadarAutocompleteSelectCompletionHandler?
    ) {
        RadarLogger.shared.info("selectAddress()", type: .sdkCall)
        guard let bridge = RadarSwift.bridge else {
            Self.finish { completionHandler?(.errorPublishableKey, nil) }
            return
        }

        bridge.selectAutocompleteAddress(address) { status, enrichedAddress in
            Self.finish { completionHandler?(status, enrichedAddress) }
        }
    }

    // Matches `[RadarUtilsDeprecated runOnMainThread:]`, which the Objective-C callers use.
    private static func finish(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }
}
