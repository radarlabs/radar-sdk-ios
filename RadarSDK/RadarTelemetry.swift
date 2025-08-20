//
//  RadarTelemetry.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc @objcMembers
public class SpanContext : NSObject, Codable {
    let trace_id: UUID
    let span_id: String
    
    init(trace_id: UUID, span_id: String) {
        self.trace_id = trace_id
        self.span_id = span_id
    }
}

struct Span: Codable {
    let name: String
    let context: SpanContext
    let parent_id: String?
    let start_time: Date
    var end_time: Date
    // limit these to [String: String] for now
    var attributes: [String: String]
    var events: [[String: String]]
}

@objc(Tracer) @objcMembers
public class Tracer: NSObject {
    
    let trace_id = UUID()
    var active_spans = [SpanContext: Span]()
    var complete_spans = [Span]()
    
    
    
    public func start(_ name: String, parent: SpanContext?) -> SpanContext {
        let context = SpanContext(trace_id: trace_id, span_id: UUID().uuidString)
        let span = Span(
            name: name,
            context: context,
            parent_id: parent?.span_id,
            start_time: Date(),
            end_time: Date(),
            attributes: [:],
            events: []
        )
        active_spans[context] = span
        return context
    }
    // this function is separate without using default function to provide an interface without the parent argument for Obj-C
    public func start(_ name: String) -> SpanContext {
        return start(name, parent: nil)
    }
    
    public func end(_ context: SpanContext) {
        guard var span = active_spans[context] else { return }
        
        span.end_time = Date()
        
        complete_spans.append(span)
        active_spans.removeValue(forKey: context)
    }
    
    @objc(complete:withStatus:)
    public func complete(_ context: SpanContext, status: RadarStatus) {
        addAttributes(context, attributes: ["status": Radar.stringForStatus(status)])
        end(context)
    }
    
    public func with(_ name: String, parent: SpanContext? = nil, _ block: (_: SpanContext) -> Void) {
        let context = start(name)
        block(context)
        end(context)
    }
    
    public func toString() -> String {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(complete_spans)
            if let jsonString = String(data: data, encoding: .utf8) {
                print(jsonString)
                return jsonString
            }
        } catch {
            // json encode error
        }
        return ""
    }
    
    // add an attribute to a active span
    public func addAttributes(_ context: SpanContext, attributes: [String: String]) {
        if var span = active_spans[context] {
            span.attributes.merge(attributes) { (_, new) in new }
            active_spans[context] = span
        }
    }
}
