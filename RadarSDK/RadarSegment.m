//
//  RadarRegion.m
//  RadarSDK
//
//  Copyright © 2019 Radar. All rights reserved.
//

#import "RadarCollectionAdditions.h"
#import "RadarJSONCoding.h"
#import "RadarSegment+Internal.h"

@implementation RadarSegment

- (instancetype)initWithDescription:(nonnull NSString *)description externalId:(nonnull NSString *)externalId {
    self = [super init];
    if (self) {
        __description = description;
        _externalId = externalId;
    }
    return self;
}

+ (nullable NSArray<RadarSegment *> *)segmentsFromObject:(nullable id)object {
    FROM_JSON_ARRAY_DEFAULT_IMP(object, RadarSegment);
}

- (nullable instancetype)initWithObject:(nullable id)object {
    if (![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *dict = (NSDictionary *)object;

    NSString *description = [dict radar_stringForKey:@"description"];
    NSString *externalId = [dict radar_stringForKey:@"externalId"];

    if (description && externalId) {
        return [[RadarSegment alloc] initWithDescription:description externalId:externalId];
    }

    return nil;
}

+ (NSArray<NSDictionary *> *)arrayForSegments:(NSArray<RadarSegment *> *)segments {
    TO_JSON_ARRAY_DEFAULT_IMP(segments, RadarSegment);
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setValue:self._description forKey:@"description"];
    [dict setValue:self.externalId forKey:@"externalId"];
    return dict;
}

@end
