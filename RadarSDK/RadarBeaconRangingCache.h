//
//  RadarBeaconRangingCache.h
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RadarBeacon.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarBeaconRangingCache : NSObject

@property (class, readonly, strong) RadarBeaconRangingCache *shared;

- (void)start;

- (void)stop;

- (void)updateBeacons:(NSArray<RadarBeacon *> *_Nullable)beacons uuids:(NSArray<NSString *> *_Nullable)uuids;

- (NSArray<RadarBeacon *> *_Nullable)cachedBeacons;

@end

NS_ASSUME_NONNULL_END
