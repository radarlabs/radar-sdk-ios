//
//  RadarContinuousBeaconManager.h
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

#import "Radar.h"
#import "RadarBeacon.h"

NS_ASSUME_NONNULL_BEGIN

// Implemented in RadarContinuousBeaconManager.swift. It's internal, so it isn't in RadarSDK-Swift.h.
@interface RadarContinuousBeaconManager : NSObject

@property (class, readonly, strong) RadarContinuousBeaconManager *shared;

- (NSArray<RadarBeacon *> *_Nullable)beaconsNear:(CLLocation *)location;

- (void)handleSearchFrom:(CLLocation *)location
                  status:(RadarStatus)status
             beaconUUIDs:(NSArray<NSString *> *_Nullable)beaconUUIDs
                 beacons:(NSArray<RadarBeacon *> *_Nullable)beacons;

@end

NS_ASSUME_NONNULL_END
