//
//  RadarReplayBuffer.m
//  RadarSDK
//
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import "RadarReplayBuffer.h"
#import "RadarReplay.h"
#import "RadarLogger.h"
#import "RadarSettings.h"

static const int MAX_BUFFER_SIZE = 120; // one hour of updates

@implementation RadarReplayBuffer {
    NSMutableArray<RadarReplay *> *mutableReplayBuffer;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        mutableReplayBuffer = [NSMutableArray<RadarReplay *> new];
    }
    return self;
}

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

/**
 * Takes a dictionary of replay params and adds it as a replay to the buffer
 */
- (void)writeNewReplayToBuffer:(NSMutableDictionary *)replayParams {
    NSUInteger replayBufferLength = [mutableReplayBuffer count];
    if (replayBufferLength >= MAX_BUFFER_SIZE) {
        [self dropOldestReplay];
    }
    // add new replay to buffer
    RadarReplay *radarReplay = [[RadarReplay alloc] initWithParams:replayParams];
    [mutableReplayBuffer addObject:radarReplay];

    RadarFeatureSettings *featureSettings = [RadarSettings featureSettings];
    if (featureSettings.usePersistence) {
        NSData *replaysData;

        // If buffer length is above 50, remove every fifth replay from the persisted buffer 
        if ([mutableReplayBuffer count] > 50) {
            NSMutableArray<RadarReplay *> *prunedBuffer = [NSMutableArray arrayWithCapacity:[mutableReplayBuffer count]];
            for (NSUInteger i = 0; i < mutableReplayBuffer.count; i++) {
                if ((i + 1) % 5 != 0) {
                    [prunedBuffer addObject:mutableReplayBuffer[i]];
                }
            }
            replaysData = [NSKeyedArchiver archivedDataWithRootObject:prunedBuffer];
        } else {
            replaysData = [NSKeyedArchiver archivedDataWithRootObject:mutableReplayBuffer];
        }

        [[NSUserDefaults standardUserDefaults] setObject:replaysData forKey:@"radar-replays"];
    }
}

/**
 * Return copy of replays in buffer
 */
- (NSArray<RadarReplay *> *)flushableReplays {
    NSArray *flushableReplays = [mutableReplayBuffer copy];
    return flushableReplays;
}

/**
 * Clears the buffer out
 */
- (void)clearBuffer {
    [mutableReplayBuffer removeAllObjects];

    // remove persisted replays
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"radar-replays"];
}

- (void)loadReplaysFromPersistentStore {
    NSData *replaysData = [[NSUserDefaults standardUserDefaults] objectForKey:@"radar-replays"];
    if (replaysData) {
        NSArray *replays = [NSKeyedUnarchiver unarchiveObjectWithData:replaysData];
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Loaded replays with length %lu", (unsigned long)[replays count]]];
        mutableReplayBuffer = [NSMutableArray arrayWithArray:replays];
    }
}

/**
 * Drops the oldest replay from the buffer
 */
- (void)dropOldestReplay {
    [mutableReplayBuffer removeObjectsInRange:NSMakeRange(0, 1)];
}

@end
