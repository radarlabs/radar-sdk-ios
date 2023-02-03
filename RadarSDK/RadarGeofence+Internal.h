//
//  RadarGeofence+Internal.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarGeofence.h"
#import <Foundation/Foundation.h>

@interface RadarGeofence ()

+ (NSArray<RadarGeofence *> *_Nullable)geofencesFromObject:(id _Nonnull)object;
- (instancetype _Nullable)initWithId:(NSString *_Nonnull)_id
                         description:(NSString *_Nonnull)description
                                 tag:(NSString *_Nullable)tag
                          externalId:(NSString *_Nullable)externalId
                            metadata:(NSDictionary *_Nullable)metadata
                            geometry:(RadarGeofenceGeometry *_Nonnull)geometry;
- (instancetype _Nullable)initWithObject:(id _Nonnull)object;

@end
