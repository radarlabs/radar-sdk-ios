//
//  RadarPoint.m
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "RadarPoint.h"
#import "RadarPoint+Internal.h"

#import "RadarCollectionAdditions.h"

@implementation RadarPoint

+ (NSArray<RadarPoint *> *)pointsFromObject:(id)object
{
    if (!object || ![object isKindOfClass:[NSArray class]]) {
        return nil;
    }
    
    NSArray *objArray = (NSArray *)object;
    
    NSMutableArray<RadarPoint *> *result = [NSMutableArray arrayWithCapacity:[objArray count]];
    
    for (id pointObj in objArray) {
        RadarPoint *point = [[RadarPoint alloc] initWithObject:pointObj];
        if (!point) {
            return nil;
        }
        [result addObject:point];
    }
    
    return result;
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
    
    if (_id && description && location) {
        // the above fields must be nonnull.
        return [[RadarPoint alloc] initWithId:_id
        description:description
                tag:tag
         externalId:externalId
           metadata:metadata
           location:location];
    }
    return nil;
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

@end
