//
//  RadarEvent.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarEvent.h"
#import "RadarEvent+Internal.h"
#import "RadarGeofence+Internal.h"
#import "RadarPlace+Internal.h"
#import "RadarRegion+Internal.h"

@implementation RadarEvent

+ (NSArray<RadarEvent *> * _Nullable)eventsFromObject:(id _Nonnull)object {
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

- (instancetype _Nullable)initWithId:(NSString *)_id createdAt:(NSDate *)createdAt actualCreatedAt:(NSDate *)actualCreatedAt live:(BOOL)live type:(RadarEventType)type geofence:(RadarGeofence *)geofence place:(RadarPlace *)place region:(RadarRegion *)region alternatePlaces:(NSArray<RadarPlace *> *)alternatePlaces verifiedPlace:(RadarPlace *)verifiedPlace verification:(RadarEventVerification)verification confidence:(RadarEventConfidence)confidence duration:(float)duration location:(CLLocation *)location {
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

- (instancetype _Nullable)initWithObject:(id)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    NSDictionary *eventDict = (NSDictionary *)object;
    
    NSString *eventId;
    NSDate *eventCreatedAt;
    NSDate *eventActualCreatedAt;
    BOOL eventLive = NO;
    RadarEventType eventType = RadarEventTypeUnknown;
    RadarGeofence *eventGeofence;
    RadarPlace *eventPlace;
    RadarRegion *eventRegion;
    NSArray <RadarPlace *> *eventAlternatePlaces;
    RadarPlace *eventVerifiedPlace;
    RadarEventVerification eventVerification = RadarEventVerificationUnverify;
    RadarEventConfidence eventConfidence = RadarEventConfidenceNone;
    float eventDuration = 0;
    CLLocation *eventLocation;
    
    id eventIdObj = eventDict[@"_id"];
    if (eventIdObj && [eventIdObj isKindOfClass:[NSString class]]) {
        eventId = (NSString *)eventIdObj;
    }
    
    id eventCreatedAtObj = eventDict[@"createdAt"];
    if (eventCreatedAtObj && [eventCreatedAtObj isKindOfClass:[NSString class]]) {
        NSString *eventCreatedAtStr = (NSString *)eventCreatedAtObj;
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
        
        eventCreatedAt = [dateFormatter dateFromString:eventCreatedAtStr];
    }
    
    id eventActualCreatedAtObj = eventDict[@"actualCreatedAt"];
    if ([eventActualCreatedAtObj isKindOfClass:[NSString class]]) {
        NSString *eventActualCreatedAtStr = (NSString *)eventActualCreatedAtObj;
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
        
        eventActualCreatedAt = [dateFormatter dateFromString:eventActualCreatedAtStr];
    }
    
    id eventTypeObj = eventDict[@"type"];
    if (eventTypeObj && [eventTypeObj isKindOfClass:[NSString class]]) {
        NSString *eventTypeStr = (NSString *)eventTypeObj;
        
        if ([eventTypeStr isEqualToString:@"user.entered_geofence"]) {
            eventType = RadarEventTypeUserEnteredGeofence;
        } else if ([eventTypeStr isEqualToString:@"user.exited_geofence"]) {
            eventType = RadarEventTypeUserExitedGeofence;
        } else if ([eventTypeStr isEqualToString:@"user.entered_home"]) {
            eventType = RadarEventTypeUserEnteredHome;
        } else if ([eventTypeStr isEqualToString:@"user.exited_home"]) {
            eventType = RadarEventTypeUserExitedHome;
        } else if ([eventTypeStr isEqualToString:@"user.entered_office"]) {
            eventType = RadarEventTypeUserEnteredOffice;
        } else if ([eventTypeStr isEqualToString:@"user.exited_office"]) {
            eventType = RadarEventTypeUserExitedOffice;
        } else if ([eventTypeStr isEqualToString:@"user.started_traveling"]) {
            eventType = RadarEventTypeUserStartedTraveling;
        } else if ([eventTypeStr isEqualToString:@"user.stopped_traveling"]) {
            eventType = RadarEventTypeUserStoppedTraveling;
        } else if ([eventTypeStr isEqualToString:@"user.started_commuting"]) {
            eventType = RadarEventTypeUserStartedCommuting;
        } else if ([eventTypeStr isEqualToString:@"user.stopped_commuting"]) {
            eventType = RadarEventTypeUserStoppedCommuting;
        } else if ([eventTypeStr isEqualToString:@"user.entered_place"]) {
            eventType = RadarEventTypeUserEnteredPlace;
        } else if ([eventTypeStr isEqualToString:@"user.exited_place"]) {
            eventType = RadarEventTypeUserExitedPlace;
        } else if ([eventTypeStr isEqualToString:@"user.nearby_place_chain"]) {
            eventType = RadarEventTypeUserNearbyPlaceChain;
        } else if ([eventTypeStr isEqualToString:@"user.entered_region_country"]) {
            eventType = RadarEventTypeUserEnteredRegionCountry;
        } else if ([eventTypeStr isEqualToString:@"user.exited_region_country"]) {
            eventType = RadarEventTypeUserExitedRegionCountry;
        } else if ([eventTypeStr isEqualToString:@"user.entered_region_state"]) {
            eventType = RadarEventTypeUserEnteredRegionState;
        } else if ([eventTypeStr isEqualToString:@"user.exited_region_state"]) {
            eventType = RadarEventTypeUserExitedRegionState;
        } else if ([eventTypeStr isEqualToString:@"user.entered_region_dma"]) {
            eventType = RadarEventTypeUserEnteredRegionDMA;
        } else if ([eventTypeStr isEqualToString:@"user.exited_region_dma"]) {
            eventType = RadarEventTypeUserExitedRegionDMA;
        }
    }
    
    id eventLiveObj = eventDict[@"live"];
    if (eventLiveObj && [eventLiveObj isKindOfClass:[NSNumber class]]) {
        NSNumber *eventLiveNumber = (NSNumber *)eventLiveObj;
        
        eventLive = [eventLiveNumber boolValue];
    }
    
    id eventVerificationObj = eventDict[@"verification"];
    if (eventVerificationObj && [eventVerificationObj isKindOfClass:[NSNumber class]]) {
        NSNumber *eventVerificationNumber = (NSNumber *)eventVerificationObj;
        int eventVerificationInt = [eventVerificationNumber intValue];
        
        if (eventVerificationInt == 1) {
            eventVerification = RadarEventVerificationAccept;
        } else if (eventVerificationInt == -1) {
            eventVerification = RadarEventVerificationReject;
        } else if (eventVerificationInt == 0) {
            eventVerification = RadarEventVerificationUnverify;
        }
    }
    
    id eventConfidenceObj = eventDict[@"confidence"];
    if (eventConfidenceObj && [eventConfidenceObj isKindOfClass:[NSNumber class]]) {
        NSNumber *eventConfidenceNumber = (NSNumber *)eventConfidenceObj;
        int eventConfidenceInt = [eventConfidenceNumber intValue];
        
        if (eventConfidenceInt == 3) {
            eventConfidence = RadarEventConfidenceHigh;
        } else if (eventConfidenceInt == 2) {
            eventConfidence = RadarEventConfidenceMedium;
        } else if (eventConfidenceInt == 1) {
            eventConfidence = RadarEventConfidenceLow;
        }
    }
    
    id eventDurationObj = eventDict[@"duration"];
    if (eventDurationObj && [eventDurationObj isKindOfClass:[NSNumber class]]) {
        NSNumber *eventDurationNumber = (NSNumber *)eventDurationObj;
        
        eventDuration = [eventDurationNumber floatValue];
    }
    
    id eventGeofenceObj = eventDict[@"geofence"];
    eventGeofence = [[RadarGeofence alloc] initWithObject:eventGeofenceObj];
    
    id eventPlaceObj = eventDict[@"place"];
    eventPlace = [[RadarPlace alloc] initWithObject:eventPlaceObj];
    
    id eventRegionObj = eventDict[@"region"];
    eventRegion = [[RadarRegion alloc] initWithObject:eventRegionObj];
    
    id eventAlternatePlacesObj = eventDict[@"alternatePlaces"];
    if (eventAlternatePlacesObj && [eventAlternatePlacesObj isKindOfClass:[NSArray class]]) {
        NSMutableArray<RadarPlace *> *mutableEventAlternatePlaces = [NSMutableArray<RadarPlace *> new];
        
        NSArray *eventAlternatePlacesArr = (NSArray *)eventAlternatePlacesObj;
        for (id eventAlternatePlaceObj in eventAlternatePlacesArr) {
            RadarPlace *eventAlternatePlace = [[RadarPlace alloc] initWithObject:eventAlternatePlaceObj];
            if (!eventAlternatePlace) {
                return nil;
            }
            
            [mutableEventAlternatePlaces addObject:eventAlternatePlace];
        }
        
        eventAlternatePlaces = mutableEventAlternatePlaces;
    }
    
    id eventVerifiedPlaceObj = eventDict[@"verifiedPlace"];
    eventVerifiedPlace = [[RadarPlace alloc] initWithObject:eventVerifiedPlaceObj];
    
    id eventLocationObj = eventDict[@"location"];
    if (eventLocationObj && [eventLocationObj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *eventLocationDict = (NSDictionary *)eventLocationObj;
        
        id eventLocationCoordinatesObj = eventLocationDict[@"coordinates"];
        if (!eventLocationCoordinatesObj || ![eventLocationCoordinatesObj isKindOfClass:[NSArray class]]) {
            return nil;
        }
        
        NSArray *eventLocationCoordinatesArr = (NSArray *)eventLocationCoordinatesObj;
        if (eventLocationCoordinatesArr.count != 2) {
            return nil;
        }
        
        id eventLocationCoordinatesLongitudeObj = eventLocationCoordinatesArr[0];
        id eventLocationCoordinatesLatitudeObj = eventLocationCoordinatesArr[1];
        if (!eventLocationCoordinatesLongitudeObj || !eventLocationCoordinatesLatitudeObj || ![eventLocationCoordinatesLongitudeObj isKindOfClass:[NSNumber class]] || ![eventLocationCoordinatesLatitudeObj isKindOfClass:[NSNumber class]]) {
            return nil;
        }
        
        NSNumber *eventLocationCoordinatesLongitudeNumber = (NSNumber *)eventLocationCoordinatesLongitudeObj;
        NSNumber *eventLocationCoordinatesLatitudeNumber = (NSNumber *)eventLocationCoordinatesLatitudeObj;
        
        float eventLocationCoordinatesLongitudeFloat = [eventLocationCoordinatesLongitudeNumber floatValue];
        float eventLocationCoordinatesLatitudeFloat = [eventLocationCoordinatesLatitudeNumber floatValue];
        
        id eventLocationAccuracyObj = eventDict[@"locationAccuracy"];
        if (eventLocationAccuracyObj && [eventLocationAccuracyObj isKindOfClass:[NSNumber class]]) {
            NSNumber *eventLocationAccuracyNumber = (NSNumber *)eventLocationAccuracyObj;
            
            eventLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(eventLocationCoordinatesLatitudeFloat, eventLocationCoordinatesLongitudeFloat) altitude:-1 horizontalAccuracy:[eventLocationAccuracyNumber floatValue] verticalAccuracy:-1 timestamp:(eventCreatedAt ? eventCreatedAt : [NSDate date])];
        }
    }
    
    
    if (eventId && eventCreatedAt) {
        return [[RadarEvent alloc] initWithId:eventId createdAt:eventCreatedAt actualCreatedAt:eventActualCreatedAt live:eventLive type:eventType geofence:eventGeofence place:eventPlace region:eventRegion alternatePlaces:eventAlternatePlaces verifiedPlace:eventVerifiedPlace verification:eventVerification confidence:eventConfidence duration:eventDuration location:eventLocation];
    }
    
    return nil;
}

@end
