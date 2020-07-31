//
//  RadarEvent.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarEvent.h"
#import "RadarCollectionAdditions.h"
#import "RadarCoordinate+Internal.h"
#import "RadarEvent+Internal.h"
#import "RadarGeofence+Internal.h"
#import "RadarPlace+Internal.h"
#import "RadarRegion+Internal.h"

@implementation RadarEvent

- (instancetype _Nullable)initWithId:(NSString *)_id
                           createdAt:(NSDate *)createdAt
                     actualCreatedAt:(NSDate *)actualCreatedAt
                                live:(BOOL)live
                                type:(RadarEventType)type
                            geofence:(RadarGeofence *)geofence
                               place:(RadarPlace *)place
                              region:(RadarRegion *)region
                     alternatePlaces:(NSArray<RadarPlace *> *)alternatePlaces
                       verifiedPlace:(RadarPlace *)verifiedPlace
                        verification:(RadarEventVerification)verification
                          confidence:(RadarEventConfidence)confidence
                            duration:(float)duration
                            location:(CLLocation *)location {
    self = [super init];
    if (self) {
        __id = _id;
        _createdAt = createdAt;
        _actualCreatedAt = actualCreatedAt;
        _live = live;
        _type = type;
        _geofence = geofence;
        _place = place;
        _region = region;
        _alternatePlaces = alternatePlaces;
        _verifiedPlace = verifiedPlace;
        _verification = verification;
        _confidence = confidence;
        _duration = duration;
        _location = location;
    }
    return self;
}

#pragma mark - JSON coding

+ (NSArray<RadarEvent *> *_Nullable)eventsFromObject:(id _Nonnull)object {
    FROM_JSON_ARRAY_DEFAULT_IMP(object, RadarEvent);
}

