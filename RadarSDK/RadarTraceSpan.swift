//
//  RadarTraceSpan.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

/// A deliberately small, dependency-free span. `RadarTraceManager` owns sampling and export.
///
/// Follows the OpenTelemetry trace data model and OTLP/JSON encoding for the fields it supports (IDs, parent, kind,
/// timestamps, status, typed attributes) and propagates context as a W3C `traceparent`. It is not an implementation of
/// the OTel API, and does not support span events, links, `tracestate`, or array attributes. OTel spans and traces:
/// https://opentelemetry.io/docs/specs/otel/trace/api/#span
///
/// Safe for concurrent use, like OTel spans: attribute updates and `end(status:)` are serialized on one lock, and the
/// span records a snapshot of its attributes.
///
/// `manager` is nil only for the shared no-op span, returned when tracing hasn't started, there's no publishable key,
/// or the trace isn't sampled. That span records nothing and propagates no context.
@objc(RadarTraceSpan)
final class RadarTraceSpan: NSObject, @unchecked Sendable {
    let name: String
    let traceId: String
    let spanId: String
    let parentSpanId: String?
    let kind: RadarSpanKind

    private let manager: RadarTraceManager?
    private let project: String
    private let startUnixMillis: UInt64
    private let startMonotonicNanos: UInt64

    private let lock = NSLock()
    // Guarded by lock.
    private var attributes: [String: RadarTraceAttributeValue] = [:]
    private var ended = false

    /// Shared span returned when tracing is off. It records nothing, so one instance serves every caller.
    static let noop = RadarTraceSpan(
        name: "", traceId: "", spanId: "", parentSpanId: nil, kind: .internal, manager: nil, project: "")

    private init(
        name: String, traceId: String, spanId: String, parentSpanId: String?, kind: RadarSpanKind,
        manager: RadarTraceManager?, project: String
    ) {
        self.name = name
        self.traceId = traceId
        self.spanId = spanId
        self.parentSpanId = parentSpanId
        self.kind = kind
        self.manager = manager
        self.project = project
        self.startUnixMillis = manager?.clock.wallMillis() ?? 0
        self.startMonotonicNanos = manager?.clock.monotonicNanos() ?? 0
        super.init()
    }

    // MARK: - Starting spans

    /// Starts a new trace with this span as its root, or returns the no-op span if tracing is off.
    @objc(startWithName:)
    static func start(_ name: String) -> RadarTraceSpan {
        start(name, manager: .shared)
    }

    static func start(_ name: String, manager: RadarTraceManager) -> RadarTraceSpan {
        guard manager.started, manager.isSampled(), let project = manager.currentProjectFingerprint() else {
            return noop
        }
        return RadarTraceSpan(
            name: name, traceId: newTraceId(), spanId: newSpanId(), parentSpanId: nil, kind: .internal,
            manager: manager, project: project)
    }

    /// Starts a child span in this trace. For a request to the Radar API, use `.client` and send the child's
    /// `traceparent` with the request. Children of the no-op span are the same no-op span.
    func child(_ name: String, kind: RadarSpanKind = .internal) -> RadarTraceSpan {
        guard let manager else { return self }
        return RadarTraceSpan(
            name: name, traceId: traceId, spanId: Self.newSpanId(), parentSpanId: spanId, kind: kind,
            manager: manager, project: project)
    }

    /// Temporary Objective-C entry point for `child(_:kind:)` with `.internal`. Objective-C can't see the internal
    /// `RadarSpanKind`, so each kind gets its own method. Remove once the callers move to Swift.
    @objc(child:)
    func objcChild(_ name: String) -> RadarTraceSpan {
        child(name, kind: .internal)
    }

    /// Temporary Objective-C entry point for `child(_:kind:)` with `.client`. See `objcChild(_:)`.
    @objc(clientChild:)
    func objcClientChild(_ name: String) -> RadarTraceSpan {
        child(name, kind: .client)
    }

    // MARK: - Context

    /// The W3C `traceparent` header for requests made in this span: `version-traceId-parentId-flags`, where flags
    /// 01 means sampled. Nil for the no-op span. https://www.w3.org/TR/trace-context/#traceparent-header
    @objc var traceparent: String? {
        manager == nil ? nil : "00-\(traceId)-\(spanId)-01"
    }

    // MARK: - Attributes

    @objc(setString:forKey:)
    func setString(_ value: String, forKey key: String) {
        setAttribute(key, .string(value))
    }

    @objc(setInteger:forKey:)
    func setInteger(_ value: Int64, forKey key: String) {
        setAttribute(key, .int(value))
    }

    @objc(setDouble:forKey:)
    func setDouble(_ value: Double, forKey key: String) {
        setAttribute(key, .double(value))
    }

    @objc(setBool:forKey:)
    func setBool(_ value: Bool, forKey key: String) {
        setAttribute(key, .bool(value))
    }

    /// Ignored on the no-op span and after `end(status:)`.
    private func setAttribute(_ key: String, _ value: RadarTraceAttributeValue) {
        guard manager != nil else { return }
        lock.withLock {
            if !ended {
                attributes[key] = value
            }
        }
    }

    // MARK: - Ending

    /// Ends the span and records it. Only the first call has an effect.
    @objc(endWithStatus:)
    func end(status: RadarStatus) {
        guard let manager else { return }
        let snapshot: [String: RadarTraceAttributeValue]? = lock.withLock {
            if ended { return nil }
            ended = true
            return attributes
        }
        guard let snapshot else { return }

        // Duration comes from the monotonic clock, so a wall-clock change while the span is open doesn't skew it.
        let now = manager.clock.monotonicNanos()
        let elapsedMillis = (now > startMonotonicNanos ? now - startMonotonicNanos : 0) / 1_000_000
        let completed = RadarCompletedSpan(
            name: name,
            traceId: traceId,
            spanId: spanId,
            parentSpanId: parentSpanId,
            kind: kind,
            startUnixNanos: startUnixMillis * 1_000_000,
            endUnixNanos: (startUnixMillis + elapsedMillis) * 1_000_000,
            status: status,
            attributes: snapshot
        )
        manager.record(completed, project: project)
    }

    // MARK: - IDs

    /// A random, non-zero 8-byte span ID as 16 lowercase hex characters. All-zero IDs are invalid in W3C Trace
    /// Context. `SystemRandomNumberGenerator` is cryptographically secure on Apple platforms.
    /// https://www.w3.org/TR/trace-context/#parent-id
    private static func newSpanId() -> String {
        hex(UInt64.random(in: 1 ... .max))
    }

    /// A random, non-zero 16-byte trace ID as 32 lowercase hex characters. https://www.w3.org/TR/trace-context/#trace-id
    private static func newTraceId() -> String {
        hex(UInt64.random(in: 0 ... .max)) + hex(UInt64.random(in: 1 ... .max))
    }

    private static func hex(_ value: UInt64) -> String {
        String(format: "%016llx", value)
    }
}

/// Clocks for span timestamps. Tests inject controllable ones.
struct RadarTraceClock: Sendable {
    /// Unix time in milliseconds, for span start times.
    let wallMillis: @Sendable () -> UInt64

    /// A monotonic clock in nanoseconds, for durations. Darwin's `CLOCK_MONOTONIC` keeps counting while the device
    /// sleeps, so a span that waits through a sleep (such as a location request) isn't undercounted.
    let monotonicNanos: @Sendable () -> UInt64

    static let system = RadarTraceClock(
        wallMillis: { UInt64(Date().timeIntervalSince1970 * 1000) },
        monotonicNanos: { clock_gettime_nsec_np(CLOCK_MONOTONIC) }
    )
}
