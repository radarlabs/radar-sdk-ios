//
//  RadarGeofence.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarCircleGeometry+Internal.h"
#import "RadarCoordinate+Internal.h"
#import "RadarGeofence+Internal.h"
#import "RadarPolygonGeometry+Internal.h"

@implementation RadarGeofence

+ (NSArray<RadarGeofence *> *_Nullable)geofencesFromObject:(id _Nonnull)object {
    if (!object || ![object isKindOfClass:[NSArray class]]) {
        return nil;
    }

    NSArray *geofencesArr = (NSArray *)object;
    NSMutableArray<RadarGeofence *> *mutableGeofences = [NSMutableArray<RadarGeofence *> new];

    for (id geofenceObj in geofencesArr) {
        RadarGeofence *geofence = [[RadarGeofence alloc] initWithObject:geofenceObj];
        if (!geofence) {
            return nil;
        }
        [mutableGeofences addObject:geofence];
    }

    return mutableGeofences;
}

- (instancetype _Nullable)initWithId:(NSString *)_id
                         description:(NSString *)description
                                 tag:(NSString *)tag
                          externalId:(NSString *_Nullable)externalId
                            metadata:(NSDictionary *_Nullable)metadata
                            geometry:(RadarGeofenceGeometry *_Nonnull)geometry {
    self = [super init];
    if (self) {
        __id = _id;
        ___description = description;
        _tag = tag;
        _externalId = externalId;
        _metadata = metadata;
        _geometry = geometry;
    }
    return self;
}

- (instancetype _Nullable)initWithObject:(id)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *dict = (NSDictionary *)object;

    NSString *_id;
    NSString *description;
    NSString *tag;
    NSString *externalId;
    NSDictionary *metadata;
    RadarGeofenceGeometry *geometry;

    id idObj = dict[@"_id"];
    if (idObj && [idObj isKindOfClass:[NSString class]]) {
        _id = (NSString *)idObj;
    }

    id descriptionObj = dict[@"description"];
    if (descriptionObj && [descriptionObj isKindOfClass:[NSString class]]) {
        description = (NSString *)descriptionObj;
    }

    id tagObj = dict[@"tag"];
    if (tagObj && [tagObj isKindOfClass:[NSString class]]) {
        tag = (NSString *)tagObj;
    }

    id externalIdObj = dict[@"externalId"];
    if (externalIdObj && [externalIdObj isKindOfClass:[NSString class]]) {
        externalId = (NSString *)externalIdObj;
    }

    id metadataObj = dict[@"metadata"];
    if (metadataObj && [metadataObj isKindOfClass:[NSDictionary class]]) {
        metadata = (NSDictionary *)metadataObj;
    }

    id typeObj = dict[@"type"];
    if ([typeObj isKindOfClass:[NSString class]]) {
        NSString *type = (NSString *)typeObj;

        id radiusObj = dict[@"geometryRadius"];
        id centerObj = dict[@"geometryCenter"];

        RadarCoordinate *center = [[RadarCoordinate alloc] initWithCoordinate:CLLocationCoordinate2DMake(0, 0)];
        float radius = 0.0;

        if ([radiusObj isKindOfClass:[NSNumber class]] && [centerObj isKindOfClass:[NSDictionary class]]) {
            id centerCoordinatesObj = ((NSDictionary *)centerObj)[@"coordinates"];
            if (![centerCoordinatesObj isKindOfClass:[NSArray class]]) {
                return nil;
            }

            NSArray *centerCoordinatesArr = (NSArray *)centerCoordinatesObj;
            if (centerCoordinatesArr.count != 2) {
                return nil;
            }

            id centerLongitudeObj = centerCoordinatesArr[0];
            id centerLatitudeObj = centerCoordinatesArr[1];
            if (![centerLongitudeObj isKindOfClass:[NSNumber class]] || ![centerLatitudeObj isKindOfClass:[NSNumber class]]) {
                return nil;
            }

            float centerLongitude = [((NSNumber *)centerLongitudeObj) floatValue];
            float centerLatitude = [((NSNumber *)centerLatitudeObj) floatValue];

            center = [[RadarCoordinate alloc] initWithCoordinate:CLLocationCoordinate2DMake(centerLatitude, centerLongitude)];
            radius = [((NSNumber *)radiusObj) floatValue];
        }

        if ([type isEqualToString:@"circle"]) {
            geometry = [[RadarCircleGeometry alloc] initWithCenter:center radius:radius];
        } else if ([type isEqualToString:@"polygon"] || [type isEqualToString:@"isochrone"]) {
            id geometryObj = dict[@"geometry"];

            if (![geometryObj isKindOfClass:[NSDictionary class]]) {
                return nil;
            }

            id coordinatesObj = ((NSDictionary *)geometryObj)[@"coordinates"];
            if (![coordinatesObj isKindOfClass:[NSArray class]]) {
                return nil;
            }

            NSArray *coordinatesArr = (NSArray *)coordinatesObj;
            if (coordinatesArr.count != 1) {
                return nil;
            }

            id polygonObj = coordinatesArr[0];
            if (![polygonObj isKindOfClass:[NSArray class]]) {
                return nil;
            }

            NSArray *polygonArr = (NSArray *)polygonObj;
            NSMutableArray<RadarCoordinate *> *mutablePolygonCoordinates = [NSMutableArray arrayWithCapacity:polygonArr.count];
            for (uint i = 0; i < polygonArr.count; i++) {
                id polygonCoordinatesObj = polygonArr[i];
                if (![polygonCoordinatesObj isKindOfClass:[NSArray class]]) {
                    return nil;
                }

                NSArray *polygonCoordinatesArr = (NSArray *)polygonCoordinatesObj;
                if (polygonCoordinatesArr.count != 2) {
                    return nil;
                }

                id polygonCoordinateLongitudeObj = polygonCoordinatesArr[0];
                id polygonCoordinateLatitudeObj = polygonCoordinatesArr[1];
                if (![polygonCoordinateLongitudeObj isKindOfClass:[NSNumber class]] || ![polygonCoordinateLatitudeObj isKindOfClass:[NSNumber class]]) {
                    return nil;
                }

                float polygonCoordinateLongitude = [((NSNumber *)polygonCoordinateLongitudeObj) floatValue];
                float polygonCoordinateLatitude = [((NSNumber *)polygonCoordinateLatitudeObj) floatValue];

                CLLocationCoordinate2D polygonCoordinate = CLLocationCoordinate2DMake(polygonCoordinateLatitude, polygonCoordinateLongitude);
                mutablePolygonCoordinates[i] = [[RadarCoordinate alloc] initWithCoordinate:polygonCoordinate];
            }

            geometry = [[RadarPolygonGeometry alloc] initWithCoordinates:mutablePolygonCoordinates center:center radius:radius];
        }
    }

    return [[RadarGeofence alloc] initWithId:_id description:description tag:tag externalId:externalId metadata:metadata geometry:geometry];
}

+ (NSArray<NSDictionary *> *)arrayForGeofences:(NSArray<RadarGeofence *> *)geofences {
    if (!geofences) {
        return nil;
    }

    NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:geofences.count];
    for (RadarGeofence *geofence in geofences) {
        NSDictionary *dict = [geofence dictionaryValue];
        [arr addObject:dict];
    }
    return arr;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setValue:self._id forKey:@"_id"];
    [dict setValue:self.tag forKey:@"tag"];
    [dict setValue:self.externalId forKey:@"externalId"];
    [dict setValue:self.__description forKey:@"description"];
    [dict setValue:self.metadata forKey:@"metadata"];
    return dict;
}

@end
