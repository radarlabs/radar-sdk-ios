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

- (nullable instancetype)initWithDistance:(nullable RadarRouteDistance *)distance
                                 duration:(nullable RadarRouteDuration *)duration {
    self = [super init];
    if (self) {
        _distance = distance;
        _duration = duration;
    }
    return self;
}

- (nullable instancetype)initWithObject:(nullable id)object {
    if (![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    NSDictionary *routeDict = (NSDictionary *)object;

    RadarRouteDistance *distance;
    RadarRouteDuration *duration;
    
    id distanceObj = routeDict[@"distance"];
    if (distanceObj) {
        distance = [[RadarRouteDistance alloc] initWithObject:distanceObj];
    }

    id durationObj = routeDict[@"duration"];
    if (durationObj) {
        duration = [[RadarRouteDuration alloc] initWithObject:durationObj];
    }
    
    return [[RadarRoute alloc] initWithDistance:distance duration:duration];
}

@end
