//
//  RadarSdkTests.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 4/3/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Testing
import CoreLocation
@testable import RadarSDK

@Suite
struct RadarParallelTests {
    @Suite
    struct RadarSDKTests {
        
        @Test(.timeLimit(.minutes(2)))
        func mockTracking() async throws {
            RadarSettings.publishableKey = "test-key" // set something so that publishableKey != nil check passes
            let mockSession = MockURLSession()
            let mockClient = RadarAPIClient(apiHelper: RadarApiHelper(session: mockSession))
            let radar = Radar_Swift(apiClient: mockClient)
            
            print(mockSession)
            
            mockSession.on(MockURLSession.urlMatch("\(RadarSettings.host)/v1/route/distance"), RadarTestUtils.data(fromResource: "route_distance")!)
            mockSession.on(MockURLSession.urlMatch("\(RadarSettings.host)/v1/track"), RadarTestUtils.data(fromResource: "track")!)
            
            
            let origin = CLLocation(latitude: 40.78382, longitude: -73.97536)
            let destination = CLLocation(latitude: 40.70390, longitude: -73.98670)
            let steps = 20
            
            var stepCount = 0
            
            await radar.mockTracking(origin: origin, destination: destination, mode: .car, steps: 20, interval: 0.2, onTrack: { result in
                stepCount += 1
                
                #expect(result["status"] as? Int == RadarStatus.success.rawValue)
                #expect(result["location"] as? CLLocation != nil)
                #expect(result["user"] != nil)
                #expect(result["events"] != nil)
            })
            
            #expect(stepCount == steps, "Expected \(steps) callbacks but got \(stepCount)")
        }
    }
}
