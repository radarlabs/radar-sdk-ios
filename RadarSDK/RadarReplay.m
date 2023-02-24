//
//  RadarReplay.m
//  RadarSDK
//
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import "RadarReplay.h"

@implementation RadarReplay

- (instancetype)initWithParams:(NSDictionary *)replayParams {
    self = [super init];
    if (self) {
        _replayParams = replayParams;
    }
    return self;
}

+ (NSMutableArray<NSDictionary *> *)arrayForReplays:(NSArray<RadarReplay *> *)replays {
    if (!replays) {
        return nil;
    }

    NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:replays.count];
    for (RadarReplay *replay in replays) {
        [arr addObject:replay.replayParams];
    }
    return arr;
}

@end
