//
//  RadarDebugNetworking.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#if DEBUG
import Foundation

/// URLSession delegate used **only in debug builds** to accept self-signed / otherwise
/// untrusted TLS certificates, letting the SDK talk to a backend hosted on your LAN over
/// HTTPS without a CA-signed certificate.
///
/// The entire type is wrapped in `#if DEBUG`, so it is compiled out of release builds and
/// can never weaken TLS validation in production. It is only attached to the SDK's URL
/// sessions in debug builds (see `RadarAPIHelper`).
@objc(RadarInsecureTrustDelegate)
public final class RadarInsecureTrustDelegate: NSObject, URLSessionDelegate {
    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
            let serverTrust = challenge.protectionSpace.serverTrust
        else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        completionHandler(.useCredential, URLCredential(trust: serverTrust))
    }
}
#endif
