//
//  RadarBeaconManager.h
//  Library
//
//  Created by Ping Xia on 4/28/20.
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "Radar.h"
#import "RadarBeacon.h"
#import "RadarDelegate.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^RadarBeaconMonitorCompletionHandler)(RadarStatus status, NSArray<RadarBeacon *> *_Nullable nearbyBeacons);

/// Manager class for beacon monitoring
@interface RadarBeaconManager : NSObject

@property (nonatomic, weak, nullable) id<RadarDelegate> delegate;

+ (instancetype)sharedInstance;

/// One time detection on beacons
/// @param radarBeacons the list of beacons to monitor / detect
/// @param block completion block which will be called on the internal queue of RadarBeaconManager
- (void)monitorOnceForRadarBeacons:(NSArray<RadarBeacon *> *)radarBeacons completionBlock:(RadarBeaconMonitorCompletionHandler)block;

@end

NS_ASSUME_NONNULL_END
