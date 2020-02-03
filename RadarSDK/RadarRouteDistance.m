//
//  RadarRouteDistance.m
//  RadarSDKTests
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "RadarRouteDistance.h"

@implementation RadarRouteDistance

- (instancetype)initWithValue:(double)value
                         text:(nonnull NSString *)text {
    self = [super init];
    if (self) {
        _value = value;
        _text = text;
    }
    return self;
}

- (nullable instancetype)initWithObject:(nullable id)object {
    if (![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    NSDictionary *durationDict = (NSDictionary *)object;

    double value = 0;
    NSString *text = @"";
    
    id valueObj = durationDict[@"value"];
    if ([valueObj isKindOfClass:[NSNumber class]]) {
        value = ((NSNumber *)valueObj).doubleValue;
    }

    id textObj = durationDict[@"text"];
    if ([textObj isKindOfClass:[NSString class]]) {
        text = (NSString *)textObj;
    }
    
    return [[RadarRouteDistance alloc] initWithValue:value text:text];
}

@end
