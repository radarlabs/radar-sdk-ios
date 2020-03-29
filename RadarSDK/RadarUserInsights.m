//
//  RadarUserInsights.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarUserInsights.h"
#import "RadarUserInsights+Internal.h"
#import "RadarUserInsightsLocation+Internal.h"
#import "RadarUserInsightsState+Internal.h"

@implementation RadarUserInsights

- (instancetype _Nullable)initWithHomeLocation:(RadarUserInsightsLocation *)homeLocation
                                officeLocation:(RadarUserInsightsLocation *)officeLocation
                                         state:(RadarUserInsightsState *)state {
    self = [super init];
    if (self) {
        _homeLocation = homeLocation;
        _officeLocation = officeLocation;
        _state = state;
    }
    return self;
}

- (instancetype _Nullable)initWithObject:(id)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *dict = (NSDictionary *)object;

    RadarUserInsightsLocation *homeLocation;
    RadarUserInsightsLocation *officeLocation;
    RadarUserInsightsState *state;

    id locationsObj = dict[@"locations"];
    if (locationsObj && [locationsObj isKindOfClass:[NSArray class]]) {
        NSArray *userInsightsLocationsArr = (NSArray *)locationsObj;
        for (id locationObj in userInsightsLocationsArr) {
            RadarUserInsightsLocation *location = [[RadarUserInsightsLocation alloc] initWithObject:locationObj];
            if (!location) {
                return nil;
            }

            if (location.type == RadarUserInsightsLocationTypeHome) {
                homeLocation = location;
            } else if (location.type == RadarUserInsightsLocationTypeOffice) {
                officeLocation = location;
            }
        }
    }

    id stateObj = dict[@"state"];
    if (locationsObj && [locationsObj isKindOfClass:[NSArray class]]) {
        state = [[RadarUserInsightsState alloc] initWithObject:stateObj];
    }

    if (homeLocation && officeLocation && state) {
        return [[RadarUserInsights alloc] initWithHomeLocation:homeLocation officeLocation:officeLocation state:state];
    }

    return nil;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    if (self.homeLocation) {
        NSDictionary *homeLocationDict = [self.homeLocation dictionaryValue];
        [dict setObject:homeLocationDict forKey:@"homeLocation"];
    }
    if (self.officeLocation) {
        NSDictionary *officeLocationDict = [self.officeLocation dictionaryValue];
        [dict setObject:officeLocationDict forKey:@"officeLocation"];
    }
    if (self.state) {
        NSDictionary *stateDict = [self.state dictionaryValue];
        [dict setObject:stateDict forKey:@"state"];
    }
    return dict;
}

@end
