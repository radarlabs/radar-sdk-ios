//
//  RadarRoute.m
//  RadarSDK
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "RadarRoute.h"
#import "RadarRouteDistance+Internal.h"
#import "RadarRouteDuration+Internal.h"
#import "RadarRouteGeometry+Internal.h"

@implementation RadarRoute

- (nullable instancetype)initWithDistance:(nullable RadarRouteDistance *)distance
                                 duration:(nullable RadarRouteDuration *)duration
                                 geometry:(nullable RadarRouteGeometry *)geometry {
    self = [super init];
    if (self) {
        _distance = distance;
        _duration = duration;
        _geometry = geometry;
    }
    return self;
}

- (nullable instancetype)initWithObject:(nullable id)object {
    if (![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *dict = (NSDictionary *)object;

    RadarRouteDistance *distance = [[RadarRouteDistance alloc] initWithObject:dict[@"distance"]];
    RadarRouteDuration *duration = [[RadarRouteDuration alloc] initWithObject:dict[@"duration"]];
    RadarRouteGeometry *geometry = [[RadarRouteGeometry alloc] initWithObject:dict[@"geometry"]];

    if (distance && duration) {
        return [[RadarRoute alloc] initWithDistance:distance duration:duration geometry:geometry];
    }

    return nil;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    if (self.distance) {
        NSDictionary *distanceDict = [self.distance dictionaryValue];
        [dict setValue:distanceDict forKey:@"distance"];
    }
    if (self.duration) {
        NSDictionary *durationDict = [self.duration dictionaryValue];
        [dict setValue:durationDict forKey:@"duration"];
    }
    if (self.geometry) {
        NSDictionary *geometryDict = [self.geometry dictionaryValue];
        [dict setValue:geometryDict forKey:@"geometry"];
    }
    return dict;
}

@end
