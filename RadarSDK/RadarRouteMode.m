// RadarRouteMode.m
#import "RadarRouteMode.h"

@implementation RadarRouteModeUtils

+ (NSString *)stringForMode:(RadarRouteMode)mode {
    switch (mode) {
        case RadarRouteModeFoot:
            return @"foot";
        case RadarRouteModeBike:
            return @"bike";
        case RadarRouteModeCar:
            return @"car";
        case RadarRouteModeTruck:
            return @"truck";
        case RadarRouteModeMotorbike:
            return @"motorbike";
        default:
            return @"unknown";
    }
}

@end