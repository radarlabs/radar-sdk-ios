//
//  RadarChain+Internal.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __has_include(<RadarSDK/RadarSDK-Swift.h>)
#import <RadarSDK/RadarSDK-Swift.h>
#elif __has_include("RadarSDK-Swift.h")
#import "RadarSDK-Swift.h"
#endif

@interface RadarChain ()

- (instancetype _Nullable)initWithSlug:(NSString *_Nonnull)slug name:(NSString *_Nonnull)name externalId:(NSString *_Nullable)externalId metadata:(nullable NSDictionary *)metadata;
- (instancetype _Nullable)initWithObject:(id _Nonnull)object;

@end
