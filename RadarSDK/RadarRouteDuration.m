//
//  RadarRouteDuration.m
//  RadarSDK
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "RadarRouteDuration.h"
#import "RadarCollectionAdditions.h"

@implementation RadarRouteDuration

- (instancetype)initWithValue:(double)value text:(nonnull NSString *)text {
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

    NSDictionary *dict = (NSDictionary *)object;

    NSNumber *valueNumber = [dict radar_numberForKey:@"value"];
    double value = valueNumber ? [valueNumber doubleValue] : 0;

    NSString *text = [dict radar_stringForKey:@"text"];

    if (text) {
        return [[RadarRouteDuration alloc] initWithValue:value text:text];
    }

    return nil;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setValue:@(self.value) forKey:@"value"];
    [dict setValue:self.text forKey:@"text"];
    return dict;
}

@end
