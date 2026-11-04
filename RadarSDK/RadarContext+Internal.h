//
//  RadarContext+Internal.h
//  RadarSDK
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "RadarGeofence.h"
#import "RadarPlace.h"
#import <Foundation/Foundation.h>

#if __has_include(<RadarSDK/RadarSDK-Swift.h>)
#import <RadarSDK/RadarSDK-Swift.h>
#elif __has_include("RadarSDK-Swift.h")
#import "RadarSDK-Swift.h"
#endif

@interface RadarContext ()

- (instancetype _Nonnull)initWithGeofences:(NSArray<RadarGeofence *> *_Nonnull)geofences
                                     place:(RadarPlace *_Nullable)place
                                   country:(RadarRegion *_Nullable)country
                                     state:(RadarRegion *_Nullable)state
                                       dma:(RadarRegion *_Nullable)dma
                                postalCode:(RadarRegion *_Nullable)postalCode;

- (instancetype _Nullable)initWithObject:(id _Nonnull)object;

@end
