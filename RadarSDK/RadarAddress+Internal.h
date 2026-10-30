//
//  RadarAddress+Internal.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "Radar.h"
#import <Foundation/Foundation.h>

#if __has_include(<RadarSDK/RadarSDK-Swift.h>)
#import <RadarSDK/RadarSDK-Swift.h>
#elif __has_include("RadarSDK-Swift.h")
#import "RadarSDK-Swift.h"
#endif

@interface RadarAddress ()

+ (NSArray<RadarAddress *> *_Nullable)addressesFromObject:(id _Nonnull)object;

+ (RadarAddressVerificationStatus)addressVerificationStatusForString:(NSString *_Nullable)string;

- (instancetype _Nullable)initWithObject:(id _Nonnull)object;

@end
