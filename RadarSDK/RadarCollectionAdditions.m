//
//  RadarCollectionAdditions.m
//  RadarSDK
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "RadarCollectionAdditions.h"
#import "RadarCoordinate+Internal.h"

@implementation NSArray (Radar)

- (NSArray *)radar_mapObjectsUsingBlock:(id _Nullable (^)(id _Nonnull))block {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[self count]];

    [self enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *stop) {
        [result addObject:block(obj)];
    }];
    return [result copy];
}

- (nullable instancetype)initWithRadarJSONObject:(nullable id)object {
    if (!object || ![object isKindOfClass:[NSArray class]]) {
        return nil;
    }

    NSArray *array = [(NSArray *)object radar_mapObjectsUsingBlock:^id _Nullable(id _Nonnull obj) {
        if ([object conformsToProtocol:@protocol(RadarJSONCoding)]) {
            return [[[object class] alloc] initWithRadarJSONObject:object];
        } else {
            return object;
        }
    }];

    return [self initWithArray:array];
}

- (nonnull id)toRadarJSONObject {
    return [self radar_mapObjectsUsingBlock:^id _Nullable(id _Nonnull obj) {
        if ([obj conformsToProtocol:@protocol(RadarJSONCoding)]) {
            return [obj toRadarJSONObject];
        } else {
            return obj;
        }
    }];
}

@end

@implementation NSDictionary (Radar)

#define GET_DICT_VALUE_FOR_KEY(_key, _valueClassName)                                                                                                                              \
    {                                                                                                                                                                              \
        id value = self[key];                                                                                                                                                      \
        if (value && [value isKindOfClass:[_valueClassName class]]) {                                                                                                              \
            return (_valueClassName *)value;                                                                                                                                       \
        }                                                                                                                                                                          \
        return nil;                                                                                                                                                                \
    }

- (NSString *)radar_stringForKey:(id)key {
    GET_DICT_VALUE_FOR_KEY(key, NSString);
}

- (NSDictionary *)radar_dictionaryForKey:(id)key {
    GET_DICT_VALUE_FOR_KEY(key, NSDictionary);
}

- (NSArray *)radar_arrayForKey:(id)key {
    GET_DICT_VALUE_FOR_KEY(key, NSArray);
}

- (RadarCoordinate *)radar_coordinateForKey:(id)key {
    NSDictionary *dict = [self radar_dictionaryForKey:key];
    if (!dict) {
        return nil;
    }

    NSArray *coordinates = [dict radar_arrayForKey:@"coordinates"];
    if (!coordinates || coordinates.count != 2 || ![coordinates[0] isKindOfClass:[NSNumber class]] || ![coordinates[1] isKindOfClass:[NSNumber class]]) {
        return nil;
    }
    float longitude = [(NSNumber *)coordinates[0] floatValue];
    if (longitude < -180 || longitude > 180) {
        return nil;
    }
    float latitude = [(NSNumber *)coordinates[1] floatValue];
    if (latitude < -90 || latitude > 90) {
        return nil;
    }

    return [[RadarCoordinate alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude, longitude)];
}

@end
