//
//  RadarAddressPlace.m
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import "RadarAutocompleteEnrichedAddress+Internal.h"

@implementation RadarAddressPlace

- (instancetype _Nullable)initWithObject:(id _Nonnull)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *dict = (NSDictionary *)object;

    self = [super init];
    if (self) {
        id nameObj = dict[@"name"];
        _name = [nameObj isKindOfClass:[NSString class]] ? (NSString *)nameObj : @"";

        NSMutableArray<NSString *> *categories = [NSMutableArray array];
        id categoriesObj = dict[@"categories"];
        if ([categoriesObj isKindOfClass:[NSArray class]]) {
            for (id category in (NSArray *)categoriesObj) {
                if ([category isKindOfClass:[NSString class]]) {
                    [categories addObject:(NSString *)category];
                }
            }
        }
        _categories = [categories copy];
    }
    return self;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setValue:self.name forKey:@"name"];
    [dict setValue:self.categories forKey:@"categories"];
    return dict;
}

@end
