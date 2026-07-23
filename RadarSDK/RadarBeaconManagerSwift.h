//
//  RadarBeaconManagerSwift.h
//  RadarSDK
//
//  Created by Alan Charles on 7/10/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

#import "Radar.h"
#import "RadarBeacon.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarBeaconManagerSwift : NSObject

@property (class, readonly, strong) RadarBeaconManagerSwift *shared;

- (void)rangeBeacons:(NSArray<RadarBeacon *> *)beacons
   completionHandler:(RadarBeaconCompletionHandler)completionHandler;

- (void)rangeBeaconUUIDs:(NSArray<NSString *> *)beaconUUIDs
       completionHandler:(RadarBeaconCompletionHandler)completionHandler;

- (void)stopRanging;

- (void)handleBeaconEntryForRegion:(CLBeaconRegion *)region
                 completionHandler:(RadarBeaconCompletionHandler)completionHandler;

- (void)handleBeaconExitForRegion:(CLBeaconRegion *)region
                completionHandler:(RadarBeaconCompletionHandler)completionHandler;

- (void)handleBeaconUUIDEntryForRegion:(CLBeaconRegion *)region
                     completionHandler:(RadarBeaconCompletionHandler)completionHandler;

- (void)handleBeaconUUIDExitForRegion:(CLBeaconRegion *)region
                    completionHandler:(RadarBeaconCompletionHandler)completionHandler;

- (void)registerBeaconRegionNotificationsFromArray:(NSArray<NSDictionary<NSString *, id> *> *)beaconArray;

@end

NS_ASSUME_NONNULL_END
