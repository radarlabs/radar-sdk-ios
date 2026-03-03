//
//  Meter.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 2/26/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

extension Otel {
    struct MetricsData: Codable {
        let resourceMetrics: [ResourceMetrics]
    }
    
    struct ResourceMetrics: Codable {
        let resource: Resource
        let scopeMetrics: [ScopeMetrics]
    }
    
    struct ScopeMetrics: Codable {
        let scope: InstrumentationScope
        let metrics: [Metric]
        let schemaUrl: String?
    }
    
    struct Metric: Codable {
        let name: String
        let description: String
        let unit: String
        // oneof
        let gauge: Gauge?
        let sum: Sum?
        let histogram: Histogram?
        let exponentialHistogram: ExponentialHistogram?
        let summary: Summary?
        // end oneof
    }
    
    struct Gauge: Codable {
        let dataPoints: [NumberDataPoint]
    }
    
    struct Sum: Codable {
        let dataPoints: [NumberDataPoint]
        let aggregationTemporality: AggregationTemporality
        let isMonotonic: Bool
    }
    
    struct Histogram: Codable {
        let dataPoints: [HistogramDataPoint]
        let aggregationTemporality: AggregationTemporality
    }
    
    struct ExponentialHistogram: Codable {
        let dataPoints: [ExponentialHistogramDataPoint]
        let aggregationTemporality: AggregationTemporality
    }
    
    struct Summary: Codable {
        let dataPoints: [SummaryDataPoint]
    }
    
    enum AggregationTemporality: UInt32, Codable {
        case AGGREGATION_TEMPORALITY_UNSPECIFIED = 0;
        case AGGREGATION_TEMPORALITY_DELTA = 1;
        case AGGREGATION_TEMPORALITY_CUMULATIVE = 2;
    }
    
    struct NumberDataPoint: Codable {
        let attributes: KeyValue
        let startTimeUnixNano: UInt64
        let timeUnixNano: UInt64
        // oneof
        let as_double: Double?
        let as_int: Int64?
        // end oneof
        let exemplars: [Exemplar]
        let flags: UInt32
    }
    
    struct HistogramDataPoint: Codable {
        let attributes: KeyValue
        let startTimeUnixNano: UInt64
        let timeUnixNano: UInt64
        let count: UInt64
        let sum: Double?
        let bucketCounts: [UInt64]
        let explicitBounds: [Double]
        let exemplars: [Exemplar]
        let flags: UInt32
        let min: Double?
        let max: Double?
    }
    
    struct ExponentialHistogramDataPoint: Codable {
        let attributes: KeyValue
        let startTimeUnixNano: UInt64
        let timeUnixNano: UInt64
        let count: UInt64
        let sum: Double?
        let scale: Int32
        let zeroCount: UInt64
        let positive: Buckets
        let negative: Buckets
        struct Buckets: Codable {
            let offset: Int32
            let bucketCounts: [UInt64]
        }
        let flags: UInt32
        let exemplars: [Exemplar]?
        let min: Double?
        let max: Double?
        let zeroThreshold: Double?
    }
    
    struct SummaryDataPoint: Codable {
        let attributes: KeyValue
        let startTimeUnixNano: UInt64
        let timeUnixNano: UInt64
        let count: UInt64
        let sum: Double?
        struct ValueAtQuantile: Codable {
            let quantile: Double
            let value: Double
        }
        let quantileValues: [ValueAtQuantile]?
        let flags: UInt32
    }
    
    struct Exemplar: Codable {
        let filteredAttributes: [KeyValue]
        let timeUnixNano: UInt64
        // oneof
        let as_double: Double?
        let as_int: Int64?
        // end oneof
        let spanId: String? // hex string
        let traceId: String? // hex string
    }
}
