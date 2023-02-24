//
//  RadarFraud.m
//  RadarSDK
//
//  Copyright © 2021 Radar Labs, Inc. All rights reserved.
//

#import "RadarFraud.h"

@implementation RadarFraud

- (instancetype _Nonnull)initWithPassed:(BOOL)passed bypassed:(BOOL)bypassed verified:(BOOL)verified proxy:(BOOL)proxy mocked:(BOOL)mocked compromised:(BOOL)compromised jumped:(BOOL)jumped {
    _passed = passed;
    _bypassed = bypassed;
    _verified = verified;
    _proxy = proxy;
    _mocked = mocked;
    _compromised = compromised;
    _jumped = jumped;

    return self;
}

- (instancetype _Nullable)initWithObject:(id)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *dict = (NSDictionary *)object;

    _passed = [self asBool:dict[@"passed"]];
    _bypassed = [self asBool:dict[@"bypassed"]];
    _verified = [self asBool:dict[@"verified"]];
    _proxy = [self asBool:dict[@"proxy"]];
    _mocked = [self asBool:dict[@"mocked"]];
    _compromised = [self asBool:dict[@"compromised"]];
    _jumped = [self asBool:dict[@"jumped"]];

    return self;
}

- (NSDictionary *)dictionaryValue {
    return @{
        @"passed": @(self.passed),
        @"bypassed": @(self.bypassed),
        @"verified": @(self.verified),
        @"proxy": @(self.proxy),
        @"mocked": @(self.mocked),
        @"compromised": @(self.compromised),
        @"jumped": @(self.jumped)
    };
}

- (BOOL)asBool:(NSObject *)object {
    if (object && [object isKindOfClass:[NSNumber class]]) {
        NSNumber *number = (NSNumber *)object;

        return [number boolValue];
    } else {
        return false;
    }
}

@end
