//
//  Header.h
//  RadarSDK
//
//  Created by Kenny Hu on 10/16/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "RadarConfig.h"
#import "RadarUtils.h"
#import "RadarEvent+Internal.h"
#import "RadarUser+Internal.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarOfflineManager : NSObject

+ (NSArray<RadarGeofence *> *)getUserGeofencesFromLocation:(CLLocation *)location;

+ (void)updateTrackingOptionsFromOfflineLocation:(NSArray<RadarGeofence *> *)userGeofences completionHandler:(void (^)(RadarConfig *))completionHandler;

+ (void)generateEventsFromOfflineLocations:(CLLocation *)location userGeofences:(NSArray<RadarGeofence *> *)userGeofences completionHandler:(void (^)(NSArray<RadarEvent *> *, RadarUser *, CLLocation *))completionHandler;

@end

NS_ASSUME_NONNULL_END
