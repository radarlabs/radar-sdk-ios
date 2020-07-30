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

    NSNumber *homeNumber = [userInsightsStateDict radar_numberForKey:@"home"];
    BOOL home = homeNumber ? [homeNumber boolValue] : NO;

    NSNumber *officeNumber = [userInsightsStateDict radar_numberForKey:@"office"];
    BOOL office = officeNumber ? [officeNumber boolValue] : NO;

    NSNumber *travelingNumber = [userInsightsStateDict radar_numberForKey:@"traveling"];
    BOOL traveling = travelingNumber ? [travelingNumber boolValue] : NO;

    NSNumber *commutingNumber = [userInsightsStateDict radar_numberForKey:@"commuting"];
    BOOL commuting = commutingNumber ? [commutingNumber boolValue] : NO;

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
