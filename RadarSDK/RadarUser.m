//
//  RadarUser.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarUser.h"
#import "RadarUser+Internal.h"
#import "RadarChain+Internal.h"
#import "RadarGeofence+Internal.h"
#import "RadarPlace+Internal.h"
#import "RadarRegion+Internal.h"
#import "RadarUserInsights+Internal.h"

@implementation RadarUser

- (instancetype _Nullable)initWithId:(NSString *)_id userId:(NSString *)userId deviceId:(NSString *)deviceId description:(NSString *)description metadata:(NSDictionary *)metadata location:(CLLocation *)location geofences:(NSArray *)geofences place:(RadarPlace *)place insights:(RadarUserInsights *)insights stopped:(BOOL)stopped foreground:(BOOL)foreground country:(RadarRegion * _Nullable)country state:(RadarRegion * _Nullable)state dma:(RadarRegion * _Nullable)dma postalCode:(RadarRegion * _Nullable)postalCode nearbyPlaceChains:(nullable NSArray<RadarChain *> *)nearbyPlaceChains {
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
    }
    return self;
}

- (instancetype _Nullable)initWithObject:(NSObject *)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    NSDictionary *userDict = (NSDictionary *)object;
    
    NSString *userId;
    NSString *userUserId;
    NSString *userDeviceId;
    NSString *userDescription;
    NSDictionary *userMetadata;
    CLLocation *userLocation;
    NSArray<RadarGeofence *> *userGeofences;
    RadarPlace *userPlace;
    RadarUserInsights *userInsights;
    BOOL stopped = NO;
    BOOL foreground = NO;
    RadarRegion *country;
    RadarRegion *state;
    RadarRegion *dma;
    RadarRegion *postalCode;
    NSArray<RadarChain *> *userPlaceChains;

    id userIdObj = userDict[@"_id"];
    if (userIdObj && [userIdObj isKindOfClass:[NSString class]]) {
        userId = (NSString *)userIdObj;
    }
    
    id userUserIdObj = userDict[@"userId"];
    if (userUserIdObj && [userUserIdObj isKindOfClass:[NSString class]]) {
        userUserId = (NSString *)userUserIdObj;
    }
    
    id userDeviceIdObj = userDict[@"deviceId"];
    if (userDeviceIdObj && [userDeviceIdObj isKindOfClass:[NSString class]]) {
        userDeviceId = (NSString *)userDeviceIdObj;
    }
    
    id userDescriptionObj = userDict[@"description"];
    if (userDescriptionObj && [userDescriptionObj isKindOfClass:[NSString class]]) {
        userDescription = (NSString *)userDescriptionObj;
    }
    
    id userMetadataObj = userDict[@"metadata"];
    if (userMetadataObj && [userMetadataObj isKindOfClass:[NSDictionary class]]) {
        userMetadata = (NSDictionary *)userMetadataObj;
    }
    
    id userLocationObj = userDict[@"location"];
    if (userLocationObj && [userLocationObj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *userLocationDict = (NSDictionary *)userLocationObj;
        
        id userLocationCoordinatesObj = userLocationDict[@"coordinates"];
        if (!userLocationCoordinatesObj || ![userLocationCoordinatesObj isKindOfClass:[NSArray class]]) {
            return nil;
        }
        
        NSArray *userLocationCoordinatesArr = (NSArray *)userLocationCoordinatesObj;
        if (userLocationCoordinatesArr.count != 2) {
            return nil;
        }
        
        id userLocationCoordinatesLongitudeObj = userLocationCoordinatesArr[0];
        id userLocationCoordinatesLatitudeObj = userLocationCoordinatesArr[1];
        if (!userLocationCoordinatesLongitudeObj || !userLocationCoordinatesLatitudeObj || ![userLocationCoordinatesLongitudeObj isKindOfClass:[NSNumber class]] || ![userLocationCoordinatesLatitudeObj isKindOfClass:[NSNumber class]]) {
            return nil;
        }
        
        NSNumber *userLocationCoordinatesLongitudeNumber = (NSNumber *)userLocationCoordinatesLongitudeObj;
        NSNumber *userLocationCoordinatesLatitudeNumber = (NSNumber *)userLocationCoordinatesLatitudeObj;
        
        float userLocationCoordinatesLongitudeFloat = [userLocationCoordinatesLongitudeNumber floatValue];
        float userLocationCoordinatesLatitudeFloat = [userLocationCoordinatesLatitudeNumber floatValue];
        
        id userLocationAccuracyObj = userDict[@"locationAccuracy"];
        if (userLocationAccuracyObj && [userLocationAccuracyObj isKindOfClass:[NSNumber class]]) {
            NSNumber *userLocationAccuracyNumber = (NSNumber *)userLocationAccuracyObj;
            
            userLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(userLocationCoordinatesLatitudeFloat, userLocationCoordinatesLongitudeFloat) altitude:-1 horizontalAccuracy:[userLocationAccuracyNumber floatValue] verticalAccuracy:-1 timestamp:[NSDate date]];
        }
    }
    
    id userGeofencesObj = userDict[@"geofences"];
    if (userGeofencesObj && [userGeofencesObj isKindOfClass:[NSArray class]]) {
        NSMutableArray<RadarGeofence *> *mutableUserGeofences = [NSMutableArray<RadarGeofence *> new];
        
        NSArray *userGeofencesArr = (NSArray *)userGeofencesObj;
        for (id userGeofenceObj in userGeofencesArr) {
            RadarGeofence *userGeofence = [[RadarGeofence alloc] initWithObject:userGeofenceObj];
            if (!userGeofence) {
                return nil;
            }
            
            [mutableUserGeofences addObject:userGeofence];
        }
        
        userGeofences = mutableUserGeofences;
    }
    
    id userPlaceObj = userDict[@"place"];
    userPlace = [[RadarPlace alloc] initWithObject:userPlaceObj];
    
    id userInsightsObj = userDict[@"insights"];
    if (userInsightsObj && [userInsightsObj isKindOfClass:[NSDictionary class]]) {
        userInsights = [[RadarUserInsights alloc] initWithObject:userInsightsObj];
    }
    
    id stoppedObj = userDict[@"stopped"];
    if (stoppedObj && [stoppedObj isKindOfClass:[NSNumber class]]) {
        NSNumber *stoppedNumber = (NSNumber *)stoppedObj;
        
        stopped = [stoppedNumber boolValue];
    }
    
    id foregroundObj = userDict[@"foreground"];
    if (foregroundObj && [foregroundObj isKindOfClass:[NSNumber class]]) {
        NSNumber *foregroundNumber = (NSNumber *)foregroundObj;
        
        foreground = [foregroundNumber boolValue];
    }
    
    id countryObj = userDict[@"country"];
    country = [[RadarRegion alloc] initWithObject:countryObj];

    id stateObj = userDict[@"state"];
    state = [[RadarRegion alloc] initWithObject:stateObj];
    
    id dmaObj = userDict[@"dma"];
    dma = [[RadarRegion alloc] initWithObject:dmaObj];
    
    id postalCodeObj = userDict[@"postalCode"];
    postalCode = [[RadarRegion alloc] initWithObject:postalCodeObj];
    
    id userNearbyChainsObj = userDict[@"nearbyPlaceChains"];
    if ([userNearbyChainsObj isKindOfClass:[NSArray class]]) {
        NSArray *nearbyChainsArr = (NSArray *)userNearbyChainsObj;
        
        NSMutableArray<RadarChain *> *mutableNearbyChains = [NSMutableArray<RadarChain *> new];
        for (id chainObj in nearbyChainsArr) {
            RadarChain *placeChain = [[RadarChain alloc] initWithObject:chainObj];
            if (placeChain) {
                [mutableNearbyChains addObject:placeChain];
            }
        }
        
        userPlaceChains = mutableNearbyChains;
    }
    
    if (userId && userLocation) {
        return [[RadarUser alloc] initWithId:userId userId:userUserId deviceId:userDeviceId description:userDescription metadata:userMetadata location:userLocation geofences:userGeofences place:userPlace insights:userInsights stopped:stopped foreground:foreground country:country state:state dma:dma postalCode:postalCode nearbyPlaceChains:userPlaceChains];
    }
    
    return nil;
}

@end
