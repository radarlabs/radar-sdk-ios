//
//  RadarFraud.m
//  RadarSDK
//
//  Copyright © 2021 Radar Labs, Inc. All rights reserved.
//

#import "RadarFraud.h"
#import "RadarUtils.h"

@implementation RadarFraud

- (instancetype _Nonnull)initWithPassed:(BOOL)passed
                               bypassed:(BOOL)bypassed
                               verified:(BOOL)verified
                                  proxy:(BOOL)proxy
                                 mocked:(BOOL)mocked
                            compromised:(BOOL)compromised
                                 jumped:(BOOL)jumped
                             inaccurate:(BOOL)inaccurate
                                sharing:(BOOL)sharing
                                blocked:(BOOL)blocked
                           lastMockedAt:(NSDate *)lastMockedAt
                           lastJumpedAt:(NSDate *)lastJumpedAt
                      lastCompromisedAt:(NSDate *)lastCompromisedAt
                       lastInaccurateAt:(NSDate *)lastInaccurateAt
                            lastProxyAt:(NSDate *)lastProxyAt
                          lastSharingAt:(NSDate *)lastSharingAt {
    _passed = passed;
    _bypassed = bypassed;
    _verified = verified;
    _proxy = proxy;
    _mocked = mocked;
    _compromised = compromised;
    _jumped = jumped;
    _inaccurate = inaccurate;
    _sharing = sharing;
    _blocked = blocked;
    _lastMockedAt = lastMockedAt;
    _lastJumpedAt = lastJumpedAt;
    _lastCompromisedAt = lastCompromisedAt;
    _lastInaccurateAt = lastInaccurateAt;
    _lastProxyAt = lastProxyAt;
    _lastSharingAt = lastSharingAt;

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
    _inaccurate = [self asBool:dict[@"inaccurate"]];
    _sharing = [self asBool:dict[@"sharing"]];
    _blocked = [self asBool:dict[@"blocked"]];

    id lastMockedAtObj = dict[@"lastMockedAt"];
    if (lastMockedAtObj && [lastMockedAtObj isKindOfClass:[NSString class]]) {
        _lastMockedAt = [RadarUtils.isoDateFormatter dateFromString:(NSString *)lastMockedAt];
    }
    id lastJumpedAtObj = dict[@"lastJumpedAt"];
    if (lastJumpedAtObj && [lastJumpedAtObj isKindOfClass:[NSString class]]) {
        _lastJumpedAt = [RadarUtils.isoDateFormatter dateFromString:(NSString *)lastJumpedAt];
    }
    id lastCompromisedAtObj = dict[@"lastCompromisedAt"];
    if (lastCompromisedAtObj && [lastCompromisedAtObj isKindOfClass:[NSString class]]) {
        _lastCompromisedAt = [RadarUtils.isoDateFormatter dateFromString:(NSString *)lastCompromisedAt];
    }
    id lastInaccurateAtObj = dict[@"lastInaccurateAt"];
    if (lastInaccurateAtObj && [lastInaccurateAtObj isKindOfClass:[NSString class]]) {
        _lastInaccurateAt = [RadarUtils.isoDateFormatter dateFromString:(NSString *)lastInaccurateAt];
    }
    id lastProxyAtObj = dict[@"lastProxyAt"];
    if (lastProxyAtObj && [lastProxyAtObj isKindOfClass:[NSString class]]) {
        _lastProxyAt = [RadarUtils.isoDateFormatter dateFromString:(NSString *)lastProxyAt];
    }
    id lastSharingAtObj = dict[@"lastSharingAt"];
    if (lastSharingAtObj && [lastSharingAtObj isKindOfClass:[NSString class]]) {
        _lastSharingAt = [RadarUtils.isoDateFormatter dateFromString:(NSString *)lastSharingAt];
    }

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
        @"jumped": @(self.jumped),
        @"inaccurate": @(self.inaccurate),
        @"sharing": @(self.sharing),
        @"blocked": @(self.blocked),
        @"lastMockedAt": @([RadarUtils.isoDateFormatter stringFromDate:self.lastMockedAt]),
        @"lastJumpedAt": @([RadarUtils.isoDateFormatter stringFromDate:self.lastJumpedAt]),
        @"lastCompromisedAt": @([RadarUtils.isoDateFormatter stringFromDate:self.lastCompromisedAt]),
        @"lastInaccurateAt": @([RadarUtils.isoDateFormatter stringFromDate:self.lastInaccurateAt]),
        @"lastProxyAt": @([RadarUtils.isoDateFormatter stringFromDate:self.lastProxyAt]),
        @"lastSharingAt": @([RadarUtils.isoDateFormatter stringFromDate:self.lastSharingAt]),
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
