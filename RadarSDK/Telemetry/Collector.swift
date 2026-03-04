//
//  Collector.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

extension Otel {
    struct ExportTraceServiceRequest: Codable {
        let resourceSpans: [ResourceSpan]
    }
    
    struct ExportTraceServiceResponse: Codable {
        let partialSuccess: ExportTracePartialSuccess?
        
        struct ExportTracePartialSuccess: Codable {
            let rejectedSpans: Int
            let errorMessage: String
        }
    }
    
    struct ExportMetricsServiceRequest: Codable {
        let resourceMetrics: [ResourceMetrics]
    }
    
    struct ExportMetricsServiceResponse: Codable {
        let partialSuccess: ExportMetricsPartialSuccess?
        
        struct ExportMetricsPartialSuccess: Codable {
            let rejectedDataPoints: Int
            let errorMessage: String
        }
    }
}


