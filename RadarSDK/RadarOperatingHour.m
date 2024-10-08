//
//  RadarOperatingHour.m
//  RadarSDK
//
//  Created by Kenny Hu on 10/7/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RadarOperatingHour+Internal.h"

@implementation RadarOperatingHour

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        NSMutableDictionary *parsedHours = [NSMutableDictionary new];
        
        for (NSString *key in dictionary) {
            id value = dictionary[key];
            
            if ([value isKindOfClass:[NSArray class]]) {
                NSArray *dayPairs = (NSArray *)value;
                NSMutableArray *parsedDayPairs = [NSMutableArray new];
                
                for (id pair in dayPairs) {
                    if ([pair isKindOfClass:[NSArray class]] && [pair count] == 2) {
                        NSString *start = pair[0];
                        NSString *end = pair[1];
                        
                        if ([start isKindOfClass:[NSString class]] && [end isKindOfClass:[NSString class]]) {
                            [parsedDayPairs addObject:@[start, end]];
                        }
                    }
                }
                
                parsedHours[key] = [parsedDayPairs copy];
            }
        }
        
        _hours = [parsedHours copy];
    }
    return self;
}

@end
