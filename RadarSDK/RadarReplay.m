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

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _replayParams = [coder decodeObjectForKey:@"replayParams"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.replayParams forKey:@"replayParams"];
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

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[RadarReplay class]]) {
        return NO;
    }

    return [self.replayParams isEqual:((RadarReplay *)object).replayParams];
}

- (NSUInteger)hash {
    return [self.replayParams hash];
}

@end
