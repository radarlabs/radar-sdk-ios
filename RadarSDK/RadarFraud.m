//
//  RadarFraud.m
//  RadarSDK
//
//  Copyright © 2021 Radar Labs, Inc. All rights reserved.
//

#import "RadarFraud.h"

@implementation RadarFraud

- (instancetype _Nonnull)initWithProxy:(bool)proxy
                                mocked:(bool)mocked {
    _proxy = proxy;
    _mocked = mocked;
    
    return self;
}

- (instancetype _Nullable)initWithObject:(id)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *dict = (NSDictionary *)object;

    _proxy = [self asBool:dict[@"proxy"]];
    _mocked = [self asBool:dict[@"mocked"]];

    return self;
}

- (NSDictionary *)dictionaryValue {
    return @{@"proxy": @(self.proxy), @"mocked": @(self.mocked)};
}

- (bool)asBool:(NSObject *)object {
    if (object && [object isKindOfClass:[NSNumber class]]) {
        NSNumber *number = (NSNumber *)object;

        return [number boolValue];
    } else {
        return false;
    }
}

@end
