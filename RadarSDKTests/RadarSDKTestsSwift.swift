//
//  RadarSDKTests.swift
//  RadarSDKTests
//
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@Suite("SDK Tests")
struct RadarSDKTestsSwift {
    
    @Test func test_profiler() async throws {
        let telemetry = RadarTelemetry()
        telemetry.start("total")
        telemetry.start("test")
        
        usleep(1500000)
        
        telemetry.end("test")
        
        #expect(telemetry.formatted() == String(format: "test: %.3f", telemetry.get("test")))
        
        telemetry.start("other")
        
        usleep(1000000)
        
        telemetry.end("other")
        telemetry.end("total")
        
        #expect(telemetry.get("other") < telemetry.get("test"))
        #expect(telemetry.get("total") >= telemetry.get("test") + telemetry.get("other"))
        
        #expect(telemetry.formatted().contains(String(format: "other: %.3f", telemetry.get("other"))))
        #expect(telemetry.formatted().contains(String(format: "total: %.3f", telemetry.get("total"))))
        #expect(telemetry.formatted().contains(String(format: "test: %.3f", telemetry.get("test"))))
    }
}
