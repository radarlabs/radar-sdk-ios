//
//  RadarContext.m
//  RadarSDK
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "RadarContext.h"
#import "RadarContext+Internal.h"
#import "RadarGeofence+Internal.h"
#import "RadarPlace+Internal.h"
#import "RadarRegion+Internal.h"
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

@implementation RadarContext

- (instancetype _Nullable)initWithGeofences:(NSArray *_Nonnull)geofences
                                      place:(RadarPlace *_Nullable)place
                                    country:(RadarRegion *_Nullable)country
                                      state:(RadarRegion *_Nullable)state
                                        dma:(RadarRegion *_Nullable)dma
                                 postalCode:(RadarRegion *_Nullable)postalCode {
    self = [super init];
    if (self) {
        _geofences = geofences;
        _place = place;
        _country = country;
        _state = state;
        _dma = dma;
        _postalCode = postalCode;
    }
    return self;
}

- (instancetype _Nullable)initWithObject:(NSObject *)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *contextDict = (NSDictionary *)object;

    NSArray<RadarGeofence *> *contextGeofences = [RadarGeofence geofencesFromObject:contextDict[@"geofences"]];
    RadarPlace *contextPlace = [[RadarPlace alloc] initWithObject:contextDict[@"place"]];
    RadarRegion *country = [[RadarRegion alloc] initWithObject:contextDict[@"country"]];
    RadarRegion *state = [[RadarRegion alloc] initWithObject:contextDict[@"state"]];
    RadarRegion *dma = [[RadarRegion alloc] initWithObject:contextDict[@"dma"]];
    RadarRegion *postalCode = [[RadarRegion alloc] initWithObject:contextDict[@"postalCode"]];

    return [[RadarContext alloc] initWithGeofences:contextGeofences place:contextPlace country:country state:state dma:dma postalCode:postalCode];
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    NSArray *geofencesArr = [RadarGeofence arrayForGeofences:self.geofences];
    [dict setValue:geofencesArr forKey:@"geofences"];
    if (self.place) {
        NSDictionary *placeDict = [self.place dictionaryValue];
        [dict setValue:placeDict forKey:@"place"];
    }
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
    return dict;
}

@end
