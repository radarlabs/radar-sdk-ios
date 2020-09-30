//
//  RadarUser.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarTrip.h"
#import "Radar.h"
#import "RadarCollectionAdditions.h"
#import "RadarTrip+Internal.h"

@implementation RadarTrip

- (instancetype _Nullable)initWithExternalId:(NSString *_Nonnull)externalId
                     metadata:(NSDictionary *_Nullable)metadata
       destinationGeofenceTag:(NSString *_Nullable)destinationGeofenceTag
destinationGeofenceExternalId:(NSString *_Nullable)destinationGeofenceExternalId
          destinationLocation:(RadarCoordinate *_Nullable)destinationLocation
                         mode:(RadarRouteMode)mode
                  etaDistance:(float)etaDistance
                  etaDuration:(float)etaDuration
                      arrived:(BOOL)arrived {
    self = [super init];
    if (self) {
        _externalId = externalId;
        _metadata = metadata;
        _destinationGeofenceTag = destinationGeofenceTag;
        _destinationGeofenceExternalId = destinationGeofenceExternalId;
        _destinationLocation = destinationLocation;
        _mode = mode;
        _etaDistance = etaDistance;
        _etaDuration = etaDuration;
        _arrived = arrived;
    }
    return self;
}

- (instancetype _Nullable)initWithObject:(NSObject *)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *dict = (NSDictionary *)object;

    NSString *externalId;
    NSDictionary *metadata;
    NSString *destinationGeofenceTag;
    NSString *destinationGeofenceExternalId;
    RadarCoordinate *destinationLocation;
    RadarRouteMode mode = RadarRouteModeCar;
    float etaDistance = 0;
    float etaDuration = 0;
    BOOL arrived = NO;

    externalId = [dict radar_stringForKey:@"externalId"];
    metadata = [dict radar_dictionaryForKey:@"metadata"];
    destinationGeofenceTag = [dict radar_stringForKey:@"destinationGeofenceTag"];
    destinationGeofenceExternalId = [dict radar_stringForKey:@"destinationGeofenceExternalId"];
    destinationLocation = [dict radar_coordinateForKey:@"destinationLocation"];
    NSString *modeStr = [dict radar_stringForKey:@"mode"];
    if ([modeStr isEqualToString:@"foot"]) {
        mode = RadarRouteModeFoot;
    } else if ([modeStr isEqualToString:@"bike"]) {
        mode = RadarRouteModeBike;
    } else {
        mode = RadarRouteModeCar;
    }
    NSDictionary *etaDict = [dict radar_dictionaryForKey:@"eta"];
    if (etaDict) {
        etaDistance = [etaDict radar_floatForKey:@"distance"];
        etaDuration = [etaDict radar_floatForKey:@"duration"];
    }
    arrived = [dict radar_boolForKey:@"arrived"];
    

    if (externalId) {
        return [[RadarTrip alloc] initWithExternalId:externalId
                                            metadata:metadata
                              destinationGeofenceTag:destinationGeofenceTag
                       destinationGeofenceExternalId:destinationGeofenceExternalId
                                 destinationLocation:destinationLocation
                                                mode:mode
                                         etaDistance:etaDistance
                                         etaDuration:etaDuration
                                             arrived:arrived];
    }

    return nil;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[@"externalId"] = self.externalId;
    dict[@"metadata"] = self.metadata;
    dict[@"destinationGeofenceTag"] = self.destinationGeofenceTag;
    dict[@"destinationGeofenceExternalId"] = self.destinationGeofenceExternalId;
    NSMutableDictionary *destinationLocationDict = [NSMutableDictionary new];
    destinationLocationDict[@"type"] = @"Point";
    NSArray *coordinates = @[
        @(self.destinationLocation.coordinate.longitude),
        @(self.destinationLocation.coordinate.latitude)
    ];
    destinationLocationDict[@"coordinates"] = coordinates;
    dict[@"destinationLocation"] = destinationLocationDict;
    dict[@"mode"] = [Radar stringForMode:self.mode];
    NSDictionary *etaDict = @{
        @"distance": @(self.etaDistance),
        @"duration": @(self.etaDuration)
    };
    dict[@"eta"] = etaDict;
    dict[@"arrived"] = @(self.arrived);
    return dict;
}

@end
