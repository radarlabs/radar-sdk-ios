//
//  RadarLocationManagerSwift+Internal.h
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

#import "RadarLocationManagerSwift.h"

NS_ASSUME_NONNULL_BEGIN

// Internal helpers that the Objective-C and Swift `startUpdates` paths share. They are in this
// header and not in RadarLocationManagerSwift.h, because the podspec makes only `+Internal.h`
// headers private.
@interface RadarLocationManagerSwift (Internal)

+ (NSTimeInterval)monotonicTime;
+ (void)recordLocationUpdateWithHost:(id<RadarLocationManagerSwiftHost>)host manager:(CLLocationManager *)manager locations:(nullable NSArray<CLLocation *> *)locations;
+ (BOOL)usesContinuousUpdatesWithInterval:(int)interval blueBar:(BOOL)blueBar;
+ (BOOL)timerShouldRequestLocationWithContinuousUpdates:(BOOL)continuousUpdates
                                               interval:(int)interval
                                 lastLocationUpdateTime:(NSTimeInterval)lastLocationUpdateTime
                                                    now:(NSTimeInterval)now;

@end

NS_ASSUME_NONNULL_END
