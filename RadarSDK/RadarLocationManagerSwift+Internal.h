//
//  RadarLocationManagerSwift+Internal.h
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RadarLocationManagerSwift.h"

NS_ASSUME_NONNULL_BEGIN

// Internal helpers that the Objective-C and Swift `startUpdates` paths share. They are in this
// header and not in RadarLocationManagerSwift.h, because the podspec makes only `+Internal.h`
// headers private.
@interface RadarLocationManagerSwift (Internal)

+ (BOOL)usesContinuousUpdatesWithInterval:(int)interval blueBar:(BOOL)blueBar;
+ (BOOL)timerShouldRequestLocationWithContinuousUpdates:(BOOL)continuousUpdates
                                               interval:(int)interval
                               lastLocationUpdateUptime:(NSTimeInterval)lastLocationUpdateUptime
                                                 uptime:(NSTimeInterval)uptime;

@end

NS_ASSUME_NONNULL_END
