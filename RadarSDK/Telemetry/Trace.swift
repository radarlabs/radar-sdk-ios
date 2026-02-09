//
//  Trace.swift
//  RadarSDK
//

extension Otel {
    struct TraceData: Codable {
        let resourceSpans: [ResourceSpan]
    }
    
    struct ResourceSpan: Codable {
        let resource: Resource
        let scopeSpans: [ScopeSpans]
        let schemaUrl: String?
    }
    
    struct ScopeSpans: Codable {
        let scope: InstrumentationScope
        let spans: [Span]
        let schemaUrl: String?
    }
    
    struct Span: Codable {
        let traceId: String // hex string
        let spanId: String // hex string
        let traceState: String?
        let parentSpanId: String? // hex string
        let flags: Int32?
        let name: String
        
        enum SpanKind: Int32, Codable {
            case UNSPECIFIED = 0;
            case INTERNAL = 1; // default
            case SERVER = 2;
            case CLIENT = 3;
            case PRODUCER = 4;
            case CONSUMER = 5;
        }
        let kind: SpanKind
        let startTimeUnixNano: UInt64
        let endTimeUnixNano: UInt64
        let attributes: [KeyValue]?
        let droppedAttributesCount: UInt32?
        
        struct Event: Codable {
            let timeUnixNano: UInt64
            let name: String
            let attributes: [KeyValue]?
            let droppedAttributesCount: UInt32?
        }
        let events: [Event]?
        let droppedEventsCount: UInt32?
        
        struct Link: Codable {
            let traceId: String
            let spanId: String
            let traceState: String?
            let attributes: [KeyValue]?
            let droppedAttributesCount: UInt32?
            let flags: UInt32?
        }
        let links: [Link]?
        let droppedLinksCount: UInt32?
        
        let status: Status
    }
    
    struct Status: Codable {
        let message: String?
        
        enum StatusCode: Int, Codable {
            case UNSET = 0;
            case OK    = 1;
            case ERROR = 2;
        }
        let code: StatusCode
    }
    
    enum SpanFlags: UInt32 {
        case SPAN_FLAGS_DO_NOT_USE = 0;
        case SPAN_FLAGS_TRACE_FLAGS_MASK = 0x000000FF;
        case SPAN_FLAGS_CONTEXT_HAS_IS_REMOTE_MASK = 0x00000100;
        case SPAN_FLAGS_CONTEXT_IS_REMOTE_MASK = 0x00000200;
    }
}
