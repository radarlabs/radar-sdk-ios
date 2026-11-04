//
//  RadarExpectedAddress+Internal.h
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#if __has_include(<RadarSDK/RadarSDK-Swift.h>)
#import <RadarSDK/RadarSDK-Swift.h>
#elif __has_include("RadarSDK-Swift.h")
#import "RadarSDK-Swift.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface RadarExpectedAddress ()

- (instancetype _Nullable)initWithObject:(id _Nonnull)object;

@end

NS_ASSUME_NONNULL_END
