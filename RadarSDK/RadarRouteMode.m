#import "RadarRouteMode.h"

@implementation RadarRouteMode

+ (NSString *)stringForMode:(RadarRouteMode)mode {
    NSString *str;
    switch (mode) {
        case RadarRouteModeFoot:
            str = @"foot";
            break;
        case RadarRouteModeBike:
            str = @"bike";
            break;
        case RadarRouteModeCar:
            str = @"car";
            break;
        case RadarRouteModeTruck:
            str = @"truck";
            break;
        case RadarRouteModeMotorbike:
            str = @"motorbike";
            break;
    }
    return str;
}

@end