//
//  RadarUser+Internal.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RadarUser.h"
#import "RadarGeofence.h"
#import "RadarUserInsights.h"

@interface RadarUser ()

- (instancetype _Nullable)initWithId:(NSString * _Nonnull)_id userId:(NSString * _Nullable)userId deviceId:(NSString * _Nullable)deviceId description:(NSString * _Nullable)description metadata:(NSDictionary * _Nullable)metadata location:(CLLocation * _Nonnull)location geofences:(NSArray * _Nullable)geofences place:(RadarPlace * _Nullable)place insights:(RadarUserInsights * _Nullable)insights stopped:(BOOL)stopped foreground:(BOOL)foreground country:(RadarRegion * _Nullable)country state:(RadarRegion * _Nullable)state dma:(RadarRegion * _Nullable)dma postalCode:(RadarRegion * _Nullable)postalCode nearbyPlaceChains:(nullable NSArray<RadarChain *> *)nearbyPlaceChains;
- (instancetype _Nullable)initWithObject:(id _Nonnull)object;

@end
