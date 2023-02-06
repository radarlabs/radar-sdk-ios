//
//  RadarReplay.h
//  RadarSDK
//
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import "Radar.h"


/**
 Represents a request to be replayed
 */
@interface RadarReplay : NSObject

/**
 The params of a request that failed due to a network error
 */

@property (nonnull, copy, nonatomic, readonly) NSDictionary *replayParams;

// 2d: determine if this is the right way of setting params
- (instancetype _Nullable)initWithParams:(NSDictionary *_Nullable) replayParams;

+ (NSMutableArray<NSDictionary *> *_Nullable)arrayForReplays:(NSArray<RadarReplay *> *_Nullable)replays;

@end


