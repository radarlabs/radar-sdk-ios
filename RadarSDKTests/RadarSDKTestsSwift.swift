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
        let profiler = RadarProfiler()
        profiler.start("total")
        profiler.start("test")
        
        usleep(1500000)
        
        profiler.end("test")
        
        #expect(profiler.formatted() == String(format: "test: %.3f", profiler.get("test")))
        
        profiler.start("other")
        
        usleep(1000000)
        
        profiler.end("other")
        profiler.end("total")
        
        #expect(profiler.get("other") < profiler.get("test"))
        #expect(profiler.get("total") >= profiler.get("test") + profiler.get("other"))
        
        #expect(profiler.formatted().contains(String(format: "other: %.3f", profiler.get("other"))))
        #expect(profiler.formatted().contains(String(format: "total: %.3f", profiler.get("total"))))
        #expect(profiler.formatted().contains(String(format: "test: %.3f", profiler.get("test"))))
    }
}
