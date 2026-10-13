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

// Reads Radar's monitored regions on a background queue, then stops them on the main thread unless
// tracking is on. Call on the main thread with the manager Radar registers regions on.
+ (void)removeAllRegionsUsingLocationManager:(CLLocationManager *)locationManager;

// Call on the main thread whenever synced regions are registered, so a pending cleanup doesn't
// remove them.
+ (void)didRegisterRegions;

@end

NS_ASSUME_NONNULL_END
