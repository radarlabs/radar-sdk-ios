//
//  RadarChain+Internal.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarChain.h"
#import "RadarJSONCoding.h"
#import <Foundation/Foundation.h>

@interface RadarChain ()<RadarJSONCoding>

+ (NSArray<RadarChain *> *_Nullable)chainsFromObject:(id _Nonnull)object;

- (instancetype _Nullable)initWithSlug:(NSString *_Nonnull)slug name:(NSString *_Nonnull)name externalId:(NSString *_Nullable)externalId metadata:(nullable NSDictionary *)metadata;

@end
