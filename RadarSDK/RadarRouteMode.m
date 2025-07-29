// RadarRouteMode.m
#import "RadarRouteMode.h"

@implementation RadarRouteModeUtils

+ (NSString *)stringForMode:(RadarRouteMode)mode {
    if (mode == 0) {
        return @"unknown";
    }
    NSMutableArray *modes = [NSMutableArray array];
    if (mode & RadarRouteModeFoot) {
        [modes addObject:@"foot"];
    }
    if (mode & RadarRouteModeBike) {
        [modes addObject:@"bike"];
    }
    if (mode & RadarRouteModeCar) {
        [modes addObject:@"car"];
    }
    if (mode & RadarRouteModeTruck) {
        [modes addObject:@"truck"];
    }
    if (mode & RadarRouteModeMotorbike) {
        [modes addObject:@"motorbike"];
    }
    if (modes.count == 0) {
        return @"unknown";
    }
    return [modes componentsJoinedByString:@","];
}

@end