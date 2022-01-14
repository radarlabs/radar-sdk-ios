//
//  RadarEvent+Internal.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarBeacon.h"
#import "RadarEvent.h"
#import "RadarGeofence.h"
#import "RadarPlace.h"
#import "RadarTrip.h"
#import "RadarUser.h"
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

@interface RadarEvent ()

+ (NSArray<RadarEvent *> *_Nullable)eventsFromObject:(id _Nonnull)object;
- (instancetype _Nullable)initWithId:(NSString *_Nonnull)_id
                           createdAt:(NSDate *_Nonnull)createdAt
                     actualCreatedAt:(NSDate *_Nonnull)actualCreatedAt
                                live:(BOOL)live
                                type:(RadarEventType)type
                            geofence:(RadarGeofence *_Nullable)geofence
                               place:(RadarPlace *_Nullable)place
                              region:(RadarRegion *_Nullable)region
                              beacon:(RadarBeacon *_Nullable)beacon
                                trip:(RadarTrip *_Nullable)trip
                     alternatePlaces:(NSArray<RadarPlace *> *_Nullable)alternatePlaces
                       verifiedPlace:(RadarPlace *_Nullable)verifiedPlace
                        verification:(RadarEventVerification)verification
                          confidence:(RadarEventConfidence)confidence
                            duration:(float)duration
                            location:(CLLocation *_Nonnull)location;
- (instancetype _Nullable)initWithObject:(id _Nonnull)object;

@end
