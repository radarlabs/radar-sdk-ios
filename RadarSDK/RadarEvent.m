//
//  RadarEvent.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarEvent.h"
#import "RadarBeacon+Internal.h"
#import "RadarEvent+Internal.h"
#import "RadarGeofence+Internal.h"
#import "RadarPlace+Internal.h"
#import "RadarRegion+Internal.h"
#import "RadarTrip+Internal.h"

@implementation RadarEvent

+ (NSArray<RadarEvent *> *_Nullable)eventsFromObject:(id _Nonnull)object {
    if (!object || ![object isKindOfClass:[NSArray class]]) {
        return nil;
    }

    NSArray *eventsArr = (NSArray *)object;

    NSMutableArray<RadarEvent *> *mutableEvents = [NSMutableArray<RadarEvent *> new];

    for (id eventObj in eventsArr) {
        RadarEvent *event = [[RadarEvent alloc] initWithObject:eventObj];

        if (!event) {
            return nil;
        }

        [mutableEvents addObject:event];
    }

    return mutableEvents;
}

- (instancetype _Nullable)initWithId:(NSString *)_id
                           createdAt:(NSDate *)createdAt
                     actualCreatedAt:(NSDate *)actualCreatedAt
                                live:(BOOL)live
                                type:(RadarEventType)type
                            geofence:(RadarGeofence *)geofence
                               place:(RadarPlace *)place
                              region:(RadarRegion *)region
                              beacon:(RadarBeacon *)beacon
                                trip:(RadarTrip *)trip
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
        _beacon = beacon;
        _trip = trip;
        _alternatePlaces = alternatePlaces;
        _verifiedPlace = verifiedPlace;
        _verification = verification;
        _confidence = confidence;
        _duration = duration;
        _location = location;
    }
    return self;
}

