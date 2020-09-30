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

NSString *const kExternalId = @"externalId";
NSString *const kMetadata = @"metadata";
NSString *const kDestinationGeofenceTag = @"destinationGeofenceTag";
NSString *const kDestinationGeofenceExternalId = @"destinationGeofenceExternalId";
NSString *const kDestinationLocation = @"destinationLocation";
NSString *const kCoordinates = @"coordinates";
NSString *const kType = @"type";
NSString *const kPoint = @"Point";
NSString *const kMode = @"mode";
NSString *const kETA = @"eta";
NSString *const kDistance = @"distance";
NSString *const kDuration = @"duration";
NSString *const kArrived = @"arrived";

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

    externalId = [dict radar_stringForKey:kExternalId];
    metadata = [dict radar_dictionaryForKey:kMetadata];
    destinationGeofenceTag = [dict radar_stringForKey:kDestinationGeofenceTag];
    destinationGeofenceExternalId = [dict radar_stringForKey:kDestinationGeofenceExternalId];
    destinationLocation = [dict radar_coordinateForKey:kDestinationLocation];
    NSString *modeStr = [dict radar_stringForKey:@"mode"];
    if ([modeStr isEqualToString:@"foot"]) {
        mode = RadarRouteModeFoot;
    } else if ([modeStr isEqualToString:@"bike"]) {
        mode = RadarRouteModeBike;
    } else {
        mode = RadarRouteModeCar;
    }
    NSDictionary *etaDict = [dict radar_dictionaryForKey:kETA];
    if (etaDict) {
        etaDistance = [etaDict radar_floatForKey:kDistance];
        etaDistance = [etaDict radar_floatForKey:kDuration];
    }
    arrived = [dict radar_boolForKey:kArrived];
    

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
    dict[kExternalId] = self.externalId;
    dict[kMetadata] = self.metadata;
    dict[kDestinationGeofenceTag] = self.destinationGeofenceTag;
    dict[kDestinationGeofenceExternalId] = self.destinationGeofenceExternalId;
    NSMutableDictionary *destinationLocationDict = [NSMutableDictionary new];
    destinationLocationDict[kType] = kPoint;
    NSArray *coordinates = @[
        @(self.destinationLocation.coordinate.longitude),
        @(self.destinationLocation.coordinate.latitude)
    ];
    destinationLocationDict[kCoordinates] = coordinates;
    dict[kDestinationLocation] = destinationLocationDict;
    dict[kMode] = [Radar stringForMode:self.mode];
    NSDictionary *etaDict = @{
        kDistance: @(self.etaDistance),
        kDuration: @(self.etaDuration)
    };
    dict[kETA] = etaDict;
    dict[kArrived] = @(self.arrived);
    return dict;
}

@end
