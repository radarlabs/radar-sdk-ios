//
//  RadarUserInsightsState.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarUserInsightsState.h"
#import "RadarCollectionAdditions.h"
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

    BOOL home = [userInsightsStateDict radar_boolForKey:@"home"];
    BOOL office = [userInsightsStateDict radar_boolForKey:@"office"];
    BOOL traveling = [userInsightsStateDict radar_boolForKey:@"traveling"];
    BOOL commuting = [userInsightsStateDict radar_boolForKey:@"commuting"];

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
