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
    return result;
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

- (NSNumber *)radar_numberForKey:(id)key {
    GET_DICT_VALUE_FOR_KEY(key, NSNumber);
}

- (BOOL)radar_boolForKey:(id)key {
    NSNumber *valueNumber = [self radar_numberForKey:key];
    return valueNumber ? [valueNumber boolValue] : NO;
}

- (NSDate *)radar_dateForKey:(id)key {
    NSString *dateStr = [self radar_stringForKey:key];
    if (dateStr) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];

        return [dateFormatter dateFromString:dateStr];
    }
    return nil;
}

- (NSDictionary *)radar_dictionaryForKey:(id)key {
    GET_DICT_VALUE_FOR_KEY(key, NSDictionary);
}

- (NSArray *)radar_arrayForKey:(id)key {
    GET_DICT_VALUE_FOR_KEY(key, NSArray);
}

@end
