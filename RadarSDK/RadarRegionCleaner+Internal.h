//
//  RadarRegionCleaner+Internal.h
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Declares the internal Swift RadarRegionCleaner for Objective-C callers, since internal Swift
// classes are not emitted into RadarSDK-Swift.h.
@interface RadarRegionCleaner : NSObject

// Removes Radar's monitored regions on a background queue, unless tracking is on.
+ (void)removeAllRegionsInBackground;

@end

NS_ASSUME_NONNULL_END
