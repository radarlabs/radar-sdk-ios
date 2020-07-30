//
//  RadarUser.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarUser.h"
#import "Radar.h"
#import "RadarChain+Internal.h"
#import "RadarCollectionAdditions.h"
#import "RadarCoordinate+Internal.h"
#import "RadarGeofence+Internal.h"
#import "RadarPlace+Internal.h"
#import "RadarRegion+Internal.h"
#import "RadarSegment+Internal.h"
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
                               proxy:(BOOL)proxy {
    self = [super init];
    if (self) {
        __id = _id;
        _userId = userId;
        _deviceId = deviceId;
        __description = description;
        _metadata = metadata;
        _location = location;
        _geofences = geofences;
        _place = place;
        _insights = insights;
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
    }
    return self;
}

- (instancetype _Nullable)initWithObject:(NSObject *)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *dict = (NSDictionary *)object;

    NSString *_id = [dict radar_stringForKey:@"_id"];
    NSString *userId = [dict radar_stringForKey:@"userId"];
    NSString *deviceId = [dict radar_stringForKey:@"deviceId"];
    NSString *description = [dict radar_stringForKey:@"description"];
    NSDictionary *metadata = [dict radar_dictionaryForKey:@"metadata"];

    NSArray<RadarGeofence *> *geofences = [RadarGeofence geofencesFromObject:dict[@"geofences"]];

    RadarPlace *place = [[RadarPlace alloc] initWithObject:dict[@"place"]];
    RadarUserInsights *insights = [[RadarUserInsights alloc] initWithObject:dict[@"insights"]];

    NSNumber *stoppedNumber = [dict radar_numberForKey:@"stopped"];
    BOOL stopped = stoppedNumber ? [stoppedNumber boolValue] : NO;

    NSNumber *foregroundNumber = [dict radar_numberForKey:@"foreground"];
    BOOL foreground = foregroundNumber ? [foregroundNumber boolValue] : NO;

    RadarRegion *country = [[RadarRegion alloc] initWithObject:dict[@"country"]];
    RadarRegion *state = [[RadarRegion alloc] initWithObject:dict[@"state"]];
    RadarRegion *dma = [[RadarRegion alloc] initWithObject:dict[@"dma"]];
    RadarRegion *postalCode = [[RadarRegion alloc] initWithObject:dict[@"postalCode"]];

    NSArray<RadarChain *> *nearbyPlaceChains = [RadarChain chainsFromObject:dict[@"nearbyPlaceChains"]];
    NSArray<RadarSegment *> *segments = [RadarSegment segmentsFromObject:dict[@"segments"]];
    NSArray<RadarChain *> *topChains = [RadarChain chainsFromObject:dict[@"topChains"]];

    NSDictionary *fraudDict = [dict radar_dictionaryForKey:@"fraud"];
    NSNumber *proxyNumber = [fraudDict radar_numberForKey:@"proxy"];
    BOOL proxy = proxyNumber ? [proxyNumber boolValue] : NO;

    RadarCoordinate *coordinate = [[RadarCoordinate alloc] initWithObject:dict[@"location"]];
    NSNumber *locationAccuracyNumber = [dict radar_numberForKey:@"locationAccuracy"];
    if (!coordinate || !locationAccuracyNumber) {
        return nil;
    }

    CLLocation *location = [[CLLocation alloc] initWithCoordinate:coordinate.coordinate
                                                         altitude:-1
                                               horizontalAccuracy:[locationAccuracyNumber floatValue]
                                                 verticalAccuracy:-1
                                                        timestamp:[NSDate date]];

    NSString *sourceStr = [dict radar_stringForKey:@"source"];
    RadarLocationSource source = RadarLocationSourceUnknown;
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
                                       proxy:proxy];
    }

    return nil;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setValue:self._id forKey:@"_id"];
    [dict setValue:self.userId forKey:@"userId"];
    [dict setValue:self.deviceId forKey:@"deviceId"];
    [dict setValue:self._description forKey:@"description"];
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
    [dict setValue:[Radar stringForSource:self.source] forKey:@"source"];
    NSDictionary *fraudDict = @{@"proxy": @(self.proxy)};
    [dict setValue:fraudDict forKey:@"fraud"];
    return dict;
}

@end
