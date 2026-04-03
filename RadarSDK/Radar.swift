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
//
//[[RadarAPIClient sharedInstance]
//    getDistanceFromOrigin:origin
//              destination:destination
//                    modes:mode
//                    units:RadarRouteUnitsMetric
//           geometryPoints:steps
//        completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, RadarRoutes *_Nullable routes) {
//            NSArray<RadarCoordinate *> *coordinates;
//            if (routes) {
//                if (mode == RadarRouteModeFoot && routes.foot && routes.foot.geometry) {
//                    coordinates = routes.foot.geometry.coordinates;
//                } else if (mode == RadarRouteModeBike && routes.bike && routes.bike.geometry) {
//                    coordinates = routes.bike.geometry.coordinates;
//                } else if (mode == RadarRouteModeCar && routes.car && routes.car.geometry) {
//                    coordinates = routes.car.geometry.coordinates;
//                } else if (mode == RadarRouteModeTruck && routes.truck && routes.truck.geometry) {
//                    coordinates = routes.truck.geometry.coordinates;
//                } else if (mode == RadarRouteModeMotorbike && routes.motorbike && routes.motorbike.geometry) {
//                    coordinates = routes.motorbike.geometry.coordinates;
//                }
//            }
//
//            if (!coordinates) {
//                if (completionHandler) {
//                    [RadarUtilsDeprecated runOnMainThread:^{
//                        completionHandler(status, nil, nil, nil);
//                    }];
//                }
//
//                return;
//            }
//
//            NSTimeInterval intervalLimit = interval;
//            if (intervalLimit < 1) {
//                intervalLimit = 1;
//            } else if (intervalLimit > 60) {
//                intervalLimit = 60;
//            }
//
//            __block int i = 0;
//            __block void (^track)(void);
//            __block __weak void (^weakTrack)(void);
//            track = ^{
//                weakTrack = track;
//                RadarCoordinate *coordinate = coordinates[i];
//                CLLocation *location = [[CLLocation alloc] initWithCoordinate:coordinate.coordinate
//                                                                     altitude:-1
//                                                           horizontalAccuracy:5
//                                                             verticalAccuracy:-1
//                                                                    timestamp:[NSDate new]];
//                BOOL stopped = (i == 0) || (i == coordinates.count - 1);
//
//                [[RadarAPIClient sharedInstance]
//                    trackWithLocation:location
//                              stopped:stopped
//                           foreground:NO
//                               source:RadarLocationSourceMockLocation
//                             replayed:NO
//                              beacons:nil
//                         indoorScan:nil
//                    completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarEvent *> *_Nullable events, RadarUser *_Nullable user,
//                                        NSArray<RadarGeofence *> *_Nullable nearbyGeofences, RadarConfig *_Nullable config, RadarVerifiedLocationToken *_Nullable token) {
//                        if (completionHandler) {
//                            [RadarUtilsDeprecated runOnMainThread:^{
//                                completionHandler(status, location, events, user);
//                            }];
//                        }
//
//                        if (i < coordinates.count - 1) {
//                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(intervalLimit * NSEC_PER_SEC)), dispatch_get_main_queue(), weakTrack);
//                        }
//
//                        i++;
//                    }];
//            };
//
//            track();
//        }];