- (instancetype _Nullable)initWithObject:(id)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *dict = (NSDictionary *)object;

    NSString *_id = [dict radar_stringForKey:@"_id"];
    NSDate *createdAt = [dict radar_dateForKey:@"createdAt"];
    NSDate *actualCreatedAt = [dict radar_dateForKey:@"actualCreatedAt"];

    BOOL live = [dict radar_boolForKey:@"live"];

    RadarGeofence *geofence = [[RadarGeofence alloc] initWithObject:dict[@"geofence"]];
    RadarPlace *place = [[RadarPlace alloc] initWithObject:dict[@"place"]];
    RadarRegion *region = [[RadarRegion alloc] initWithObject:dict[@"region"]];
    NSArray<RadarPlace *> *alternatePlaces = [RadarPlace placesFromObject:dict[@"alternatePlaces"]];
    RadarPlace *verifiedPlace = [[RadarPlace alloc] initWithObject:dict[@"verifiedPlace"]];

    NSNumber *durationNumber = [dict radar_numberForKey:@"duration"];
    float duration = durationNumber ? [durationNumber floatValue] : 0;

    // location
    RadarCoordinate *coordinate = [[RadarCoordinate alloc] initWithObject:dict[@"location"]];
    NSNumber *locationAccuracyNumber = [dict radar_numberForKey:@"locationAccuracy"];
    if (!coordinate || !locationAccuracyNumber) {
        return nil;
    }
    CLLocation *location = [[CLLocation alloc] initWithCoordinate:coordinate.coordinate
                                                         altitude:-1
                                               horizontalAccuracy:[locationAccuracyNumber floatValue]
                                                 verticalAccuracy:-1
                                                        timestamp:(createdAt ? createdAt : [NSDate date])];

    RadarEventType type = RadarEventTypeUnknown;
    id typeObj = dict[@"type"];
    if (typeObj && [typeObj isKindOfClass:[NSString class]]) {
        NSString *typeStr = (NSString *)typeObj;

        if ([typeStr isEqualToString:@"user.entered_geofence"]) {
            type = RadarEventTypeUserEnteredGeofence;
        } else if ([typeStr isEqualToString:@"user.exited_geofence"]) {
            type = RadarEventTypeUserExitedGeofence;
        } else if ([typeStr isEqualToString:@"user.entered_home"]) {
            type = RadarEventTypeUserEnteredHome;
        } else if ([typeStr isEqualToString:@"user.exited_home"]) {
            type = RadarEventTypeUserExitedHome;
        } else if ([typeStr isEqualToString:@"user.entered_office"]) {
            type = RadarEventTypeUserEnteredOffice;
        } else if ([typeStr isEqualToString:@"user.exited_office"]) {
            type = RadarEventTypeUserExitedOffice;
        } else if ([typeStr isEqualToString:@"user.started_traveling"]) {
            type = RadarEventTypeUserStartedTraveling;
        } else if ([typeStr isEqualToString:@"user.stopped_traveling"]) {
            type = RadarEventTypeUserStoppedTraveling;
        } else if ([typeStr isEqualToString:@"user.started_commuting"]) {
            type = RadarEventTypeUserStartedCommuting;
        } else if ([typeStr isEqualToString:@"user.stopped_commuting"]) {
            type = RadarEventTypeUserStoppedCommuting;
        } else if ([typeStr isEqualToString:@"user.entered_place"]) {
            type = RadarEventTypeUserEnteredPlace;
        } else if ([typeStr isEqualToString:@"user.exited_place"]) {
            type = RadarEventTypeUserExitedPlace;
        } else if ([typeStr isEqualToString:@"user.nearby_place_chain"]) {
            type = RadarEventTypeUserNearbyPlaceChain;
        } else if ([typeStr isEqualToString:@"user.entered_region_country"]) {
            type = RadarEventTypeUserEnteredRegionCountry;
        } else if ([typeStr isEqualToString:@"user.exited_region_country"]) {
            type = RadarEventTypeUserExitedRegionCountry;
        } else if ([typeStr isEqualToString:@"user.entered_region_state"]) {
            type = RadarEventTypeUserEnteredRegionState;
        } else if ([typeStr isEqualToString:@"user.exited_region_state"]) {
            type = RadarEventTypeUserExitedRegionState;
        } else if ([typeStr isEqualToString:@"user.entered_region_dma"]) {
            type = RadarEventTypeUserEnteredRegionDMA;
        } else if ([typeStr isEqualToString:@"user.exited_region_dma"]) {
            type = RadarEventTypeUserExitedRegionDMA;
        }
    }

    RadarEventVerification verification = RadarEventVerificationUnverify;
    id verificationObj = dict[@"verification"];
    if (verificationObj && [verificationObj isKindOfClass:[NSNumber class]]) {
        NSNumber *verificationNumber = (NSNumber *)verificationObj;
        int verificationInt = [verificationNumber intValue];

        if (verificationInt == 1) {
            verification = RadarEventVerificationAccept;
        } else if (verificationInt == -1) {
            verification = RadarEventVerificationReject;
        } else if (verificationInt == 0) {
            verification = RadarEventVerificationUnverify;
        }
    }

    RadarEventConfidence confidence = RadarEventConfidenceNone;
    id confidenceObj = dict[@"confidence"];
    if (confidenceObj && [confidenceObj isKindOfClass:[NSNumber class]]) {
        NSNumber *confidenceNumber = (NSNumber *)confidenceObj;
        int confidenceInt = [confidenceNumber intValue];

        if (confidenceInt == 3) {
            confidence = RadarEventConfidenceHigh;
        } else if (confidenceInt == 2) {
            confidence = RadarEventConfidenceMedium;
        } else if (confidenceInt == 1) {
            confidence = RadarEventConfidenceLow;
        }
    }

    if (_id && createdAt) {
        return [[RadarEvent alloc] initWithId:_id
                                    createdAt:createdAt
                              actualCreatedAt:actualCreatedAt
                                         live:live
                                         type:type
                                     geofence:geofence
                                        place:place
                                       region:region
                              alternatePlaces:alternatePlaces
                                verifiedPlace:verifiedPlace
                                 verification:verification
                                   confidence:confidence
                                     duration:duration
                                     location:location];
    }

    return nil;
}

