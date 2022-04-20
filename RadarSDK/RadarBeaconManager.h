//
//  RadarBeaconManager.h
//  RadarSDK
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

#import "Radar.h"
#import "RadarBeacon.h"
#import "RadarPermissionsHelper.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarBeaconManager : NSObject<CLLocationManagerDelegate>

@property (nonnull, strong, nonatomic) CLLocationManager *locationManager;
@property (nonnull, strong, nonatomic) RadarPermissionsHelper *permissionsHelper;

+ (instancetype)sharedInstance;
- (void)rangeBeacons:(NSArray<RadarBeacon *> *_Nonnull)beacons completionHandler:(RadarBeaconCompletionHandler)completionHandler;
- (void)rangeUUIDs:(NSArray<NSString *> *_Nonnull)uuids completionHandler:(RadarBeaconCompletionHandler)completionHandler;
- (void)handleBeaconEntryForRegion:(CLBeaconRegion *)region completionHandler:(RadarBeaconCompletionHandler)completionHandler;
- (void)handleBeaconExitForRegion:(CLBeaconRegion *)region completionHandler:(RadarBeaconCompletionHandler)completionHandler;
- (void)handleBeaconUUIDEntryForRegion:(CLBeaconRegion *)region completionHandler:(RadarBeaconCompletionHandler)completionHandler;
- (void)handleBeaconUUIDExitForRegion:(CLBeaconRegion *)region completionHandler:(RadarBeaconCompletionHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END
