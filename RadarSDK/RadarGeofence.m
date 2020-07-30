//
//  RadarGeofence.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarCircleGeometry+Internal.h"
#import "RadarCollectionAdditions.h"
#import "RadarCoordinate+Internal.h"
#import "RadarGeofence+Internal.h"
#import "RadarJSONCoding.h"
#import "RadarPolygonGeometry+Internal.h"

@implementation RadarGeofence

- (instancetype _Nullable)initWithId:(NSString *)_id
                         description:(NSString *)description
                                 tag:(NSString *)tag
                          externalId:(NSString *_Nullable)externalId
                            metadata:(NSDictionary *_Nullable)metadata
                            geometry:(RadarGeofenceGeometry *_Nonnull)geometry {
    self = [super init];
    if (self) {
        __id = _id;
        __description = description;
        _tag = tag;
        _externalId = externalId;
        _metadata = metadata;
        _geometry = geometry;
    }
    return self;
}

#pragma mark - JSON coding

+ (NSArray<RadarGeofence *> *_Nullable)geofencesFromObject:(id _Nonnull)object {
    FROM_JSON_ARRAY_DEFAULT_IMP(object, RadarGeofence);
}

- (instancetype _Nullable)initWithObject:(id)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *dict = (NSDictionary *)object;

    NSString *_id = [dict radar_stringForKey:@"_id"];
    NSString *description = [dict radar_stringForKey:@"description"];
    NSString *tag = [dict radar_stringForKey:@"tag"];
    NSString *externalId = [dict radar_stringForKey:@"externalId"];
    NSDictionary *metadata = [dict radar_dictionaryForKey:@"metadata"];
    RadarGeofenceGeometry *geometry = [[RadarPolygonGeometry alloc] initWithCoordinates:@[]];

    id typeObj = dict[@"type"];
    if ([typeObj isKindOfClass:[NSString class]]) {
        NSString *type = (NSString *)typeObj;
        if ([type isEqualToString:@"circle"]) {
            NSNumber *centerRadius = [dict radar_numberForKey:@"geometryRadius"];

            RadarCoordinate *center = [[RadarCoordinate alloc] initWithObject:dict[@"geometryCenter"]];
            if (!center || !centerRadius) {
                return nil;
            }
            geometry = [[RadarCircleGeometry alloc] initWithCenter:center radius:[centerRadius floatValue]];
        } else if ([type isEqualToString:@"polygon"]) {
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
            NSArray<RadarCoordinate *> *coordinates = [RadarCoordinate coordinatesFromJSONCoordinates:polygonObj];
            if (!coordinates) {
                return nil;
            }

            geometry = [[RadarPolygonGeometry alloc] initWithCoordinates:coordinates];
        }
    }

    if (_id && description && geometry) {
        return [[RadarGeofence alloc] initWithId:_id description:description tag:tag externalId:externalId metadata:metadata geometry:geometry];
    } else {
        return nil;
    }
}

+ (NSArray<NSDictionary *> *)arrayForGeofences:(NSArray<RadarGeofence *> *)geofences {
    TO_JSON_ARRAY_DEFAULT_IMP(geofences, RadarGeofence);
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setValue:self._id forKey:@"_id"];
    [dict setValue:self.tag forKey:@"tag"];
    [dict setValue:self.externalId forKey:@"externalId"];
    [dict setValue:self._description forKey:@"description"];
    [dict setValue:self.metadata forKey:@"metadata"];
    return dict;
}

@end
