//
//  RadarAddressLocationDetails.m
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import "RadarAutocompleteEnrichedAddress+Internal.h"

// The server fills every field before the payload leaves it, so these only stand in for a malformed response.
static NSString *const kRadarAddressLocationDetailsUnknown = @"unknown";

@implementation RadarAddressLocationDetails

- (instancetype _Nullable)initWithObject:(id _Nullable)object {
    NSDictionary *dict = [object isKindOfClass:[NSDictionary class]] ? (NSDictionary *)object : @{};

    self = [super init];
    if (self) {
        id usageObj = dict[@"usage"];
        _usage = [usageObj isKindOfClass:[NSString class]] ? (NSString *)usageObj : kRadarAddressLocationDetailsUnknown;

        id dwellingObj = dict[@"dwelling"];
        _dwelling = [dwellingObj isKindOfClass:[NSString class]] ? (NSString *)dwellingObj : kRadarAddressLocationDetailsUnknown;

        NSMutableArray<NSString *> *grounds = [NSMutableArray array];
        id groundsObj = dict[@"grounds"];
        if ([groundsObj isKindOfClass:[NSArray class]]) {
            for (id ground in (NSArray *)groundsObj) {
                if ([ground isKindOfClass:[NSString class]]) {
                    [grounds addObject:(NSString *)ground];
                }
            }
        }
        _grounds = [grounds copy];

        NSMutableArray<RadarAddressPlace *> *places = [NSMutableArray array];
        id placesObj = dict[@"places"];
        if ([placesObj isKindOfClass:[NSArray class]]) {
            for (id placeObj in (NSArray *)placesObj) {
                RadarAddressPlace *place = [[RadarAddressPlace alloc] initWithObject:placeObj];
                if (place) {
                    [places addObject:place];
                }
            }
        }
        _places = [places copy];
    }
    return self;
}

- (NSDictionary *)dictionaryValue {
    NSMutableArray<NSDictionary *> *places = [NSMutableArray arrayWithCapacity:self.places.count];
    for (RadarAddressPlace *place in self.places) {
        [places addObject:[place dictionaryValue]];
    }

    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setValue:self.usage forKey:@"usage"];
    [dict setValue:self.dwelling forKey:@"dwelling"];
    [dict setValue:self.grounds forKey:@"grounds"];
    [dict setValue:places forKey:@"places"];
    return dict;
}

@end
