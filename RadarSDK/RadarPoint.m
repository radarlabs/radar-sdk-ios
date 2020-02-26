//
//  RadarPoint.m
//  RadarSDKTests
//
//  Created by Ping Xia on 2/26/20.
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "RadarPoint.h"
#import "RadarPoint+Internal.h"

#import "CollectionAdditions.h"

@implementation RadarPoint

+ (NSArray<RadarPoint *> *)pointsFromObject:(id)object
{
    if (!object || ![object isKindOfClass:[NSArray class]]) {
        return nil;
    }

    return [(NSArray *)object radar_mapObjectsUsingBlock:^RadarPoint *_Nullable(id _Nonnull pointObj) {
      return [[RadarPoint alloc] initWithObject:pointObj];
    }];
}

- (instancetype)initWithObject:(id)object
{
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *dict = (NSDictionary *)object;
    NSString *_id = [dict radar_stringForKey:@"_id"];
    NSString *description = [dict radar_stringForKey:@"description"];
    NSString *tag = [dict radar_stringForKey:@"tag"];
    NSString *externalId = [dict radar_stringForKey:@"externalId"];
    NSDictionary *metadata = [dict radar_dictionaryForKey:@"metadata"];
    RadarCoordinate *location = [dict radar_coordinateForKey:@"geometry"];

    return [[RadarPoint alloc] initWithId:_id
                              description:description
                                      tag:tag
                               externalId:externalId
                                 metadata:metadata
                                 location:location];
}

- (instancetype)initWithId:(NSString *)_id
               description:(NSString *)description
                       tag:(NSString *)tag
                externalId:(NSString *)externalId
                  metadata:(NSDictionary *)metadata
                  location:(RadarCoordinate *)location
{
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

#pragma mark - serialization

//+ (NSArray<NSDictionary *> *)serializeArray:(NSArray<RadarPoint *> *)points
//{
//    if (!points) {
//        return nil;
//    }
//    return [points radar_mapObjectsUsingBlock:^NSDictionary * _Nullable(RadarPoint * _Nonnull point) {
//        return [point serialize];
//    }];
//}
//
//- (NSDictionary *)serialize
//{
//    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
//    [dict setValue:self._id forKey:@"_id"];
//    [dict setValue:self.tag forKey:@"tag"];
//    [dict setValue:self.externalId forKey:@"externalId"];
//    [dict setValue:self._description forKey:@"description"];
//    [dict setValue:self.metadata forKey:@"metadata"];
//    return dict;
//}


@end
