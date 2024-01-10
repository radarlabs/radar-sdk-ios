//
//  RadarReplayBuffer.m
//  RadarSDK
//
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import "Radar+Internal.h"
#import "RadarAPIClient.h"
#import "RadarReplayBuffer.h"
#import "RadarReplay.h"
#import "RadarLogger.h"
#import "RadarSettings.h"
#import "RadarKVStore.h"

static const int MAX_BUFFER_SIZE = 120; // one hour of updates
static NSString *const kReplayBuffer = @"radar-replays";

@implementation RadarReplayBuffer {
    NSMutableArray<RadarReplay *> *mutableReplayBuffer;
    BOOL isFlushing;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        mutableReplayBuffer = [NSMutableArray<RadarReplay *> new];
        isFlushing = NO;
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

+ (void)migrateToRadarKVStore {
    NSData *replaysData = [[NSUserDefaults standardUserDefaults] objectForKey:kReplayBuffer];
    if (replaysData) {
        NSArray *replays = [NSKeyedUnarchiver unarchiveObjectWithData:replaysData];
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Migrating replays with length %lu", (unsigned long)[replays count]]];
        [[RadarKVStore sharedInstance] setObject:replays forKey:kReplayBuffer];
    } else {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"No replays to migrate"];
    }
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

        // If buffer length is above 50, remove every fifth replay from the persisted buffer 
        if ([mutableReplayBuffer count] > 50) {
            NSMutableArray<RadarReplay *> *prunedBuffer = [NSMutableArray arrayWithCapacity:[mutableReplayBuffer count]];
            for (NSUInteger i = 0; i < mutableReplayBuffer.count; i++) {
                if ((i + 1) % 5 != 0) {
                    [prunedBuffer addObject:mutableReplayBuffer[i]];
                }
            }
            [[RadarKVStore sharedInstance] setObject:prunedBuffer forKey:kReplayBuffer];
        } else {
            [[RadarKVStore sharedInstance] setObject:mutableReplayBuffer forKey:kReplayBuffer];
        }

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
* Flushes the replay in the buffer
*/
- (void)flushReplaysWithCompletionHandler:(NSDictionary *_Nullable)replayParams
                        completionHandler:(RadarFlushReplaysCompletionHandler _Nullable)completionHandler {
    if (isFlushing) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Already flushing replays"];
        if (completionHandler) {
            completionHandler(RadarStatusErrorServer, nil);
        }
        return;
    }

    isFlushing = YES;

    NSArray<RadarReplay *> *flushableReplays = [self flushableReplays];
    if ([flushableReplays count] == 0 && !replayParams) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"No replays to flush"];
        isFlushing = NO;
        if (completionHandler) {
            completionHandler(RadarStatusSuccess, nil);
        }
        return;
    }

    // get a copy of the replays so we can safely clear what was synced up
    NSMutableArray<RadarReplay *> *replaysArray = [NSMutableArray arrayWithArray:flushableReplays];
    
    NSMutableArray *replaysRequestArray = [RadarReplay arrayForReplays:replaysArray];

    // if we have a current track update, add it to the local replay list
    NSMutableDictionary *newReplayParams;
    if (replayParams) {
        newReplayParams = [replayParams mutableCopy];
        newReplayParams[@"replayed"] = @(YES);
        long nowMs = (long)([NSDate date].timeIntervalSince1970 * 1000);
        newReplayParams[@"updatedAtMs"] = @(nowMs);
        // remove the updatedAtMsDiff key because for replays we want to rely on the updatedAtMs key for the time instead
        [newReplayParams removeObjectForKey:@"updatedAtMsDiff"];
        [replaysRequestArray addObject:newReplayParams];
    }

    // log the replay count
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Flushing %lu replays", (unsigned long)[replaysRequestArray count]]];

    [[RadarAPIClient sharedInstance] flushReplays:replaysRequestArray completionHandler:^(RadarStatus status, NSDictionary *_Nullable res) {
        if (status == RadarStatusSuccess) {
            // if the flush was successful, remove the replays from the buffer
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Flushed replays successfully"];
            [self removeReplaysFromBuffer:replaysArray];
            [Radar flushLogs];

        } else {
            if (replayParams) {
                [self writeNewReplayToBuffer:newReplayParams];
            }
        }

        [self setIsFlushing:NO];
        if (completionHandler) {
            completionHandler(status, res);
        }
    }];
}

// Set is Flushing from outside
- (void)setIsFlushing:(BOOL)flushing {
    isFlushing = flushing;
}

/**
 * Clears the buffer out
 */
- (void)clearBuffer {
    [mutableReplayBuffer removeAllObjects];

    // remove persisted replays
    [[RadarKVStore sharedInstance] removeObjectForKey:kReplayBuffer];
}

- (void)removeReplaysFromBuffer:(NSArray<RadarReplay *> *)replays {
    [mutableReplayBuffer removeObjectsInArray:replays];

    // persist the updated buffer
    [[RadarKVStore sharedInstance] setObject:mutableReplayBuffer forKey:kReplayBuffer];
}

- (void)loadReplaysFromPersistentStore {
    NSObject *replayObject = [[RadarKVStore sharedInstance] objectForKey:kReplayBuffer];
    if (replayObject && [replayObject isKindOfClass:[NSArray class]]) {
        NSArray *replays = (NSArray *)replayObject;
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
