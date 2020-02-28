//
//  RadarRoute.m
//  RadarSDKTests
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "RadarRoute.h"
#import "RadarRouteDistance+Internal.h"
#import "RadarRouteDuration+Internal.h"

@implementation RadarRoute

- (nullable instancetype)initWithDistance:(nullable RadarRouteDistance *)distance duration:(nullable RadarRouteDuration *)duration
{
    self = [super init];
    if (self) {
        _distance = distance;
        _duration = duration;
    }
    return self;
}

- (nullable instancetype)initWithObject:(nullable id)object
{
    if (![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *dict = (NSDictionary *)object;

    RadarRouteDistance *distance;
    RadarRouteDuration *duration;

    id distanceObj = dict[@"distance"];
    if (distanceObj) {
        distance = [[RadarRouteDistance alloc] initWithObject:distanceObj];
    }

    id durationObj = dict[@"duration"];
    if (durationObj) {
        duration = [[RadarRouteDuration alloc] initWithObject:durationObj];
    }

    if (distance && duration) {
        return [[RadarRoute alloc] initWithDistance:distance duration:duration];
    }

    return nil;
}

- (NSDictionary *)serialize
{
    NSMutableDictionary *dict = [NSMutableDictionary new];
    if (self.distance) {
        NSDictionary *distanceDict = [self.distance serialize];
        [dict setValue:distanceDict forKey:@"distance"];
    }
    if (self.duration) {
        NSDictionary *durationDict = [self.duration serialize];
        [dict setValue:durationDict forKey:@"duration"];
    }
    return dict;
}

@end
