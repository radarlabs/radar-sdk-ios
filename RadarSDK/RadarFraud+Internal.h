//
//  RadarFraud+Internal.h
//  RadarSDK
//
//  Copyright © 2021 Radar Labs, Inc. All rights reserved.
//

#import "RadarFraud+Internal.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarFraud ()

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
                          lastSharingAt:(NSDate *)lastSharingAt;

- (instancetype _Nullable)initWithObject:(id _Nonnull)object;

@end

NS_ASSUME_NONNULL_END
