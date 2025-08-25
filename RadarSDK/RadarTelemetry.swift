//
//  RadarTelemetry.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc @objcMembers
public class SpanContext : NSObject, Codable {
    let trace_id: String
    let span_id: String
    
    init(trace_id: String, span_id: String) {
        self.trace_id = trace_id
        self.span_id = span_id
    }
}

@objc @objcMembers
public class Span: NSObject, Codable {
    let name: String
    let context: SpanContext
    let parent_id: String?
    let start_time: Date
    var end_time: Date
    // limit these to [String: String] for now
    var attributes: [String: String]
    var events: [[String: String]]
    
    init(name: String, context: SpanContext, parent_id: String?, start_time: Date, end_time: Date, attributes: [String: String], events: [[String: String]]) {
        self.name = name
        self.context = context
        self.parent_id = parent_id
        self.start_time = start_time
        self.end_time = end_time
        self.attributes = attributes
        self.events = events
    }
}

@objc
extension Span {
    public func end() {
        end_time = Date()
    }
    
    public func endWithStatus(_ status: RadarStatus) {
        attributes["status"] = Radar.stringForStatus(status)
        end()
    }
}


@objc(Tracer) @objcMembers
public class Tracer: NSObject {
    
    let trace_id = {
        var uuidString = UUID().uuidString
        uuidString.removeAll(where: { $0 == "-" })
        return uuidString.lowercased()
    }()
    var spans = [String: Span]()
    @objc public var globalAttributes = [String: String]()
    
    func getSpanId() -> String {
        let value = UInt64.random(in: 0...UInt64.max)
        return String(format:"%02lx", value)
    }
    
    public func start(_ name: String, parent: SpanContext?) -> Span {
        let span_id = getSpanId()
        let span = Span(
            name: name,
            context: SpanContext(trace_id: trace_id, span_id: span_id),
            parent_id: parent?.span_id,
            start_time: Date(),
            end_time: Date(),
            attributes: globalAttributes,
            events: []
        )
        spans[span_id] = span
        return span
    }
    // this function is separate without using default function to provide an interface without the parent argument for Obj-C
    public func start(_ name: String) -> Span {
        return start(name, parent: nil)
    }
    
    public func with(_ name: String, parent: SpanContext? = nil, _ block: (_: Span) -> Void) {
        let span = start(name)
        block(span)
        span.end()
    }
    
    public func toString() -> String {
        let encoder = JSONEncoder()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        encoder.dateEncodingStrategy = .formatted(formatter)
        
        do {
            let data = try encoder.encode(Array(spans.values))
            if let jsonString = String(data: data, encoding: .utf8) {
                return jsonString
            }
        } catch {
            // json encode error
        }
        return ""
    }
}
