//
//  Collector.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 2/8/26.
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
}
