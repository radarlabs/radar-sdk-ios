//
//  RadarContext.m
//  RadarSDK
//
//  Created by Cory Pisano on 1/30/20.
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "RadarContext.h"
#import "RadarContext+Internal.h"
#import "RadarGeofence+Internal.h"
#import "RadarPlace+Internal.h"
#import "RadarRegion+Internal.h"

@implementation RadarContext

- (instancetype _Nullable)initWithGeofences:(NSArray * _Nonnull)geofences
                                      place:(RadarPlace * _Nullable)place
                                    country:(RadarRegion * _Nullable)country
                                      state:(RadarRegion * _Nullable)state
                                        dma:(RadarRegion * _Nullable)dma
                                 postalCode:(RadarRegion * _Nullable)postalCode {
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
    
    NSArray <RadarGeofence *> *contextGeofences = @[];
    RadarPlace *contextPlace;
    RadarRegion *country;
    RadarRegion *state;
    RadarRegion *dma;
    RadarRegion *postalCode;
    
    id contextGeofencesObj = contextDict[@"geofences"];
    if (contextGeofencesObj && [contextGeofencesObj isKindOfClass:[NSArray class]]) {
        NSMutableArray<RadarGeofence *> *mutableContextGeofences = [NSMutableArray<RadarGeofence *> new];
        
        NSArray *contextGeofencesArr = (NSArray *)contextGeofencesObj;
        for (id contextGeofenceObj in contextGeofencesArr) {
            RadarGeofence *contextGeofence = [[RadarGeofence alloc] initWithObject:contextGeofenceObj];
            if (!contextGeofence) {
                return nil;
            }
            
            [mutableContextGeofences addObject:contextGeofence];
        }
        
        contextGeofences = mutableContextGeofences;
    }
    
    id contextPlaceObj = contextDict[@"place"];
    contextPlace = [[RadarPlace alloc] initWithObject:contextPlaceObj];
    
    id countryObj = contextDict[@"country"];
    country = [[RadarRegion alloc] initWithObject:countryObj];

    id stateObj = contextDict[@"state"];
    state = [[RadarRegion alloc] initWithObject:stateObj];
    
    id dmaObj = contextDict[@"dma"];
    dma = [[RadarRegion alloc] initWithObject:dmaObj];
    
    id postalCodeObj = contextDict[@"postalCode"];
    postalCode = [[RadarRegion alloc] initWithObject:postalCodeObj];
    
    return [[RadarContext alloc] initWithGeofences:contextGeofences place:contextPlace country:country state:state dma:dma postalCode:postalCode];

}

@end
