//
//  RadarEvent+Internal.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "RadarEvent.h"
#import "RadarUser.h"
#import "RadarGeofence.h"
#import "RadarPlace.h"

@interface RadarEvent ()

+ (NSArray<RadarEvent *> * _Nullable)eventsFromObject:(id _Nonnull)object;
- (instancetype _Nullable)initWithId:(NSString * _Nonnull)_id createdAt:(NSDate * _Nonnull)createdAt actualCreatedAt:(NSDate *_Nonnull)actualCreatedAt live:(BOOL)live type:(RadarEventType)type geofence:(RadarGeofence * _Nullable)geofence place:(RadarPlace * _Nullable)place region:(RadarRegion * _Nullable)region alternatePlaces:(NSArray<RadarPlace *> * _Nullable)alternatePlaces verifiedPlace:(RadarPlace * _Nullable)verifiedPlace verification:(RadarEventVerification)verification confidence:(RadarEventConfidence)confidence duration:(float)duration location:(CLLocation *_Nonnull)location;
- (instancetype _Nullable)initWithObject:(id _Nonnull)object;

@end
