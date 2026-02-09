//
//  RadarTelemetry.swift
//  RadarSDK
//
//  following closely to https://opentelemetry.io/docs/specs/otel/trace/api/ as much as possible while keeping implementation simple
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

struct Context {
    // the span id stack
    var spanIds = [String]()
}

@objc(Span) @objcMembers
public class Span: NSObject {
    let name: String
    let spanId: String
    let parentSpanId: String?
    let startTime: Date
    var endTime: Date?
    
    init(name: String, spanId: String, parentSpanId: String?) {
        self.name = name
        self.spanId = spanId
        self.parentSpanId = parentSpanId
        self.startTime = Date()
    }
    
    func end() {
        self.endTime = Date()
    }
}

@objc(Tracer) @objcMembers
public class Tracer: NSObject {
    
    let name: String
    var context: Context
    
    init(name: String) {
        self.name = name
        
        self.context = Context()
        
        super.init()
    }
    
    public var enabled = false
    
    let traceId = {
        var uuidString = UUID().uuidString
        uuidString.removeAll(where: { $0 == "-" })
        return uuidString.lowercased()
    }()
    var spans = [Span]()
    @objc public var globalAttributes = [String: String]()
    
    func getSpanId() -> String {
        let value = UInt64.random(in: 0...UInt64.max)
        return String(format:"%02lx", value)
    }
    
    public func start(_ name: String, parent: String?) -> Span {
        let span = Span(
            name: name,
            spanId: getSpanId(),
            parentSpanId: parent,
        )
        spans.append(span)
        return span
    }
    // this function is separate without using default function to provide an interface without the parent argument for Obj-C
    public func start(_ name: String) -> Span {
        return start(name, parent: nil)
    }
    
    public func with(_ name: String, parent: String? = nil, _ block: (_: Span) -> Void) {
        let span = start(name)
        block(span)
        span.end()
    }
    
    @available(iOS 13.0, *)
    public func with(_ name: String, parent: String? = nil, _ block: (_: Span) async -> Void) async {
        let span = start(name)
        await block(span)
        span.end()
    }
    
    @available(iOS 13.0, *)
    public func toString() -> String {
        let encoder = JSONEncoder()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        encoder.dateEncodingStrategy = .formatted(formatter)
        
        do {
            let data = try encoder.encode(spans.map { span in
                Otel.Span(traceId: traceId, spanId: span.spanId, traceState: "trace-state-ok", parentSpanId: span.parentSpanId, flags: 0, name: span.name, kind: .CLIENT, startTimeUnixNano: UInt64(span.startTime.timeIntervalSince1970 * 1_000_000_000), endTimeUnixNano: UInt64(span.endTime!.timeIntervalSince1970 * 1_000_000_000), attributes: [], droppedAttributesCount: 0, events: [], droppedEventsCount: 0, links: [], droppedLinksCount: nil, status: Otel.Status(message: "OK", code: .OK)
                )
            } )
            if let jsonString = String(data: data, encoding: .utf8) {
                return jsonString
            }
        } catch {
            // json encode error
        }
        return ""
    }
}

@objc @objcMembers
public class TraceProvider: NSObject {
    
    let shared: TraceProvider = TraceProvider()
    
    var tracers = [String: Tracer]()
    
    func getTracer(name: String?, version: String?) -> Tracer {
        if (name == nil) {
            print("Invalid tracer name")
        }
        let name = name ?? ""
        if let tracer = tracers[name] {
            return tracer
        } else {
            let tracer = Tracer(name: name)
            tracers[name] = tracer
            return tracer
        }
    }
}



