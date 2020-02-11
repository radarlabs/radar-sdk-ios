//
//  RadarUserInsightsState.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarUserInsightsState.h"
#import "RadarUserInsightsState+Internal.h"

@implementation RadarUserInsightsState

- (instancetype _Nullable)initWithHome:(BOOL)home office:(BOOL)office traveling:(BOOL)traveling commuting:(BOOL)commuting {
    self = [super init];
    if (self) {
        _home = home;
        _office = office;
        _traveling = traveling;
        _commuting = commuting;
    }
    return self;
}

- (instancetype _Nullable)initWithObject:(id)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    NSDictionary *userInsightsStateDict = (NSDictionary *)object;
    
    BOOL userInsightsStateHome = NO;
    BOOL userInsightsStateOffice = NO;
    BOOL userInsightsStateTraveling = NO;
    BOOL userInsightsStateCommuting = NO;
    
    id userInsightsStateHomeObj = userInsightsStateDict[@"home"];
    if ([userInsightsStateHomeObj isKindOfClass:[NSNumber class]]) {
        userInsightsStateHome = [(NSNumber *)userInsightsStateHomeObj boolValue];
    }
    
    id userInsightsStateOfficeObj = userInsightsStateDict[@"office"];
    if ([userInsightsStateOfficeObj isKindOfClass:[NSNumber class]]) {
        userInsightsStateOffice = [(NSNumber *)userInsightsStateOfficeObj boolValue];
    }
         
    id userInsightsStateTravelingObj = userInsightsStateDict[@"traveling"];
    if ([userInsightsStateTravelingObj isKindOfClass:[NSNumber class]]) {
        userInsightsStateTraveling = [(NSNumber *)userInsightsStateTravelingObj boolValue];
    }
    
    id userInsightsStateCommutingObj = userInsightsStateDict[@"commuting"];
    if ([userInsightsStateCommutingObj isKindOfClass:[NSNumber class]]) {
        userInsightsStateCommuting = [(NSNumber *)userInsightsStateCommutingObj boolValue];
    }
    
    return [[RadarUserInsightsState alloc] initWithHome:userInsightsStateHome office:userInsightsStateOffice traveling:userInsightsStateTraveling commuting:userInsightsStateCommuting];
}

@end
