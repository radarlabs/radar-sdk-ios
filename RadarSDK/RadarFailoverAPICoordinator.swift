//
//  RadarFailoverAPICoordinator.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

/// Coordinates requests against an ordered list of hosts with transparent
/// failover. The caller supplies a `performRequest` block that actually issues
/// the HTTP request for a given URL (wrapping `RadarAPIHelper`); this
/// coordinator owns host selection, one retry on the next host when the
/// current host returns a non-Radar response, and reports every outcome back
/// to `RadarFailoverHostSelector`.
///
/// A "Radar response" is defined as: a response whose parsed body is a
/// dictionary containing a top-level `meta` key. Transport errors and
/// responses without `meta` are treated
/// as non-Radar failures and trigger failover. `RadarAPIHelper` surfaces
/// transport errors as `(RadarStatusErrorNetwork, nil)` and unparseable or
/// non-dict bodies as `(RadarStatusErrorServer, nil)`; both hit the
/// "no meta" branch here and count as non-Radar failures.
@objc(RadarFailoverAPICoordinator)
internal final class RadarFailoverAPICoordinator: NSObject {

    /// Pre-configured coordinator for verified-host requests.
    @objc(verifiedSharedInstance)
    nonisolated(unsafe) static let verifiedShared = RadarFailoverAPICoordinator(
        selector: RadarFailoverHostSelector(hostCount: 2),
        hostsProvider: { [RadarSettings.verifiedHost, RadarSettings.DefaultVerifiedHostSecondary] },
        logPrefix: "verified"
    )

    private let selector: RadarFailoverHostSelector
    private let hostsProvider: () -> [String]
    private let logPrefix: String

    init(
        selector: RadarFailoverHostSelector,
        hostsProvider: @escaping () -> [String],
        logPrefix: String = ""
    ) {
        self.selector = selector
        self.hostsProvider = hostsProvider
        self.logPrefix = logPrefix
        super.init()
    }

    /// Issue `path` against the host pool, failing over once to the next host
    /// if the first attempt was on host[0] and returned a non-Radar response.
    @objc
    func request(
        path: String,
        performRequest: @escaping (_ url: String, _ completion: @escaping (RadarStatus, [AnyHashable: Any]?) -> Void) -> Void,
        completionHandler: @escaping (RadarStatus, [AnyHashable: Any]?) -> Void
    ) {
        let (index, isProbe) = selector.indexForNextRequest()
        RadarLogger.shared.debug(
            "\(logTag): request host[\(index)] isProbe=\(isProbe) path=\(path)"
        )
        perform(
            index: index,
            path: path,
            allowFailover: index == 0,
            performRequest: performRequest,
            completionHandler: completionHandler
        )
    }

    private func perform(
        index: Int,
        path: String,
        allowFailover: Bool,
        performRequest: @escaping (String, @escaping (RadarStatus, [AnyHashable: Any]?) -> Void) -> Void,
        completionHandler: @escaping (RadarStatus, [AnyHashable: Any]?) -> Void
    ) {
        let hosts = hostsProvider()
        guard index < hosts.count else {
            RadarLogger.shared.warning("\(logTag): no host configured for index \(index); surfacing error")
            completionHandler(.errorUnknown, nil)
            return
        }
        let url = Self.url(host: hosts[index], path: path)

        performRequest(url) { [selector, logTag] status, res in
            let isRadarResponse = (res?["meta"] != nil)

            if isRadarResponse {
                selector.recordRadarResponse(onIndex: index)
                completionHandler(status, res)
                return
            }

            selector.recordNonRadarFailure(onIndex: index)

            if allowFailover {
                let retryIndex = index + 1
                if retryIndex < hosts.count {
                    RadarLogger.shared.info(
                        "\(logTag): non-Radar response on host[\(index)] (status=\(status.rawValue)), retrying on host[\(retryIndex)]"
                    )
                    self.perform(
                        index: retryIndex,
                        path: path,
                        allowFailover: false,
                        performRequest: performRequest,
                        completionHandler: completionHandler
                    )
                    return
                }
            }

            RadarLogger.shared.warning(
                "\(logTag): non-Radar response on host[\(index)] (status=\(status.rawValue)), surfacing error"
            )
            completionHandler(status, res)
        }
    }

    private var logTag: String {
        logPrefix.isEmpty ? "FailoverAPICoordinator" : "FailoverAPICoordinator[\(logPrefix)]"
    }

    private static func url(host: String, path: String) -> String {
        let combined = "\(host)\(path)"
        return combined.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? combined
    }
}
