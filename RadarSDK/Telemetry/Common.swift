//
//  Common.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

class Otel {
    struct AnyValue: Codable {
        let stringValue: String?
        let boolValue: Bool?
        let intValue: Int?
        let doubleValue: Double?
        let arrayValue: ArrayValue?
        let kvlistValue: KeyValueList?
        let bytesValue: Data?
    }
    
    struct ArrayValue: Codable {
        let values: [AnyValue]
    }
    
    struct KeyValueList: Codable {
        let values: [KeyValue]
    }
    
    struct KeyValue: Codable {
        let key: String
        let value: AnyValue
    }
    
    struct InstrumentationScope: Codable {
        let name: String
        let version: String
        let attributes: [KeyValue]
        let droppedAttributesCount: Int
    }
    
    struct EntityRef: Codable {
        let schemaUrl: String
        let type: String
        let idKeys: [String]
        let descriptionKeys: [String]
    }
}
