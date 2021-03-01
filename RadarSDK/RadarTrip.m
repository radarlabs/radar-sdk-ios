//
//  RadarTrip.m
//  RadarSDK
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "RadarTrip.h"
#import "Radar.h"
#import "RadarCoordinate+Internal.h"
#import "RadarTrip+Internal.h"

@implementation RadarTrip

- (instancetype _Nullable)initWithId:(NSString *_Nonnull)_id
                          externalId:(NSString *_Nonnull)externalId
                            metadata:(NSDictionary *_Nullable)metadata
              destinationGeofenceTag:(NSString *_Nullable)destinationGeofenceTag
       destinationGeofenceExternalId:(NSString *_Nullable)destinationGeofenceExternalId
                 destinationLocation:(RadarCoordinate *_Nullable)destinationLocation
                                mode:(RadarRouteMode)mode
                         etaDistance:(float)etaDistance
                         etaDuration:(float)etaDuration
                              status:(RadarTripStatus)status {
    self = [super init];
    if (self) {
        __id = _id;
        _externalId = externalId;
        _metadata = metadata;
        _destinationGeofenceTag = destinationGeofenceTag;
        _destinationGeofenceExternalId = destinationGeofenceExternalId;
        _destinationLocation = destinationLocation;
        _mode = mode;
        _etaDistance = etaDistance;
        _etaDuration = etaDuration;
        _status = status;
    }
    return self;
}

