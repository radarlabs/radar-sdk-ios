//
//  RadarCompletedSpan.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

/// OTel span kind. Values are the OTLP enum values. The SDK only creates internal and client spans; the
/// others are 0 (unspecified), 2 (server, e.g. the Radar API's span for a request), 4 (producer) and 5 (consumer).
enum RadarSpanKind: Int, Sendable {
    /// Work inside the SDK, such as getting a location.
    case `internal` = 1

    /// An outgoing request to the Radar API. The server's span for that request is its child.
    case client = 3
}

/// A typed span attribute value, encoded as the matching OTLP `AnyValue` field.
enum RadarTraceAttributeValue: Sendable, Equatable {
    case string(String)
    case int(Int64)
    case double(Double)
    case bool(Bool)

    var otlpValue: [String: Any] {
        switch self {
        case .string(let value):
            return ["stringValue": value]
        case .int(let value):
            // int64 values are decimal strings in OTLP/JSON.
            return ["intValue": String(value)]
        case .double(let value):
            return ["doubleValue": value]
        case .bool(let value):
            return ["boolValue": value]
        }
    }
}

/// An ended span's data, serialized with `otlpJSON()` as an OTLP span for storage and upload. `otlpJSON()` follows
/// the OTLP/JSON encoding: hex IDs, int64 values as decimal strings, and enums as integers.
/// https://opentelemetry.io/docs/specs/otlp/#json-protobuf-encoding
struct RadarCompletedSpan: Sendable {
    let name: String
    let traceId: String
    let spanId: String
    let parentSpanId: String?
    let kind: RadarSpanKind
    let startUnixNanos: UInt64
    let endUnixNanos: UInt64
    let status: RadarStatus
    let attributes: [String: RadarTraceAttributeValue]

    func otlpJSON() -> [String: Any] {
        var attrs: [[String: Any]] = attributes.sorted { $0.key < $1.key }.map { key, value in
            ["key": key, "value": value.otlpValue]
        }
        if status != .success {
            attrs.append(["key": "error.type", "value": ["stringValue": Radar.stringForStatus(status)]])
        }
        var json: [String: Any] = [
            "name": name,
            "traceId": traceId,
            "spanId": spanId,
            "kind": kind.rawValue,
            // Bits 0-7 are the W3C trace flags; 1 = sampled.
            // https://github.com/open-telemetry/opentelemetry-proto/blob/main/opentelemetry/proto/trace/v1/trace.proto
            // https://www.w3.org/TR/trace-context-2/#trace-flags
            "flags": 1,
            "startTimeUnixNano": String(startUnixNanos),
            "endTimeUnixNano": String(endUnixNanos),
            "attributes": attrs,
        ]
        if let parentSpanId {
            json["parentSpanId"] = parentSpanId
        }
        // OTLP status code 2 is ERROR. Leave status unset (0) on success; instrumentation should not set OK (1).
        // https://opentelemetry.io/docs/specs/semconv/general/recording-errors/#recording-errors-on-spans
        if status != .success {
            json["status"] = ["code": 2]
        }
        return json
    }
}
