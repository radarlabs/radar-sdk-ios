//
//  RadarVerifiedAPICoordinator.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

/// Fronts `RadarAPIHelper` for requests that target the verified host.
/// Resolves the primary/secondary host via `RadarVerifiedHostSelector`,
/// transparently retries once on the secondary when the primary returns
/// a non-Radar response, and reports every outcome back to the selector
/// so the state machine can decide where the *next* request should go.
///
/// A "Radar response" is defined as: a response whose parsed body is a
/// dictionary containing a top-level `meta` key. Transport errors and
/// responses without `meta` (including Cloudflare error pages) are
/// treated as non-Radar failures and trigger failover. See
/// `RadarAPIHelper.m` for how those get surfaced as `(status, res)` —
/// transport errors come through as `(RadarStatusErrorNetwork, nil)`,
/// and unparseable / non-dict bodies come through as
/// `(RadarStatusErrorServer, nil)`.
@objc(RadarVerifiedAPICoordinator)
final class RadarVerifiedAPICoordinator: NSObject {

    @objc(sharedInstance)
    static let shared = RadarVerifiedAPICoordinator()

    private let selector: RadarVerifiedHostSelector

    /// Resolves the `RadarAPIHelper` to use for a given request. Reads from
    /// `RadarAPIClient.sharedInstance.apiHelper` by default so tests that
    /// swap in `RadarAPIHelperMock` work transparently.
    private let apiHelperProvider: () -> RadarAPIHelper

    init(
        selector: RadarVerifiedHostSelector = .shared,
        apiHelperProvider: @escaping () -> RadarAPIHelper = { RadarAPIClient.sharedInstance().apiHelper }
    ) {
        self.selector = selector
        self.apiHelperProvider = apiHelperProvider
        super.init()
    }

    @objc
    func request(
        method: String,
        path: String,
        headers: [String: String]?,
        params: [String: Any]?,
        sleep: Bool,
        logPayload: Bool,
        extendedTimeout: Bool,
        completionHandler: @escaping (RadarStatus, [AnyHashable: Any]?) -> Void
    ) {
        let (host, _) = selector.hostForNextRequest()
        perform(
            host: host,
            method: method,
            path: path,
            headers: headers,
            params: params,
            sleep: sleep,
            logPayload: logPayload,
            extendedTimeout: extendedTimeout,
            allowFailover: host == .primary,
            completionHandler: completionHandler
        )
    }

    private func perform(
        host: RadarVerifiedHost,
        method: String,
        path: String,
        headers: [String: String]?,
        params: [String: Any]?,
        sleep: Bool,
        logPayload: Bool,
        extendedTimeout: Bool,
        allowFailover: Bool,
        completionHandler: @escaping (RadarStatus, [AnyHashable: Any]?) -> Void
    ) {
        let url = Self.url(for: host, path: path)
        let helper = apiHelperProvider()

        helper.request(
            withMethod: method,
            url: url,
            headers: headers,
            params: params,
            sleep: sleep,
            logPayload: logPayload,
            extendedTimeout: extendedTimeout
        ) { [selector] status, res in
            let isRadarResponse = (res?["meta"] != nil)

            if isRadarResponse {
                selector.recordRadarResponse(on: host)
                completionHandler(status, res)
                return
            }

            selector.recordNonRadarFailure(on: host)

            if allowFailover {
                self.perform(
                    host: .secondary,
                    method: method,
                    path: path,
                    headers: headers,
                    params: params,
                    sleep: sleep,
                    logPayload: logPayload,
                    extendedTimeout: extendedTimeout,
                    allowFailover: false,
                    completionHandler: completionHandler
                )
                return
            }

            completionHandler(status, res)
        }
    }

    static func url(for host: RadarVerifiedHost, path: String) -> String {
        let base: String
        switch host {
        case .primary:
            base = RadarSettings.verifiedHost
        case .secondary:
            base = RadarSettings.DefaultVerifiedHostSecondary
        }
        let combined = "\(base)\(path)"
        return combined.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? combined
    }
}
