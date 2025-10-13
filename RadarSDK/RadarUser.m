//
//  RadarUser.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarUser.h"
#import "Radar.h"
#import "RadarBeacon+Internal.h"
#import "RadarChain+Internal.h"
#import "RadarFraud+Internal.h"
#import "RadarGeofence+Internal.h"
#import "RadarPlace+Internal.h"
#import "RadarRegion+Internal.h"
#import "RadarSegment+Internal.h"
#import "RadarTrip+Internal.h"
#import "RadarUser+Internal.h"
#import "RadarLogger.h"

@implementation RadarUser

- (instancetype _Nullable)initWithId:(NSString *)_id
                              userId:(NSString *)userId
                            deviceId:(NSString *)deviceId
                         description:(NSString *)description
                            metadata:(NSDictionary *)metadata
                            location:(CLLocation *)location
                        activityType:(RadarActivityType)activityType
                           geofences:(NSArray *)geofences
                               place:(RadarPlace *)place
                             beacons:(NSArray *)beacons
                             stopped:(BOOL)stopped
                          foreground:(BOOL)foreground
                             country:(RadarRegion *_Nullable)country
                               state:(RadarRegion *_Nullable)state
                                 dma:(RadarRegion *_Nullable)dma
                          postalCode:(RadarRegion *_Nullable)postalCode
                   nearbyPlaceChains:(nullable NSArray<RadarChain *> *)nearbyPlaceChains
                            segments:(nullable NSArray<RadarSegment *> *)segments
                           topChains:(nullable NSArray<RadarChain *> *)topChains
                              source:(RadarLocationSource)source
                                trip:(RadarTrip *_Nullable)trip
                               debug:(BOOL)debug
                               fraud:(RadarFraud *_Nullable)fraud 
                            altitude:(double)altitude
               latestGeofencesDwelled:(nullable NSArray<RadarGeofence *> *)latestGeofencesDwelled {
    self = [super init];
    if (self) {
        __id = _id;
        _userId = userId;
        _deviceId = deviceId;
        ___description = description;
        _metadata = metadata;
        _location = location;
        _activityType = activityType;
        _geofences = geofences;
        _place = place;
        _beacons = beacons;
        _stopped = stopped;
        _foreground = foreground;
        _country = country;
        _state = state;
        _dma = dma;
        _postalCode = postalCode;
        _nearbyPlaceChains = nearbyPlaceChains;
        _segments = segments;
        _topChains = topChains;
        _source = source;
        _trip = trip;
        _debug = debug;
        _fraud = fraud;
        _altitude = altitude;
        _latestGeofencesDwelled = latestGeofencesDwelled;
    }
    return self;
}

