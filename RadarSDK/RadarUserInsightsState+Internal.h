//
//  RadarUserInsightsState+Internal.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RadarUserInsightsState ()

- (instancetype _Nullable)initWithHome:(BOOL)home office:(BOOL)office traveling:(BOOL)traveling commuting:(BOOL)commuting;
- (instancetype _Nullable)initWithObject:(id _Nonnull)object;

@end
