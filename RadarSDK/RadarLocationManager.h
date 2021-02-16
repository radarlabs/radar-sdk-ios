//
//  RadarLocationManager.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Radar.h"
#import "RadarDelegate.h"
#import "RadarPermissionsHelper.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarLocationManager : NSObject<CLLocationManagerDelegate>

@property (nonnull, strong, nonatomic) CLLocationManager *locationManager;
@property (nonnull, strong, nonatomic) CLLocationManager *lowPowerLocationManager;
@property (nonnull, strong, nonatomic) RadarPermissionsHelper *permissionsHelper;

+ (instancetype)sharedInstance;
- (void)getLocationWithCompletionHandler:(RadarLocationCompletionHandler _Nullable)completionHandler;
- (void)getLocationWithDesiredAccuracy:(RadarTrackingOptionsDesiredAccuracy)desiredAccuracy completionHandler:(RadarLocationCompletionHandler _Nullable)completionHandler;
- (void)startTrackingWithOptions:(RadarTrackingOptions *)trackingOptions;
- (void)stopTracking;
- (void)replaceSyncedBeacons:(NSArray<RadarBeacon *> *)beacons;
- (void)updateTracking;

@end

NS_ASSUME_NONNULL_END
