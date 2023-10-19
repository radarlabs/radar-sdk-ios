//
//  RadarReplay.h
//  RadarSDK
//
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import "Radar.h"

@interface RadarReplay : NSObject<NSCoding>

@property (nonnull, copy, nonatomic, readonly) NSDictionary *replayParams;

- (instancetype _Nullable)initWithParams:(NSDictionary *_Nullable)replayParams;

+ (NSMutableArray<NSDictionary *> *_Nullable)arrayForReplays:(NSArray<RadarReplay *> *_Nullable)replays;

@end
