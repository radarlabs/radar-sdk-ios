//
//  RadarRegion.m
//  RadarSDK
//
//  Copyright © 2019 Radar. All rights reserved.
//

#import "RadarSegment+Internal.h"

@implementation RadarSegment

- (instancetype)initWithDescription:(nonnull NSString *)description externalId:(nonnull NSString *)externalId {
    self = [super init];
    if (self) {
        ___description = description;
        _externalId = externalId;
    }
    return self;
}

- (nullable instancetype)initWithObject:(nullable id)object {
    if (![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *dict = (NSDictionary *)object;

    NSString *description;
    NSString *externalId;

    id descriptionObj = dict[@"description"];
    if ([descriptionObj isKindOfClass:[NSString class]]) {
        description = (NSString *)descriptionObj;
    }

    id externalIdObj = dict[@"externalId"];
    if ([externalIdObj isKindOfClass:[NSString class]]) {
        externalId = (NSString *)externalIdObj;
    }

    if (description && externalId) {
        return [[RadarSegment alloc] initWithDescription:description externalId:externalId];
    }

    return nil;
}

+ (NSArray<NSDictionary *> *)arrayForSegments:(NSArray<RadarSegment *> *)segments {
    if (!segments) {
        return nil;
    }

    NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:segments.count];
    for (RadarSegment *segment in segments) {
        NSDictionary *dict = [segment dictionaryValue];
        [arr addObject:dict];
    }
    return arr;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setValue:self.__description forKey:@"description"];
    [dict setValue:self.externalId forKey:@"externalId"];
    return dict;
}

@end
