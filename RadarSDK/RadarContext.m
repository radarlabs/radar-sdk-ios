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

- (instancetype _Nullable)initWithUpdatedAt:(NSDate *)updatedAt
                                   location:(CLLocation *)location
                                  geofences:(NSArray *)geofences
                                      place:(RadarPlace *)place
                                       live:(BOOL)live
                                    country:(RadarRegion * _Nullable)country
                                      state:(RadarRegion * _Nullable)state
                                        dma:(RadarRegion * _Nullable)dma
                                 postalCode:(RadarRegion * _Nullable)postalCode {
    self = [super init];
    if (self) {
        _live = live;
        _updatedAt = updatedAt;
        _location = location;
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
    
    // INIT
    BOOL contextLive = NO;
    NSDate *contextUpdatedAt;
    CLLocation *contextLocation;
    NSArray <RadarGeofence *> *contextGeofences;
    RadarPlace *contextPlace;
    RadarRegion *country;
    RadarRegion *state;
    RadarRegion *dma;
    RadarRegion *postalCode;
    
    // UPDATED AT
    id contextUpdatedAtObj = contextDict[@"updatedAt"];
    if (contextUpdatedAtObj && [contextUpdatedAtObj isKindOfClass:[NSString class]]) {
        NSString *contextUpdatedAtStr = (NSString *)contextUpdatedAtObj;
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
        
        contextUpdatedAt = [dateFormatter dateFromString:contextUpdatedAtStr];
    }
    
    // LIVE
    id contextLiveObj = contextDict[@"live"];
    if (contextLiveObj && [contextLiveObj isKindOfClass:[NSNumber class]]) {
        NSNumber *contextLiveNumber = (NSNumber *)contextLiveObj;
        
        contextLive = [contextLiveNumber boolValue];
    }
    
    // GEOFENCES
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
    
    // PLACE
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
    
    // REGION STATE
    
    // LOCATION
    id contextLocationObj = contextDict[@"location"];
    if (contextLocationObj && [contextLocationObj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *contextLocationDict = (NSDictionary *)contextLocationObj;
        
        id contextLocationCoordinatesObj = contextLocationDict[@"coordinates"];
        if (!contextLocationCoordinatesObj || ![contextLocationCoordinatesObj isKindOfClass:[NSArray class]]) {
            return nil;
        }
        
        NSArray *contextLocationCoordinatesArr = (NSArray *)contextLocationCoordinatesObj;
        if (contextLocationCoordinatesArr.count != 2) {
            return nil;
        }
        
        id contextLocationCoordinatesLongitudeObj = contextLocationCoordinatesArr[0];
        id contextLocationCoordinatesLatitudeObj = contextLocationCoordinatesArr[1];
        if (!contextLocationCoordinatesLongitudeObj || !contextLocationCoordinatesLatitudeObj || ![contextLocationCoordinatesLongitudeObj isKindOfClass:[NSNumber class]] || ![contextLocationCoordinatesLatitudeObj isKindOfClass:[NSNumber class]]) {
            return nil;
        }
        
        NSNumber *contextLocationCoordinatesLongitudeNumber = (NSNumber *)contextLocationCoordinatesLongitudeObj;
        NSNumber *contextLocationCoordinatesLatitudeNumber = (NSNumber *)contextLocationCoordinatesLatitudeObj;
        
        float contextLocationCoordinatesLongitudeFloat = [contextLocationCoordinatesLongitudeNumber floatValue];
        float contextLocationCoordinatesLatitudeFloat = [contextLocationCoordinatesLatitudeNumber floatValue];
        
        id contextLocationAccuracyObj = contextDict[@"locationAccuracy"];
        if (contextLocationAccuracyObj && [contextLocationAccuracyObj isKindOfClass:[NSNumber class]]) {
            NSNumber *contextLocationAccuracyNumber = (NSNumber *)contextLocationAccuracyObj;
            
            contextLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(contextLocationCoordinatesLatitudeFloat, contextLocationCoordinatesLongitudeFloat) altitude:-1 horizontalAccuracy:[contextLocationAccuracyNumber floatValue] verticalAccuracy:-1 timestamp:(contextUpdatedAt ? contextUpdatedAt : [NSDate date])];
        }
    }
    
    if (contextUpdatedAt) {
        return [[RadarContext alloc] initWithUpdatedAt:contextUpdatedAt location:contextLocation geofences:contextGeofences place:contextPlace live:contextLive  country:country state:state dma:dma postalCode:postalCode ];
    }
    
    return nil;

}

@end
