//
//  RadarTelemetry.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing
@testable
import RadarSDK

// run tests in series because we want to test UserDefaults.standard, which is a shared instance
actor RadarTelemetryTest {
    @Suite("SpanContext is real")
    struct SpanContext {
        @Test("Has API to create SpanContext")
        func create() async {
            
        }
        
        @Test("Has API to retrieve TraceId and SpanId")
        func traceIdAndSpanId() async {
            
        }
        
        @Test("Has API IsValid")
        func isValid() async {
            
        }
        
        @Test("Has API IsRemote")
        func isRemote() async {
            
        }
        
        @Test("Has API to get value for TraceState key")
        func traceStateGet() async {
            
        }
        
        @Test("Has API to set value for TraceState key")
        func traceStateSet() async {
            
        }
        
        @Test("Has API to update value for TraceState key")
        func traceStateUpdate() async {
            
        }
        
        @Test("Has API to remove key/value for TraceState")
        func traceStateRemove() async {
            
        }
    }
    
    @Test("Get a Tracer from TraceProvider")
    func getTracer() async {
        let provider = TraceProvider()
        let tracer = provider.getTracer(name: "test", version: "1.0.0")
        #expect(tracer.toString() == "")
    }
    
    @Test("Creates a span")
    func CreatesASpan() async {
        let tracer = Tracer()
        await tracer.with("test") { span in
            try? await Task.sleep(nanoseconds: 100_000)
        }
        
        #expect(tracer.toString() == "")
    }
    
    @Suite("Json encoding")
    struct JsonEncoding {
        @Test("Can encode to Json")
        func encode() async {
            
        }
        
        func decode() async {
            
        }
    }
    
}