- (instancetype _Nullable)initWithObject:(NSObject *)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *dict = (NSDictionary *)object;

    NSString *_id;
    NSString *externalId;
    NSDictionary *metadata;
    NSString *destinationGeofenceTag;
    NSString *destinationGeofenceExternalId;
    RadarCoordinate *destinationLocation;
    RadarRouteMode mode = RadarRouteModeCar;
    float etaDistance = 0;
    float etaDuration = 0;
    RadarTripStatus status = RadarTripStatusUnknown;

    id idObj = dict[@"_id"];
    if (idObj && [idObj isKindOfClass:[NSString class]]) {
        _id = (NSString *)idObj;
    }

    id externalIdObj = dict[@"externalId"];
    if (externalIdObj && [externalIdObj isKindOfClass:[NSString class]]) {
        externalId = (NSString *)externalIdObj;
    }

    id metadataObj = dict[@"metadata"];
    if (metadataObj && [metadataObj isKindOfClass:[NSDictionary class]]) {
        metadata = (NSDictionary *)metadataObj;
    }

    id destinationGeofenceTagObj = dict[@"destinationGeofenceTag"];
    if (destinationGeofenceTagObj && [destinationGeofenceTagObj isKindOfClass:[NSString class]]) {
        destinationGeofenceTag = (NSString *)destinationGeofenceTagObj;
    }

    id destinationGeofenceExternalIdObj = dict[@"destinationGeofenceExternalId"];
    if (destinationGeofenceExternalIdObj && [destinationGeofenceExternalIdObj isKindOfClass:[NSString class]]) {
        destinationGeofenceExternalId = (NSString *)destinationGeofenceExternalIdObj;
    }

    id destinationLocationObj = dict[@"destinationLocation"];
    if (destinationLocationObj && [destinationLocationObj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *destinationLocationDict = (NSDictionary *)destinationLocationObj;

        id destinationLocationCoordinatesObj = destinationLocationDict[@"coordinates"];
        if (!destinationLocationCoordinatesObj || ![destinationLocationCoordinatesObj isKindOfClass:[NSArray class]]) {
            return nil;
        }

        NSArray *destinationLocationCoordinatesArr = (NSArray *)destinationLocationCoordinatesObj;
        if (destinationLocationCoordinatesArr.count != 2) {
            return nil;
        }

        id destinationLocationCoordinatesLongitudeObj = destinationLocationCoordinatesArr[0];
        id destinationLocationCoordinatesLatitudeObj = destinationLocationCoordinatesArr[1];
        if (!destinationLocationCoordinatesLongitudeObj || !destinationLocationCoordinatesLatitudeObj ||
            ![destinationLocationCoordinatesLongitudeObj isKindOfClass:[NSNumber class]] || ![destinationLocationCoordinatesLatitudeObj isKindOfClass:[NSNumber class]]) {
            return nil;
        }

        NSNumber *destinationLocationCoordinatesLongitudeNumber = (NSNumber *)destinationLocationCoordinatesLongitudeObj;
        NSNumber *destinationLocationCoordinatesLatitudeNumber = (NSNumber *)destinationLocationCoordinatesLatitudeObj;

        float destinationLocationCoordinatesLongitudeFloat = [destinationLocationCoordinatesLongitudeNumber floatValue];
        float destinationLocationCoordinatesLatitudeFloat = [destinationLocationCoordinatesLatitudeNumber floatValue];

        destinationLocation =
            [[RadarCoordinate alloc] initWithCoordinate:CLLocationCoordinate2DMake(destinationLocationCoordinatesLatitudeFloat, destinationLocationCoordinatesLongitudeFloat)];
    }

    id modeObj = dict[@"mode"];
    if (modeObj && [modeObj isKindOfClass:[NSString class]]) {
        NSString *modeStr = (NSString *)modeObj;
        if ([modeStr isEqualToString:@"foot"]) {
            mode = RadarRouteModeFoot;
        } else if ([modeStr isEqualToString:@"bike"]) {
            mode = RadarRouteModeBike;
        } else if ([modeStr isEqualToString:@"truck"]) {
            mode = RadarRouteModeTruck;
        } else if ([modeStr isEqualToString:@"motorbike"]) {
            mode = RadarRouteModeMotorbike;
        } else {
            mode = RadarRouteModeCar;
        }
    }

    id etaObj = dict[@"eta"];
    if (etaObj && [etaObj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *etaDict = (NSDictionary *)etaObj;
        id etaDistanceObj = etaDict[@"distance"];
        if (etaDistanceObj && [etaDistanceObj isKindOfClass:[NSNumber class]]) {
            etaDistance = [(NSNumber *)etaDistanceObj floatValue];
        }
        id etaDurationObj = etaDict[@"duration"];
        if (etaDurationObj && [etaDurationObj isKindOfClass:[NSNumber class]]) {
            etaDuration = [(NSNumber *)etaDurationObj floatValue];
        }
    }

    id statusObj = dict[@"status"];
    if (statusObj && [statusObj isKindOfClass:[NSString class]]) {
        NSString *statusStr = (NSString *)statusObj;
        if ([statusStr isEqualToString:@"started"]) {
            status = RadarTripStatusStarted;
        } else if ([statusStr isEqualToString:@"approaching"]) {
            status = RadarTripStatusApproaching;
        } else if ([statusStr isEqualToString:@"arrived"]) {
            status = RadarTripStatusArrived;
        } else if ([statusStr isEqualToString:@"expired"]) {
            status = RadarTripStatusExpired;
        } else if ([statusStr isEqualToString:@"completed"]) {
            status = RadarTripStatusCompleted;
        } else if ([statusStr isEqualToString:@"canceled"]) {
            status = RadarTripStatusCanceled;
        }
    }

    if (externalId) {
        return [[RadarTrip alloc] initWithId:_id
                                  externalId:externalId
                                    metadata:metadata
                      destinationGeofenceTag:destinationGeofenceTag
               destinationGeofenceExternalId:destinationGeofenceExternalId
                         destinationLocation:destinationLocation
                                        mode:mode
                                 etaDistance:etaDistance
                                 etaDuration:etaDuration
                                      status:status];
    }

    return nil;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[@"_id"] = self._id;
    dict[@"externalId"] = self.externalId;
    dict[@"metadata"] = self.metadata;
    dict[@"destinationGeofenceTag"] = self.destinationGeofenceTag;
    dict[@"destinationGeofenceExternalId"] = self.destinationGeofenceExternalId;
    NSMutableDictionary *destinationLocationDict = [NSMutableDictionary new];
    destinationLocationDict[@"type"] = @"Point";
    NSArray *coordinates = @[@(self.destinationLocation.coordinate.longitude), @(self.destinationLocation.coordinate.latitude)];
    destinationLocationDict[@"coordinates"] = coordinates;
    dict[@"destinationLocation"] = destinationLocationDict;
    dict[@"mode"] = [Radar stringForMode:self.mode];
    NSDictionary *etaDict = @{@"distance": @(self.etaDistance), @"duration": @(self.etaDuration)};
    dict[@"eta"] = etaDict;
    dict[@"status"] = [Radar stringForTripStatus:self.status];
    return dict;
}

@end
