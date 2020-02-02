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
    
    NSDictionary *routesDict = (NSDictionary *)object;

    RadarRouteDistance *geodesic;
    RadarRoute *foot;
    RadarRoute *bike;
    RadarRoute *car;
    RadarRoute *transit;
    
    id geodesicObj = routesDict[@"geodesic"];
    if (geodesicObj) {
        geodesic = [[RadarRouteDistance alloc] initWithObject:geodesicObj];
    }

    id footObj = routesDict[@"foot"];
    if (footObj) {
        foot = [[RadarRoute alloc] initWithObject:footObj];
    }
    
    id bikeObj = routesDict[@"bike"];
    if (bikeObj) {
        bike = [[RadarRoute alloc] initWithObject:bikeObj];
    }
    
    id carObj = routesDict[@"car"];
    if (carObj) {
        car = [[RadarRoute alloc] initWithObject:carObj];
    }
    
    id transitObj = routesDict[@"transit"];
    if (transitObj) {
        transit = [[RadarRoute alloc] initWithObject:transitObj];
    }
    
    return [[RadarRoutes alloc] initWithGeodesic:geodesic foot:foot bike:bike car:car transit:transit];
}

@end