- (instancetype _Nullable)initWithObject:(id)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *dict = (NSDictionary *)object;

    NSString *_id;
    NSDate *createdAt;
    NSDate *actualCreatedAt;
    BOOL live = NO;
    RadarEventType type = RadarEventTypeUnknown;
    RadarGeofence *geofence;
    RadarPlace *place;
    RadarRegion *region;
    RadarBeacon *beacon;
    RadarTrip *trip;
    NSArray<RadarPlace *> *alternatePlaces;
    RadarPlace *verifiedPlace;
    RadarEventVerification verification = RadarEventVerificationUnverify;
    RadarEventConfidence confidence = RadarEventConfidenceNone;
    float duration = 0;
    CLLocation *location;

    id idObj = dict[@"_id"];
    if (idObj && [idObj isKindOfClass:[NSString class]]) {
        _id = (NSString *)idObj;
    }

    id createdAtObj = dict[@"createdAt"];
    if (createdAtObj && [createdAtObj isKindOfClass:[NSString class]]) {
        NSString *createdAtStr = (NSString *)createdAtObj;

        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];

        createdAt = [dateFormatter dateFromString:createdAtStr];
    }

    id actualCreatedAtObj = dict[@"actualCreatedAt"];
    if ([actualCreatedAtObj isKindOfClass:[NSString class]]) {
        NSString *actualCreatedAtStr = (NSString *)actualCreatedAtObj;

        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];

        actualCreatedAt = [dateFormatter dateFromString:actualCreatedAtStr];
    }

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
        } else if ([typeStr isEqualToString:@"user.started_trip"]) {
            type = RadarEventTypeUserStartedTrip;
        } else if ([typeStr isEqualToString:@"user.updated_trip"]) {
            type = RadarEventTypeUserUpdatedTrip;
        } else if ([typeStr isEqualToString:@"user.approaching_trip_destination"]) {
            type = RadarEventTypeUserApproachingTripDestination;
        } else if ([typeStr isEqualToString:@"user.arrived_at_trip_destination"]) {
            type = RadarEventTypeUserArrivedAtTripDestination;
        } else if ([typeStr isEqualToString:@"user.stopped_trip"]) {
            type = RadarEventTypeUserStoppedTrip;
        } else if ([typeStr isEqualToString:@"user.entered_beacon"]) {
            type = RadarEventTypeUserEnteredBeacon;
        } else if ([typeStr isEqualToString:@"user.exited_beacon"]) {
            type = RadarEventTypeUserExitedBeacon;
        }
    }

    id liveObj = dict[@"live"];
    if (liveObj && [liveObj isKindOfClass:[NSNumber class]]) {
        NSNumber *eventLiveNumber = (NSNumber *)liveObj;

        live = [eventLiveNumber boolValue];
    }

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

    id durationObj = dict[@"duration"];
    if (durationObj && [durationObj isKindOfClass:[NSNumber class]]) {
        NSNumber *durationNumber = (NSNumber *)durationObj;

        duration = [durationNumber floatValue];
    }

    id geofenceObj = dict[@"geofence"];
    geofence = [[RadarGeofence alloc] initWithObject:geofenceObj];

    id placeObj = dict[@"place"];
    place = [[RadarPlace alloc] initWithObject:placeObj];

    id regionObj = dict[@"region"];
    region = [[RadarRegion alloc] initWithObject:regionObj];

    id beaconObj = dict[@"beacon"];
    beacon = [[RadarBeacon alloc] initWithObject:beaconObj];

    id tripObj = dict[@"trip"];
    trip = [[RadarTrip alloc] initWithObject:tripObj];

    id alternatePlacesObj = dict[@"alternatePlaces"];
    if (alternatePlacesObj && [alternatePlacesObj isKindOfClass:[NSArray class]]) {
        NSMutableArray<RadarPlace *> *mutableAlternatePlaces = [NSMutableArray<RadarPlace *> new];

        NSArray *alternatePlacesArr = (NSArray *)alternatePlacesObj;
        for (id alternatePlaceObj in alternatePlacesArr) {
            RadarPlace *alternatePlace = [[RadarPlace alloc] initWithObject:alternatePlaceObj];
            if (!alternatePlace) {
                return nil;
            }

            [mutableAlternatePlaces addObject:alternatePlace];
        }

        alternatePlaces = mutableAlternatePlaces;
    }

    id verifiedPlaceObj = dict[@"verifiedPlace"];
    verifiedPlace = [[RadarPlace alloc] initWithObject:verifiedPlaceObj];

    id locationObj = dict[@"location"];
    if (locationObj && [locationObj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *locationDict = (NSDictionary *)locationObj;

        id locationCoordinatesObj = locationDict[@"coordinates"];
        if (!locationCoordinatesObj || ![locationCoordinatesObj isKindOfClass:[NSArray class]]) {
            return nil;
        }

        NSArray *locationCoordinatesArr = (NSArray *)locationCoordinatesObj;
        if (locationCoordinatesArr.count != 2) {
            return nil;
        }

        id locationCoordinatesLongitudeObj = locationCoordinatesArr[0];
        id locationCoordinatesLatitudeObj = locationCoordinatesArr[1];
        if (!locationCoordinatesLongitudeObj || !locationCoordinatesLatitudeObj || ![locationCoordinatesLongitudeObj isKindOfClass:[NSNumber class]] ||
            ![locationCoordinatesLatitudeObj isKindOfClass:[NSNumber class]]) {
            return nil;
        }

        NSNumber *locationCoordinatesLongitudeNumber = (NSNumber *)locationCoordinatesLongitudeObj;
        NSNumber *locationCoordinatesLatitudeNumber = (NSNumber *)locationCoordinatesLatitudeObj;

        float locationCoordinatesLongitudeFloat = [locationCoordinatesLongitudeNumber floatValue];
        float locationCoordinatesLatitudeFloat = [locationCoordinatesLatitudeNumber floatValue];

        id locationAccuracyObj = dict[@"locationAccuracy"];
        if (locationAccuracyObj && [locationAccuracyObj isKindOfClass:[NSNumber class]]) {
            NSNumber *locationAccuracyNumber = (NSNumber *)locationAccuracyObj;

            location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(locationCoordinatesLatitudeFloat, locationCoordinatesLongitudeFloat)
                                                     altitude:-1
                                           horizontalAccuracy:[locationAccuracyNumber floatValue]
                                             verticalAccuracy:-1
                                                    timestamp:(createdAt ? createdAt : [NSDate date])];
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
                                       beacon:beacon
                                         trip:trip
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
    case RadarEventTypeUserStartedTrip:
        return @"user.started_trip";
    case RadarEventTypeUserUpdatedTrip:
        return @"user.updated_trip";
    case RadarEventTypeUserApproachingTripDestination:
        return @"user.approaching_trip_destination";
    case RadarEventTypeUserArrivedAtTripDestination:
        return @"user.arrived_at_trip_destination";
    case RadarEventTypeUserStoppedTrip:
        return @"user.stopped_trip";
    case RadarEventTypeUserEnteredBeacon:
        return @"user.entered_beacon";
    case RadarEventTypeUserExitedBeacon:
        return @"user.exited_beacon";
    case RadarEventTypeUserEnteredRegionPostalCode:
        return @"user.entered_region_postal_code";
    case RadarEventTypeUserExitedRegionPostalCode:
        return @"user.exited_region_postal_code";
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
    if (self.region) {
        NSDictionary *regionDict = [self.region dictionaryValue];
        [dict setValue:regionDict forKey:@"region"];
    }
    if (self.beacon) {
        NSDictionary *beaconDict = [self.beacon dictionaryValue];
        [dict setValue:beaconDict forKey:@"beacon"];
    }
    if (self.trip) {
        NSDictionary *tripDict = [self.trip dictionaryValue];
        [dict setValue:tripDict forKey:@"trip"];
    }
    NSArray *alternatePlaces = [RadarPlace arrayForPlaces:self.alternatePlaces];
    if (alternatePlaces) {
        [dict setValue:alternatePlaces forKey:@"alternatePlaces"];
    }
    NSMutableDictionary *locationDict = [NSMutableDictionary new];
    locationDict[@"type"] = @"Point";
    NSArray *coordinates = @[@(self.location.coordinate.longitude), @(self.location.coordinate.latitude)];
    locationDict[@"coordinates"] = coordinates;
    [dict setValue:locationDict forKey:@"location"];
    return dict;
}

@end
