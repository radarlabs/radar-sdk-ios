//
//  RadarRoutes.m
//  RadarSDKTests
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "RadarRoutes.h"
#import "RadarRoute+Internal.h"
#import "RadarRouteDistance+Internal.h"

@implementation RadarRoutes

- (nullable instancetype)initWithGeodesic:(nullable RadarRouteDistance *)geodesic
                                     foot:(nullable RadarRoute *)foot
                                     bike:(nullable RadarRoute *)bike
                                      car:(nullable RadarRoute *)car
                                  transit:(nullable RadarRoute *)transit {
    self = [super init];
    if (self) {
        _geodesic = geodesic;
        _foot = foot;
        _bike = bike;
        _car = car;
        _transit = transit;
    }
    return self;
}

- (nullable instancetype)initWithObject:(nullable id)object {
    if (![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *dict = (NSDictionary *)object;

    RadarRouteDistance *geodesic;
    RadarRoute *foot;
    RadarRoute *bike;
    RadarRoute *car;
    RadarRoute *transit;

    id geodesicObj = dict[@"geodesic"];
    if (geodesicObj) {
      id geodesicDistanceObj = geodesicObj[@"distance"];
      if (geodesicDistanceObj) {
          geodesic = [[RadarRouteDistance alloc] initWithObject:geodesicDistanceObj];
      }
    }

    id footObj = dict[@"foot"];
    if (footObj) {
        foot = [[RadarRoute alloc] initWithObject:footObj];
    }

    id bikeObj = dict[@"bike"];
    if (bikeObj) {
        bike = [[RadarRoute alloc] initWithObject:bikeObj];
    }

    id carObj = dict[@"car"];
    if (carObj) {
        car = [[RadarRoute alloc] initWithObject:carObj];
    }

    id transitObj = dict[@"transit"];
    if (transitObj) {
        transit = [[RadarRoute alloc] initWithObject:transitObj];
    }

    return [[RadarRoutes alloc] initWithGeodesic:geodesic foot:foot bike:bike car:car transit:transit];
}

- (NSDictionary *)serialize {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    if (self.geodesic) {
        NSDictionary *geodesicDict = [self.geodesic serialize];
        [dict setValue:geodesicDict forKey:@"geodesic"];
    }
    if (self.foot) {
        NSDictionary *footDict = [self.foot serialize];
        [dict setValue:footDict forKey:@"foot"];
    }
    if (self.bike) {
        NSDictionary *bikeDict = [self.bike serialize];
        [dict setValue:bikeDict forKey:@"bike"];
    }
    if (self.car) {
        NSDictionary *carDict = [self.car serialize];
        [dict setValue:carDict forKey:@"car"];
    }
    if (self.transit) {
        NSDictionary *transitDict = [self.transit serialize];
        [dict setValue:transitDict forKey:@"transit"];
    }
    return dict;
}

@end
