//
//  RadarEvent+Internal.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarEvent.h"
#import "RadarGeofence.h"
#import "RadarJSONCoding.h"
#import "RadarPlace.h"
#import "RadarUser.h"
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

@interface RadarEvent ()<RadarJSONCoding>

+ (NSArray<RadarEvent *> *_Nullable)eventsFromObject:(id _Nonnull)object;
- (instancetype _Nullable)initWithId:(NSString *_Nonnull)_id
                           createdAt:(NSDate *_Nonnull)createdAt
                     actualCreatedAt:(NSDate *_Nonnull)actualCreatedAt
                                live:(BOOL)live
                                type:(RadarEventType)type
                            geofence:(RadarGeofence *_Nullable)geofence
                               place:(RadarPlace *_Nullable)place
                              region:(RadarRegion *_Nullable)region
                     alternatePlaces:(NSArray<RadarPlace *> *_Nullable)alternatePlaces
                       verifiedPlace:(RadarPlace *_Nullable)verifiedPlace
                        verification:(RadarEventVerification)verification
                          confidence:(RadarEventConfidence)confidence
                            duration:(float)duration
                            location:(CLLocation *_Nonnull)location;

@end
