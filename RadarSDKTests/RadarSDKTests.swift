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


struct RadarSdkTests {

    @Test(.timeLimit(.minutes(1)))
    func mockTracking() async throws {
        let mockSession = MockURLSession()
        let mockClient = RadarAPIClient(apiHelper: RadarApiHelper(session: mockSession))
        let radar = Radar_Swift(apiClient: mockClient)
        
        guard let routeResponse = RadarTestUtilsSwift.data(fromResource: "route_distance") else {
            Issue.record("invalid resource 'route_distance'")
            return
        }
        mockSession.on({ request in
            request.url?.absoluteString.starts(with: "\(RadarSettings.host)/v1/route/distance") == true
        }, routeResponse)
        
        
        guard let routeResponse = RadarTestUtilsSwift.data(fromResource: "track") else {
            Issue.record("invalid resource 'track'")
            return
        }
        mockSession.on({ request in
            request.url?.absoluteString.starts(with: "\(RadarSettings.host)/v1/track") == true
        }, routeResponse)
        

        let origin = CLLocation(latitude: 40.78382, longitude: -73.97536)
        let destination = CLLocation(latitude: 40.70390, longitude: -73.98670)
        let steps = 20
        let expireTimeout: TimeInterval = 10.0

        var stepCount = 0
        
        await radar.mockTracking(origin: origin, destination: destination, mode: .car, steps: 20, interval: 1, onTrack: { result in
            stepCount += 1
//            status, location, events, user
//            #expect(result["status"])d
        })

        #expect(stepCount == steps, "Expected \(steps) callbacks but got \(stepCount)")
    }
}
