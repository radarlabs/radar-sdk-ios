//
//  RadarReplayBuffer.h
//  RadarSDK
//
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RadarReplay.h"

// 2d: figure out what this means
NS_ASSUME_NONNULL_BEGIN

@interface RadarReplayBuffer : NSObject

@property (assign, nonatomic, readonly) NSArray<RadarReplay *> *flushableReplays;

+ (instancetype)sharedInstance;

- (void)writeNewReplayToBuffer:(NSMutableDictionary* )replayParams;

- (void)dropOldestReplay;

- (void)clearBuffer;

@end
NS_ASSUME_NONNULL_END