+ (NSString *)stringForType:(RadarEventType)type {
    switch (type) {
    case RadarEventTypeUserEnteredGeofence:
        return @"user.entered_geofence";
    case RadarEventTypeUserExitedGeofence:
        return @"user.exited_geofence";
    case RadarEventTypeUserEnteredHome:
        return @"user.entered_home";
    case RadarEventTypeUserExitedHome:
        return @"user.exited_home";
    case RadarEventTypeUserEnteredOffice:
        return @"user.entered_office";
    case RadarEventTypeUserExitedOffice:
        return @"user.exited_office";
    case RadarEventTypeUserStartedTraveling:
        return @"user.started_traveling";
    case RadarEventTypeUserStoppedTraveling:
        return @"user.stopped_traveling";
    case RadarEventTypeUserEnteredPlace:
        return @"user.entered_place";
    case RadarEventTypeUserExitedPlace:
        return @"user.exited_place";
    case RadarEventTypeUserNearbyPlaceChain:
        return @"user.nearby_place_chain";
    case RadarEventTypeUserEnteredRegionCountry:
        return @"user.entered_region_country";
    case RadarEventTypeUserExitedRegionCountry:
        return @"user.exited_region_country";
    case RadarEventTypeUserEnteredRegionState:
        return @"user.entered_region_state";
    case RadarEventTypeUserExitedRegionState:
        return @"user.exited_region_state";
    case RadarEventTypeUserEnteredRegionDMA:
        return @"user.entered_region_dma";
    case RadarEventTypeUserExitedRegionDMA:
        return @"user.exited_region_country";
    case RadarEventTypeUserStartedCommuting:
        return @"user.started_commuting";
    case RadarEventTypeUserStoppedCommuting:
        return @"user.stopped_commuting";
    default:
        return @"unknown";
    }
}

+ (NSArray<NSDictionary *> *)arrayForEvents:(NSArray<RadarEvent *> *)events {
    if (!events) {
        return nil;
    }

    NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:events.count];
    for (RadarEvent *event in events) {
        NSDictionary *dict = [event dictionaryValue];
        [arr addObject:dict];
    }
    return arr;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setValue:self._id forKey:@"_id"];
    [dict setValue:@(self.live) forKey:@"live"];
    NSString *type = [RadarEvent stringForType:self.type];
    if (type) {
        [dict setValue:type forKey:@"type"];
    }
    if (self.geofence) {
        NSDictionary *geofenceDict = [self.geofence dictionaryValue];
        if (geofenceDict) {
            [dict setValue:geofenceDict forKey:@"geofence"];
        }
    }
    if (self.place) {
        NSDictionary *placeDict = [self.place dictionaryValue];
        if (placeDict) {
            [dict setValue:placeDict forKey:@"place"];
        }
    }
    NSNumber *confidence = @(self.confidence);
    [dict setValue:confidence forKey:@"confidence"];
    if (self.duration) {
        [dict setValue:@(self.duration) forKey:@"duration"];
    }
    NSArray *alternatePlaces = [RadarPlace arrayForPlaces:self.alternatePlaces];
    if (alternatePlaces) {
        [dict setValue:alternatePlaces forKey:@"alternatePlaces"];
    }
    if (self.region) {
        NSDictionary *regionDict = [self.region dictionaryValue];
        [dict setValue:regionDict forKey:@"region"];
    }
    NSMutableDictionary *locationDict = [NSMutableDictionary new];
    locationDict[@"type"] = @"Point";
    NSArray *coordinates = @[@(self.location.coordinate.longitude), @(self.location.coordinate.latitude)];
    locationDict[@"coordinates"] = coordinates;
    [dict setValue:locationDict forKey:@"location"];
    return dict;
}

@end
