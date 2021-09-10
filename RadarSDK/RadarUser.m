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
#import "RadarGeofence+Internal.h"
#import "RadarPlace+Internal.h"
#import "RadarRegion+Internal.h"
#import "RadarSegment+Internal.h"
#import "RadarTrip+Internal.h"
#import "RadarUser+Internal.h"
#import "RadarUserInsights+Internal.h"

@implementation RadarUser

- (instancetype _Nullable)initWithId:(NSString *)_id
                              userId:(NSString *)userId
                            deviceId:(NSString *)deviceId
                         description:(NSString *)description
                            metadata:(NSDictionary *)metadata
                            location:(CLLocation *)location
                           geofences:(NSArray *)geofences
                               place:(RadarPlace *)place
                            insights:(RadarUserInsights *)insights
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
                               proxy:(BOOL)proxy
                                trip:(RadarTrip *_Nullable)trip {
    self = [super init];
    if (self) {
        __id = _id;
        _userId = userId;
        _deviceId = deviceId;
        ___description = description;
        _metadata = metadata;
        _location = location;
        _geofences = geofences;
        _place = place;
        _insights = insights;
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
        _proxy = proxy;
        _trip = trip;
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
    NSArray<RadarGeofence *> *geofences;
    RadarPlace *place;
    RadarUserInsights *insights;
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
    BOOL proxy = false;
    RadarTrip *trip;

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

    id geofencesObj = dict[@"geofences"];
    if (geofencesObj && [geofencesObj isKindOfClass:[NSArray class]]) {
        geofences = [RadarGeofence geofencesFromObject:geofencesObj];
    }

    id placeObj = dict[@"place"];
    place = [[RadarPlace alloc] initWithObject:placeObj];

    id insightsObj = dict[@"insights"];
    if (insightsObj && [insightsObj isKindOfClass:[NSDictionary class]]) {
        insights = [[RadarUserInsights alloc] initWithObject:insightsObj];
    }

    id beaconsObj = dict[@"beacons"];
    if (beaconsObj && [beaconsObj isKindOfClass:[NSArray class]]) {
        beacons = [RadarBeacon beaconsFromObject:beaconsObj];
    }

    id stoppedObj = dict[@"stopped"];
    if (stoppedObj && [stoppedObj isKindOfClass:[NSNumber class]]) {
        NSNumber *stoppedNumber = (NSNumber *)stoppedObj;

        stopped = [stoppedNumber boolValue];
    }

    id foregroundObj = dict[@"foreground"];
    if (foregroundObj && [foregroundObj isKindOfClass:[NSNumber class]]) {
        NSNumber *foregroundNumber = (NSNumber *)foregroundObj;

        foreground = [foregroundNumber boolValue];
    }

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

    id fraudObj = dict[@"fraud"];
    if (fraudObj && [fraudObj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *fraudDict = (NSDictionary *)fraudObj;

        id proxyObj = fraudDict[@"proxy"];
        if (proxyObj && [proxyObj isKindOfClass:[NSNumber class]]) {
            NSNumber *proxyNumber = (NSNumber *)proxyObj;

            proxy = [proxyNumber boolValue];
        }
    }

    id tripObj = dict[@"trip"];
    trip = [[RadarTrip alloc] initWithObject:tripObj];

    if (_id && location) {
        return [[RadarUser alloc] initWithId:_id
                                      userId:userId
                                    deviceId:deviceId
                                 description:description
                                    metadata:metadata
                                    location:location
                                   geofences:geofences
                                       place:place
                                    insights:insights
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
                                       proxy:proxy
                                        trip:trip];
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
    NSArray *geofencesArr = [RadarGeofence arrayForGeofences:self.geofences];
    [dict setValue:geofencesArr forKey:@"geofences"];
    if (self.place) {
        NSDictionary *placeDict = [self.place dictionaryValue];
        [dict setValue:placeDict forKey:@"place"];
    }
    if (self.insights) {
        NSDictionary *insightsDict = [self.insights dictionaryValue];
        [dict setValue:insightsDict forKey:@"insights"];
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
    NSDictionary *fraudDict = @{@"proxy": @(self.proxy)};
    [dict setValue:fraudDict forKey:@"fraud"];
    if (self.trip) {
        [dict setValue:[self.trip dictionaryValue] forKey:@"trip"];
    }
    return dict;
}

@end
