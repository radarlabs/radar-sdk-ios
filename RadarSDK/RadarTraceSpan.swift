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
/// or the session isn't sampled. That span records nothing and propagates no context.
///
/// A span started before the server has decided whether its session is sampled still records, so its trace can be
/// uploaded if the decision is yes. A trace's `sessionId` is the session it started in, and its child spans inherit it.
///
/// Instrumentation lives in one `Radar<Subsystem>Tracing.swift` file per attribute namespace, for example
/// `radar.location.*` in RadarLocationTracing.swift. Each file holds its attribute setters and completion handler
/// wrappers as `@objc` extensions, declared for Objective-C in RadarTraceSpan+Internal.h. A wrapper ends its span with
/// the result's status before calling the handler, so every path that calls back ends the span. Attribute names and
/// values match the Android SDK where both platforms record the same thing, so one query works on both.
///
/// Never record precise coordinates, identifiers (install, device, user, session, transaction), strings the app passes
/// in, tokens, or fraud check results.
@objc(RadarTraceSpan)
final class RadarTraceSpan: NSObject, @unchecked Sendable {
    let name: String
    let traceId: String
    let spanId: String
    let parentSpanId: String?
    let kind: RadarSpanKind

    private let manager: RadarTraceManager?
    private let project: String
    private let sessionId: String
    private let startUnixMillis: UInt64
    private let startMonotonicNanos: UInt64

    private let lock = NSLock()
    // Guarded by lock. ended is set after the record is queued or the span is discarded.
    private var attributes: [String: RadarTraceAttributeValue] = [:]
    private var ended = false
    private var endCallbacks: [() -> Void] = []

    /// Shared span returned when tracing is off. It records nothing, so one instance serves every caller.
    static let noop = RadarTraceSpan(
        name: "", traceId: "", spanId: "", parentSpanId: nil, kind: .internal, manager: nil, project: "", sessionId: "")

    private init(
        name: String, traceId: String, spanId: String, parentSpanId: String?, kind: RadarSpanKind,
        manager: RadarTraceManager?, project: String, sessionId: String
    ) {
        self.name = name
        self.traceId = traceId
        self.spanId = spanId
        self.parentSpanId = parentSpanId
        self.kind = kind
        self.manager = manager
        self.project = project
        self.sessionId = sessionId
        self.startUnixMillis = manager?.clock.wallMillis() ?? 0
        self.startMonotonicNanos = manager?.clock.monotonicNanos() ?? 0
        super.init()
    }

    // MARK: - Starting spans

    /// The manager `start(_:)` records into. Tests point it at an isolated manager.
    nonisolated(unsafe) static var defaultManager: RadarTraceManager = .shared

    /// Starts a new trace with this span as its root, or returns the no-op span if tracing is off.
    @objc(startWithName:)
    static func start(_ name: String) -> RadarTraceSpan {
        start(name, manager: defaultManager)
    }

    static func start(_ name: String, manager: RadarTraceManager) -> RadarTraceSpan {
        let sessionId = manager.currentSessionId()
        guard manager.started, manager.samplingState(sessionId: sessionId) != .notSampled,
            let project = manager.currentProjectFingerprint()
        else {
            return noop
        }
        return RadarTraceSpan(
            name: name, traceId: newTraceId(), spanId: newSpanId(), parentSpanId: nil, kind: .internal,
            manager: manager, project: project, sessionId: sessionId)
    }

    /// Starts a child span in this trace. For a request to the Radar API, use `.client` and send the child's
    /// `traceparent` with the request. Children of the no-op span are the same no-op span.
    func child(_ name: String, kind: RadarSpanKind = .internal) -> RadarTraceSpan {
        guard let manager else { return self }
        return RadarTraceSpan(
            name: name, traceId: traceId, spanId: Self.newSpanId(), parentSpanId: spanId, kind: kind,
            manager: manager, project: project, sessionId: sessionId)
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
    /// 01 means sampled. Nil unless the session is sampled: there's no header while the decision is pending, and never
    /// the not-sampled flag. https://www.w3.org/TR/trace-context/#traceparent-header
    @objc var traceparent: String? {
        guard manager?.samplingState(sessionId: sessionId) == .sampled else { return nil }
        return "00-\(traceId)-\(spanId)-01"
    }

    // MARK: - Attributes

    /// False for the no-op span, which ignores attributes and records nothing.
    @objc var isRecording: Bool {
        manager != nil
    }

    /// Calls `setAttributes` with this span only when it records. The no-op span ignores attributes, but their values
    /// would still be computed.
    ///
    /// Unlike the Android SDK's `recording { }`, this can't catch errors from `setAttributes`: Swift can't catch
    /// Objective-C exceptions. Keep the reads inside it to stored values and simple lookups, so tracing can't break
    /// the work it measures.
    @discardableResult
    func recording(_ setAttributes: (RadarTraceSpan) -> Void) -> RadarTraceSpan {
        if isRecording {
            setAttributes(self)
        }
        return self
    }

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
        guard value.isFinite else { return }
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
        let callbacks: [() -> Void]? = lock.withLock {
            if ended { return nil }
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
                attributes: attributes
            )
            // Record before marking the span ended, so a flush queued by an end listener uploads this span.
            manager.record(completed, project: project, sessionId: sessionId)
            return takeEndCallbacks()
        }
        callbacks?.forEach { $0() }
    }

    /// Calls `callback` after this span's record has been queued or the span has been discarded. It runs right away if
    /// the span has already ended or doesn't record.
    func onEnded(_ callback: @escaping () -> Void) {
        guard manager != nil else {
            callback()
            return
        }
        let runNow = lock.withLock {
            if ended { return true }
            endCallbacks.append(callback)
            return false
        }
        if runNow {
            callback()
        }
    }

    /// Ends the span without recording it, for work that turned out not to be worth a trace. Child spans that already
    /// ended are still recorded, so only discard a span with no children. End listeners still run.
    @objc func discard() {
        guard manager != nil else { return }
        let callbacks: [() -> Void]? = lock.withLock {
            if ended { return nil }
            return takeEndCallbacks()
        }
        callbacks?.forEach { $0() }
    }

    /// Marks the span ended and returns its end listeners. Call with lock held.
    private func takeEndCallbacks() -> [() -> Void] {
        ended = true
        defer { endCallbacks.removeAll() }
        return endCallbacks
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
        let digits = String(value, radix: 16)
        return String(repeating: "0", count: 16 - digits.count) + digits
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
