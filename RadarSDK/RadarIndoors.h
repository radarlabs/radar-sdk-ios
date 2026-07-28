//
//  RadarIndoors.h
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "RadarGeofence.h"

@interface RadarIndoors : NSObject

+ (RadarIndoors * _Nonnull)shared;

- (void)updateTrackingWithGeofences:(NSArray<RadarGeofence *> * _Nullable)geofences completionHandler:(void (^ _Nonnull)(void))completionHandler;
- (void)getLocationWithCompletionHandler:(void (^ _Nonnull)(CLLocation * _Nullable))completionHandler;
- (nonnull instancetype)init;
@end
