//
//  RadarVerifiedAPICoordinator.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

/// Coordinates verified-host requests with failover. The caller supplies a
/// `performRequest` block that actually issues the HTTP request for a given
/// URL (wrapping `RadarAPIHelper`); this coordinator owns host selection,
/// transparent retry on the secondary when the primary returns a non-Radar
/// response, and reports every outcome back to `RadarVerifiedHostSelector`.
///
/// A "Radar response" is defined as: a response whose parsed body is a
/// dictionary containing a top-level `meta` key. Transport errors and
/// responses without `meta` (including Cloudflare error pages) are treated
/// as non-Radar failures and trigger failover. `RadarAPIHelper` surfaces
/// transport errors as `(RadarStatusErrorNetwork, nil)` and unparseable or
/// non-dict bodies as `(RadarStatusErrorServer, nil)`; both hit the
/// "no meta" branch here and count as non-Radar failures.
@objc(RadarVerifiedAPICoordinator)
internal final class RadarVerifiedAPICoordinator: NSObject {

    @objc(sharedInstance)
    nonisolated(unsafe) static let shared = RadarVerifiedAPICoordinator()

    private let selector: RadarVerifiedHostSelector

    init(selector: RadarVerifiedHostSelector = .shared) {
        self.selector = selector
        super.init()
    }

    /// Issue `path` against the verified host, failing over to the secondary
    /// once if the primary returns a non-Radar response.
    ///
    /// - Parameter path: request path + query string, e.g. `"/v1/track"` or
    ///   `"/v1/config?installId=..."`. The coordinator prepends the current
    ///   host and percent-encodes the result.
    /// - Parameter performRequest: block that performs an HTTP request against
    ///   the given fully-formed URL and invokes `completion` with the result.
    /// - Parameter completionHandler: receives the final (status, body) pair.
    @objc
    func request(
        path: String,
        performRequest: @escaping (_ url: String, _ completion: @escaping (RadarStatus, [AnyHashable: Any]?) -> Void) -> Void,
        completionHandler: @escaping (RadarStatus, [AnyHashable: Any]?) -> Void
    ) {
        let (host, _) = selector.hostForNextRequest()
        perform(
            host: host,
            path: path,
            allowFailover: host == .primary,
            performRequest: performRequest,
            completionHandler: completionHandler
        )
    }

    private func perform(
        host: RadarVerifiedHost,
        path: String,
        allowFailover: Bool,
        performRequest: @escaping (String, @escaping (RadarStatus, [AnyHashable: Any]?) -> Void) -> Void,
        completionHandler: @escaping (RadarStatus, [AnyHashable: Any]?) -> Void
    ) {
        let url = Self.url(for: host, path: path)

        performRequest(url) { [selector] status, res in
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
                    path: path,
                    allowFailover: false,
                    performRequest: performRequest,
                    completionHandler: completionHandler
                )
                return
            }

            completionHandler(status, res)
        }
    }

    private static func url(for host: RadarVerifiedHost, path: String) -> String {
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
