//
//  RadarFraud+Internal.h
//  RadarSDK
//
//  Copyright © 2021 Radar Labs, Inc. All rights reserved.
//

#if __has_include(<RadarSDK/RadarSDK-Swift.h>)
#import <RadarSDK/RadarSDK-Swift.h>
#elif __has_include("RadarSDK-Swift.h")
#import "RadarSDK-Swift.h"
#endif

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
                                blocked:(BOOL)blocked;

- (instancetype _Nullable)initWithObject:(id _Nonnull)object;

@end

NS_ASSUME_NONNULL_END
