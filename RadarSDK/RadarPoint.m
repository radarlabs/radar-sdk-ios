//
//  RadarPoint.m
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "RadarPoint.h"
#import "RadarCoordinate+Internal.h"
#import "RadarPoint+Internal.h"

#import "RadarCollectionAdditions.h"
#import "RadarJSONCoding.h"

@implementation RadarPoint

- (instancetype)initWithId:(NSString *)_id
               description:(NSString *)description
                       tag:(NSString *)tag
                externalId:(NSString *)externalId
                  metadata:(NSDictionary *)metadata
                  location:(RadarCoordinate *)location {
    self = [super init];
    if (self) {
        __id = [_id copy];
        __description = [description copy];
        _tag = [tag copy];
        _externalId = [externalId copy];
        _metadata = metadata;
        _location = location;
    }
    return self;
}

#pragma mark - JSON coding

+ (NSArray<RadarPoint *> *)pointsFromObject:(id)object {
    FROM_JSON_ARRAY_DEFAULT_IMP(object, RadarPoint);
}

- (instancetype)initWithObject:(id)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
    }

    NSDictionary *dict = (NSDictionary *)object;
    NSString *_id = [dict radar_stringForKey:@"_id"];
    NSString *description = [dict radar_stringForKey:@"description"];
    NSString *tag = [dict radar_stringForKey:@"tag"];
    NSString *externalId = [dict radar_stringForKey:@"externalId"];
    NSDictionary *metadata = [dict radar_dictionaryForKey:@"metadata"];
    RadarCoordinate *location = [[RadarCoordinate alloc] initWithObject:dict[@"geometry"]];

    if (_id && description && location) {
        return [[RadarPoint alloc] initWithId:_id description:description tag:tag externalId:externalId metadata:metadata location:location];
    }
    return nil;
}

+ (NSArray<NSDictionary *> *)arrayForPoints:(NSArray<RadarPoint *> *)points {
    TO_JSON_ARRAY_DEFAULT_IMP(points, RadarPoint);
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
