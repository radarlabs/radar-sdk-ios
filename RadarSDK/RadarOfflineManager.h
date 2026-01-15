//
//  RadarOfflineManager.h
//  RadarSDK
//
//  Created by Alan Charles on 1/15/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "RadarConfig.h"
#import "RadarUtils.h"
#import "RadarEvent+Internal.h"
#import "RadarUser+Internal.h"
#import "RadarBeacon.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarOfflineManager : NSObject

+ (NSArray<RadarGeofence *> *)getUserGeofencesFromLocation:(CLLocation *)location;

+ (NSArray<RadarBeacon *> *)getBeaconsFromLocation:(CLLocation *)location;

+ (void)updateTrackingOptionsFromOfflineLocation:(NSArray<RadarGeofence *> *)userGeofences completionHandler:(void (^)(RadarConfig *))completionHandler;

+ (void)generateEventsFromOfflineLocations:(CLLocation *)location userGeofences:(NSArray<RadarGeofence *> *)userGeofences completionHandler:(void (^)(NSArray<RadarEvent *> *, RadarUser *, CLLocation *))completionHandler;

@end

NS_ASSUME_NONNULL_END
