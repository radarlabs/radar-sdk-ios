//
//  RadarHTTPTracing.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

// HTTP instrumentation: attributes of client spans, which RadarAPIHelper sets through RadarAPIRequestTrace. Uses
// OpenTelemetry semantic convention names where they exist; those are marked below. `radar.*` names have no semconv
// equivalent.
extension RadarTraceSpan {
    /// Called when the request starts on the API queue. `queueNanos` is the time since the request was enqueued,
    /// including any wait for an earlier track request and its post-request sleep.
    @objc(requestStartedWithURL:headers:queueNanos:)
    func requestStarted(url: String, headers: [AnyHashable: Any]?, queueNanos: UInt64) {
        recording { span in
            if let host = URL(string: url)?.host {
                span.setString(host, forKey: "server.address")  // OTel semconv
            }
            let networkType = headers?["X-Radar-Network-Type"] as? String
            span.setString(Self.connectionType(networkType), forKey: "network.connection.type")  // OTel semconv
            span.setInteger(Int64(queueNanos / 1_000_000), forKey: "radar.http.queue_ms")
        }
    }

    /// The number of times the request was resent, for example after a lost connection.
    @objc(setResendCount:)
    func setResendCount(_ count: Int) {
        setInteger(Int64(count), forKey: "http.request.resend_count")  // OTel semconv
    }

    /// Ends a client span whose request failed without a response.
    @objc(endWithNetworkError:)
    func end(networkError error: NSError) {
        setString(Self.networkErrorKind(error), forKey: "radar.network.error_kind")
        end(status: .errorNetwork)
    }

    /// OpenTelemetry `network.connection.type` values, from the `X-Radar-Network-Type` header the SDK already sends,
    /// so a traced request doesn't run a second reachability check. iOS can't tell "unavailable" from "unknown".
    static func connectionType(_ networkType: String?) -> String {
        guard let networkType else { return "unknown" }
        if networkType == "wifi" {
            return "wifi"
        }
        return networkType.hasPrefix("cellular") ? "cell" : "unknown"
    }

    static func networkErrorKind(_ error: NSError) -> String {
        guard error.domain == NSURLErrorDomain else { return "other" }
        switch error.code {
        case NSURLErrorCannotFindHost, NSURLErrorDNSLookupFailed:
            return "dns_failure"
        case NSURLErrorTimedOut:
            return "timeout"
        case NSURLErrorCannotConnectToHost:
            return "connect_refused"
        case NSURLErrorSecureConnectionFailed, NSURLErrorServerCertificateHasBadDate,
            NSURLErrorServerCertificateUntrusted, NSURLErrorServerCertificateHasUnknownRoot,
            NSURLErrorServerCertificateNotYetValid, NSURLErrorClientCertificateRejected,
            NSURLErrorClientCertificateRequired:
            return "ssl_failure"
        default:
            return "other"
        }
    }
}