- (instancetype _Nullable)initWithObject:(NSObject *)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *dict = (NSDictionary *)object;

    NSString *_id;
    NSString *userId;
    NSString *deviceId;
    NSString *description;
    NSDictionary *metadata;
    CLLocation *location;
    RadarActivityType activityType = RadarActivityTypeUnknown;
    NSArray<RadarGeofence *> *geofences;
    NSArray<RadarGeofence *> *latestGeofencesDwelled;
    RadarPlace *place;
    NSArray<RadarBeacon *> *beacons;
    BOOL stopped = NO;
    BOOL foreground = NO;
    RadarRegion *country;
    RadarRegion *state;
    RadarRegion *dma;
    RadarRegion *postalCode;
    NSArray<RadarChain *> *nearbyPlaceChains;
    NSArray<RadarSegment *> *segments;
    NSArray<RadarChain *> *topChains;
    RadarLocationSource source = RadarLocationSourceUnknown;
    RadarTrip *trip;
    RadarFraud *fraud;
    BOOL debug = NO;
    double altitude = NAN;

    id idObj = dict[@"_id"];
    if (idObj && [idObj isKindOfClass:[NSString class]]) {
        _id = (NSString *)idObj;
    }

    id userIdObj = dict[@"userId"];
    if (userIdObj && [userIdObj isKindOfClass:[NSString class]]) {
        userId = (NSString *)userIdObj;
    }

    id deviceIdObj = dict[@"deviceId"];
    if (deviceIdObj && [deviceIdObj isKindOfClass:[NSString class]]) {
        deviceId = (NSString *)deviceIdObj;
    }

    id descriptionObj = dict[@"description"];
    if (descriptionObj && [descriptionObj isKindOfClass:[NSString class]]) {
        description = (NSString *)descriptionObj;
    }

    id metadataObj = dict[@"metadata"];
    if (metadataObj && [metadataObj isKindOfClass:[NSDictionary class]]) {
        metadata = (NSDictionary *)metadataObj;
    }

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
                                                    timestamp:[NSDate date]];
        }
    }

    id activityTypeObj = dict[@"activityType"];
    if (activityTypeObj && [activityTypeObj isKindOfClass:[NSString class]]) {
        NSString *activityTypeStr = (NSString *)activityTypeObj;

        if ([activityTypeStr isEqualToString:@"unknown"]) {
            activityType = RadarActivityTypeUnknown;
        } else if ([activityTypeStr isEqualToString:@"car"]) {
            activityType = RadarActivityTypeCar;
        } else if ([activityTypeStr isEqualToString:@"bike"]) {
            activityType = RadarActivityTypeBike;
        } else if ([activityTypeStr isEqualToString:@"foot"]) {
            activityType = RadarActivityTypeFoot;
        } else if ([activityTypeStr isEqualToString:@"run"]) {
            activityType = RadarActivityTypeRun;
        } else if ([activityTypeStr isEqualToString:@"stationary"]) {
            activityType = RadarActivityTypeStationary;
        }
    }


    id geofencesObj = dict[@"geofences"];
    if (geofencesObj && [geofencesObj isKindOfClass:[NSArray class]]) {
        geofences = [RadarGeofence geofencesFromObject:geofencesObj];
    }

    id latestGeofencesDwelledObj = dict[@"latestGeofencesDwelled"];
    if (latestGeofencesDwelledObj && [latestGeofencesDwelledObj isKindOfClass:[NSArray class]]) {
        latestGeofencesDwelled = [RadarGeofence geofencesFromObject:latestGeofencesDwelledObj];
    }

    id placeObj = dict[@"place"];
    place = [[RadarPlace alloc] initWithObject:placeObj];

    id beaconsObj = dict[@"beacons"];
    if (beaconsObj && [beaconsObj isKindOfClass:[NSArray class]]) {
        beacons = [RadarBeacon beaconsFromObject:beaconsObj];
    }

    stopped = [self asBool:dict[@"stopped"]];
    foreground = [self asBool:dict[@"foreground"]];

    id countryObj = dict[@"country"];
    country = [[RadarRegion alloc] initWithObject:countryObj];

    id stateObj = dict[@"state"];
    state = [[RadarRegion alloc] initWithObject:stateObj];

    id dmaObj = dict[@"dma"];
    dma = [[RadarRegion alloc] initWithObject:dmaObj];

    id postalCodeObj = dict[@"postalCode"];
    postalCode = [[RadarRegion alloc] initWithObject:postalCodeObj];

    id userNearbyPlaceChainsObj = dict[@"nearbyPlaceChains"];
    if ([userNearbyPlaceChainsObj isKindOfClass:[NSArray class]]) {
        NSArray *nearbyChainsArr = (NSArray *)userNearbyPlaceChainsObj;

        NSMutableArray<RadarChain *> *mutableNearbyPlaceChains = [NSMutableArray<RadarChain *> new];
        for (id chainObj in nearbyChainsArr) {
            RadarChain *placeChain = [[RadarChain alloc] initWithObject:chainObj];
            if (placeChain) {
                [mutableNearbyPlaceChains addObject:placeChain];
            }
        }

        nearbyPlaceChains = mutableNearbyPlaceChains;
    }

    id segmentsObj = dict[@"segments"];
    if ([segmentsObj isKindOfClass:[NSArray class]]) {
        NSArray *segmentsArr = (NSArray *)segmentsObj;

        NSMutableArray<RadarSegment *> *mutableSegments = [NSMutableArray<RadarSegment *> new];
        for (id segmentObj in segmentsArr) {
            RadarSegment *segment = [[RadarSegment alloc] initWithObject:segmentObj];
            if (segment) {
                [mutableSegments addObject:segment];
            }
        }

        segments = mutableSegments;
    }

    id topChainsObj = dict[@"topChains"];
    if ([topChainsObj isKindOfClass:[NSArray class]]) {
        NSArray *topChainsArr = (NSArray *)topChainsObj;

        NSMutableArray<RadarChain *> *mutableTopChains = [NSMutableArray<RadarChain *> new];
        for (id chainObj in topChainsArr) {
            RadarChain *placeChain = [[RadarChain alloc] initWithObject:chainObj];
            if (placeChain) {
                [mutableTopChains addObject:placeChain];
            }
        }

        topChains = mutableTopChains;
    }

    id sourceObj = dict[@"source"];
    if (sourceObj && [sourceObj isKindOfClass:[NSString class]]) {
        NSString *sourceStr = (NSString *)sourceObj;

        if ([sourceStr isEqualToString:@"FOREGROUND_LOCATION"]) {
            source = RadarLocationSourceForegroundLocation;
        } else if ([sourceStr isEqualToString:@"BACKGROUND_LOCATION"]) {
            source = RadarLocationSourceBackgroundLocation;
        } else if ([sourceStr isEqualToString:@"MANUAL_LOCATION"]) {
            source = RadarLocationSourceManualLocation;
        } else if ([sourceStr isEqualToString:@"GEOFENCE_ENTER"]) {
            source = RadarLocationSourceGeofenceEnter;
        } else if ([sourceStr isEqualToString:@"GEOFENCE_EXIT"]) {
            source = RadarLocationSourceGeofenceExit;
        } else if ([sourceStr isEqualToString:@"VISIT_ARRIVAL"]) {
            source = RadarLocationSourceVisitArrival;
        } else if ([sourceStr isEqualToString:@"VISIT_DEPARTURE"]) {
            source = RadarLocationSourceVisitDeparture;
        } else if ([sourceStr isEqualToString:@"MOCK_LOCATION"]) {
            source = RadarLocationSourceMockLocation;
        }
    }

    id tripObj = dict[@"trip"];
    trip = [[RadarTrip alloc] initWithObject:tripObj];

    debug = [self asBool:dict[@"debug"]];

    id fraudObj = dict[@"fraud"];
    fraud = [[RadarFraud alloc] initWithObject:fraudObj];

    id barometricAltitudeObj = dict[@"barometricAltitude"];
    if (barometricAltitudeObj && [barometricAltitudeObj isKindOfClass:[NSNumber class]]) {
        altitude = [((NSNumber *)barometricAltitudeObj) doubleValue];
    }

    id altitudeObj = dict[@"altitude"];
    if (altitudeObj && [altitudeObj isKindOfClass:[NSNumber class]]) {
        altitude = [((NSNumber *)altitudeObj) doubleValue];
    }

    if (_id && location) {
        return [[RadarUser alloc] initWithId:_id
                                      userId:userId
                                    deviceId:deviceId
                                 description:description
                                    metadata:metadata
                                    location:location
                                activityType:activityType
                                   geofences:geofences
                                       place:place
                                     beacons:beacons
                                     stopped:stopped
                                  foreground:foreground
                                     country:country
                                       state:state
                                         dma:dma
                                  postalCode:postalCode
                           nearbyPlaceChains:nearbyPlaceChains
                                    segments:segments
                                   topChains:topChains
                                      source:source
                                        trip:trip
                                       debug:debug
                                       fraud:fraud
                                    altitude:altitude
                       latestGeofencesDwelled:latestGeofencesDwelled];
    }

    return nil;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setValue:self._id forKey:@"_id"];
    [dict setValue:self.userId forKey:@"userId"];
    [dict setValue:self.deviceId forKey:@"deviceId"];
    [dict setValue:self.__description forKey:@"description"];
    [dict setValue:self.metadata forKey:@"metadata"];
    NSMutableDictionary *locationDict = [NSMutableDictionary new];
    locationDict[@"type"] = @"Point";
    NSArray *coordinates = @[@(self.location.coordinate.longitude), @(self.location.coordinate.latitude)];
    locationDict[@"coordinates"] = coordinates;
    [dict setValue:locationDict forKey:@"location"];
    [dict setValue:[Radar stringForActivityType:self.activityType] forKey:@"activityType"];
    NSArray *geofencesArr = [RadarGeofence arrayForGeofences:self.geofences];
    [dict setValue:geofencesArr forKey:@"geofences"];
    NSArray *latestGeofencesDwelledArr = [RadarGeofence arrayForGeofences:self.latestGeofencesDwelled];
    [dict setValue:latestGeofencesDwelledArr forKey:@"latestGeofencesDwelled"];
    if (self.place) {
        NSDictionary *placeDict = [self.place dictionaryValue];
        [dict setValue:placeDict forKey:@"place"];
    }
    if (self.beacons) {
        NSArray *beaconsArr = [RadarBeacon arrayForBeacons:self.beacons];
        [dict setValue:beaconsArr forKey:@"beacons"];
    }
    [dict setValue:@(self.stopped) forKey:@"stopped"];
    [dict setValue:@(self.foreground) forKey:@"foreground"];
    if (self.country) {
        NSDictionary *countryDict = [self.country dictionaryValue];
        [dict setValue:countryDict forKey:@"country"];
    }
    if (self.state) {
        NSDictionary *stateDict = [self.state dictionaryValue];
        [dict setValue:stateDict forKey:@"state"];
    }
    if (self.dma) {
        NSDictionary *dmaDict = [self.dma dictionaryValue];
        [dict setValue:dmaDict forKey:@"dma"];
    }
    if (self.postalCode) {
        NSDictionary *postalCodeDict = [self.postalCode dictionaryValue];
        [dict setValue:postalCodeDict forKey:@"postalCode"];
    }
    NSArray *nearbyPlaceChains = [RadarChain arrayForChains:self.nearbyPlaceChains];
    [dict setValue:nearbyPlaceChains forKey:@"nearbyPlaceChains"];
    NSArray *segmentsArr = [RadarSegment arrayForSegments:self.segments];
    [dict setValue:segmentsArr forKey:@"segments"];
    NSArray *topChainsArr = [RadarChain arrayForChains:self.topChains];
    [dict setValue:topChainsArr forKey:@"topChains"];
    [dict setValue:[Radar stringForLocationSource:self.source] forKey:@"source"];
    if (self.trip) {
        [dict setValue:[self.trip dictionaryValue] forKey:@"trip"];
    }
    [dict setValue:@(self.debug) forKey:@"debug"];
    if (self.fraud) {
        [dict setValue:[self.fraud dictionaryValue] forKey:@"fraud"];
    }
    if (!isnan(self.altitude)) {
        [dict setValue:@(self.altitude) forKey:@"altitude"];
    }
    return dict;
}

- (BOOL)asBool:(NSObject *)object {
    if (object && [object isKindOfClass:[NSNumber class]]) {
        NSNumber *number = (NSNumber *)object;

        return [number boolValue];
    } else {
        return false;
    }
}

@end
