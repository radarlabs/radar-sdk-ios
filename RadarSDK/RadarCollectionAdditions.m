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
        id mappedObj = block(obj);
        if (mappedObj) {
            [result addObject:mappedObj];
        }
    }];
    return [result copy];
}

- (NSDictionary *)radar_mapToDictionaryUsingKeyBlock:(id _Nullable (^)(id _Nonnull))keyBlock valueBlock:(id _Nullable (^)(id _Nonnull))valueBlock {
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[self count]];

    [self enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        id key = keyBlock(obj);
        id value = valueBlock(obj);
        if (key && value) {
            [result setValue:value forKey:key];
        }
    }];

    return [result copy];
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

@end
