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

- (instancetype _Nullable)initWithHomeLocation:(RadarUserInsightsLocation *)homeLocation officeLocation:(RadarUserInsightsLocation *)officeLocation state:(RadarUserInsightsState *)state {
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
    
    NSDictionary *userInsightsDict = (NSDictionary *)object;
    
    RadarUserInsightsLocation *homeLocation;
    RadarUserInsightsLocation *officeLocation;
    RadarUserInsightsState *state;
    
    id userInsightsLocationsObj = userInsightsDict[@"locations"];
    if (userInsightsLocationsObj && [userInsightsLocationsObj isKindOfClass:[NSArray class]]) {
        NSArray *userInsightsLocationsArr = (NSArray *)userInsightsLocationsObj;
        for (id userInsightsLocationObj in userInsightsLocationsArr) {
            RadarUserInsightsLocation *userInsightsLocation = [[RadarUserInsightsLocation alloc] initWithObject:userInsightsLocationObj];
            if (!userInsightsLocation)
                return nil;
            
            if (userInsightsLocation.type == RadarUserInsightsLocationTypeHome)
                homeLocation = userInsightsLocation;
            else if (userInsightsLocation.type == RadarUserInsightsLocationTypeOffice)
                officeLocation = userInsightsLocation;
        }
    }
    
    id userInsightsStateObj = userInsightsDict[@"state"];
    if (userInsightsLocationsObj && [userInsightsLocationsObj isKindOfClass:[NSArray class]]) {
        state = [[RadarUserInsightsState alloc] initWithObject:userInsightsStateObj];
    }
    
    if (homeLocation && officeLocation && state) {
        return [[RadarUserInsights alloc] initWithHomeLocation:homeLocation officeLocation:officeLocation state:state];
    }
    
    return nil;
}

@end
