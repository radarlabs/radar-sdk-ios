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

    BOOL home = NO;
    BOOL office = NO;
    BOOL traveling = NO;
    BOOL commuting = NO;

    id homeObj = userInsightsStateDict[@"home"];
    if ([homeObj isKindOfClass:[NSNumber class]]) {
        home = [(NSNumber *)homeObj boolValue];
    }

    id officeObj = userInsightsStateDict[@"office"];
    if ([officeObj isKindOfClass:[NSNumber class]]) {
        office = [(NSNumber *)officeObj boolValue];
    }

    id travelingObj = userInsightsStateDict[@"traveling"];
    if ([travelingObj isKindOfClass:[NSNumber class]]) {
        traveling = [(NSNumber *)travelingObj boolValue];
    }

    id commutingObj = userInsightsStateDict[@"commuting"];
    if ([commutingObj isKindOfClass:[NSNumber class]]) {
        commuting = [(NSNumber *)commutingObj boolValue];
    }

    return [[RadarUserInsightsState alloc] initWithHome:home office:office traveling:traveling commuting:commuting];
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setValue:@(self.home) forKey:@"home"];
    [dict setValue:@(self.office) forKey:@"office"];
    [dict setValue:@(self.traveling) forKey:@"traveling"];
    [dict setValue:@(self.commuting) forKey:@"commuting"];
    return dict;
}

@end
