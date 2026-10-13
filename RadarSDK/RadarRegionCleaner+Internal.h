//
//  RadarRegionCleaner+Internal.h
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Declares the internal Swift RadarRegionCleaner for Objective-C callers, since internal Swift
// classes are not emitted into RadarSDK-Swift.h.
@interface RadarRegionCleaner : NSObject

// Reads Radar's monitored regions on a background queue, then stops them on locationManager on the main
// thread unless tracking is on by then. Pass the manager Radar registers regions on. Safe to call from
// any thread.
+ (void)removeAllRegionsUsingLocationManager:(CLLocationManager *)locationManager;

@end

NS_ASSUME_NONNULL_END
