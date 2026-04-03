//
//  Radar.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 4/1/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//



@available(iOS 13.0, *)
@objc(Radar_Swift) @objcMembers
final class Radar_Swift: NSObject, Sendable {
    
    public static let shared = Radar_Swift()
    
    nonisolated(unsafe)
    let apiClient: RadarAPIClient
    
    init(apiClient: RadarAPIClient? = nil) {
        if let apiClient {
            self.apiClient = apiClient
        } else {
            self.apiClient = RadarAPIClient.shared
        }
    }
    
    public func mockTracking(origin: CLLocation, destination: CLLocation, mode: RadarRouteMode, steps: Int, interval: TimeInterval, onTrack: @escaping ([String: Any]) -> Void) async {
        do {
            let routes = try await apiClient.getDistance(origin: origin, destination: destination, modes: mode, units: .metric, points: steps)
            
            guard let coordinates = routes.car?.geometry.coordinates else {
                print("no coords")
                return
            }
            
            for coordinate in coordinates {
                let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                
                var result = try await apiClient.track(location: location, stopped: false, foreground: false, source: .mockLocation, replayed: false, beacons: nil)
                result["location"] = location
                result["status"] = RadarStatus.success.rawValue
                onTrack(result)
                
                try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        } catch {
            print("error \(error)")
            onTrack([
                "status": RadarStatus.errorServer.rawValue
            ])
        }
    }
}
