//
//  RadarTraceManager+Export.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

// The `/v1/traces` protocol: the OTLP request body and what each response means for the batch.
extension RadarTraceManager {

    enum UploadOutcome: Equatable {
        /// The server accepted the batch. `rejectedSpans` is set when it reported a partial success.
        case accepted(rejectedSpans: String?)
        /// Transient failure: keep the batch for the next flush.
        case retry
        /// Not retryable: drop the batch.
        case drop(statusCode: Int, body: String)
    }

    /// Maps an upload response to what to do with the batch. A 2xx with a JSON envelope is accepted, including a
    /// `partialSuccess` (rejected spans aren't retried). 429 and 5xx keep the batch for a later flush. Anything else
    /// drops it.
    static func outcome(statusCode: Int, data: Data) -> UploadOutcome {
        switch statusCode {
        case 200..<300:
            // Every /v1/traces response has a JSON envelope. Without one, acknowledgement is ambiguous, so keep the batch.
            guard let res = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return .retry
            }
            guard let partialSuccess = res["partialSuccess"] as? [String: Any] else {
                return .accepted(rejectedSpans: nil)
            }
            let rejectedSpans = partialSuccess["rejectedSpans"].map { "\($0)" } ?? "unknown"
            return .accepted(rejectedSpans: rejectedSpans)
        case 429, 500...599:
            return .retry
        default:
            return .drop(statusCode: statusCode, body: String(bytes: data.prefix(1000), encoding: .utf8) ?? "")
        }
    }

    /// The cross-platform framework calling the SDK, matching the `X-Radar-X-Platform-SDK-*` headers: `Native` with no
    /// version for apps that call the SDK directly, or a wrapper's type and version.
    struct XPlatform: Equatable, Sendable {
        let type: String
        let version: String?

        static let native = XPlatform(type: "Native", version: nil)

        static var current: XPlatform {
            guard RadarSettings.xPlatform, let type = RadarSettings.xPlatformSDKType else { return .native }
            return XPlatform(type: type, version: RadarSettings.xPlatformSDKVersion)
        }
    }

    /// The SDK that recorded a span, which `otlpPayload` puts on the batch's resource. `xPlatformType` and
    /// `xPlatformVersion` are nil for spans stored before they were recorded; the server fills them in from the upload's
    /// headers.
    struct SpanSource: Equatable {
        let sdkVersion: String
        let xPlatformType: String?
        let xPlatformVersion: String?
    }

    /// Wraps spans in an OTLP ExportTraceServiceRequest.
    ///
    /// Device attributes are read at upload time, so spans recorded before an OS update are labeled with the new
    /// `os.version`.
    static func otlpPayload(spans: [[String: Any]], source: SpanSource) -> [String: Any] {
        var attributes = [
            attribute("service.name", "radar-client"),
            attribute("os.type", "ios"),
            attribute("radar.sdk.version", source.sdkVersion),
            attribute("os.version", RadarUtils.deviceOSVersion),
            attribute("device.manufacturer", RadarUtils.deviceMake),
            attribute("device.model.identifier", RadarUtils.deviceModel),
        ]
        if let xPlatformType = source.xPlatformType {
            attributes.append(attribute("radar.sdk.xplatform.type", xPlatformType))
        }
        if let xPlatformVersion = source.xPlatformVersion {
            attributes.append(attribute("radar.sdk.xplatform.version", xPlatformVersion))
        }
        let resource: [String: Any] = ["attributes": attributes]
        let scopeSpans: [String: Any] = [
            "scope": ["name": "io.radar.sdk", "version": source.sdkVersion],
            "spans": spans,
        ]
        return ["resourceSpans": [["resource": resource, "scopeSpans": [scopeSpans]]]]
    }

    /// An OTLP string attribute.
    private static func attribute(_ key: String, _ value: String) -> [String: Any] {
        ["key": key, "value": ["stringValue": value]]
    }
}
