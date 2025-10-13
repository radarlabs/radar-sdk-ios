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

static const int MAX_BUFFER_SIZE = 120; // one hour of updates
static const int MAX_BATCH_SIZE = 100;

@implementation RadarReplayBuffer {
    NSMutableArray<RadarReplay *> *mutableReplayBuffer;
    BOOL isFlushing;
    NSTimer *batchFlushTimer;
    NSDate *batchStartTime;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        mutableReplayBuffer = [NSMutableArray<RadarReplay *> new];
        isFlushing = NO;
        batchFlushTimer = nil;
        batchStartTime = nil;
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

#pragma mark - Replay Buffer Methods

- (void)writeNewReplayToBuffer:(NSMutableDictionary *)replayParams {
    NSUInteger replayBufferLength = [mutableReplayBuffer count];
    if (replayBufferLength >= MAX_BUFFER_SIZE) {
        [self dropOldestReplay];
    }
    
    // add new replay to buffer
    RadarReplay *radarReplay = [[RadarReplay alloc] initWithParams:replayParams];
    [mutableReplayBuffer addObject:radarReplay];

    RadarSdkConfiguration *sdkConfiguration = [RadarSettings sdkConfiguration];
    if (sdkConfiguration.usePersistence) {
        NSData *replaysData;
        NSError *error;

        // if buffer length is above 50, remove every fifth replay from the persisted buffer
        if ([mutableReplayBuffer count] > 50) {
            NSMutableArray<RadarReplay *> *prunedBuffer = [NSMutableArray arrayWithCapacity:[mutableReplayBuffer count]];
            for (NSUInteger i = 0; i < mutableReplayBuffer.count; i++) {
                if ((i + 1) % 5 != 0) {
                    [prunedBuffer addObject:mutableReplayBuffer[i]];
                }
            }
            replaysData = [NSKeyedArchiver archivedDataWithRootObject:prunedBuffer requiringSecureCoding:YES error:&error];
        } else {
            replaysData = [NSKeyedArchiver archivedDataWithRootObject:mutableReplayBuffer requiringSecureCoding:YES error:&error];
        }
        if (error) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Error archiving replays"]; 
            return;
        } else {
            [[NSUserDefaults standardUserDefaults] setObject:replaysData forKey:@"radar-replays"];
        }
    }
}

- (NSArray<RadarReplay *> *)flushableReplays {
    NSArray *flushableReplays = [mutableReplayBuffer copy];
    return flushableReplays;
}

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

- (void)setIsFlushing:(BOOL)flushing {
    isFlushing = flushing;
}

- (void)clearBuffer {
    [mutableReplayBuffer removeAllObjects];

    // remove persisted replays
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"radar-replays"];
}

- (void)removeReplaysFromBuffer:(NSArray<RadarReplay *> *)replays {
    [mutableReplayBuffer removeObjectsInArray:replays];

    // persist the updated buffer
    NSError *error;
    NSData *replaysData = [NSKeyedArchiver archivedDataWithRootObject:mutableReplayBuffer requiringSecureCoding:YES error:&error];
    if (error) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Error archiving replays"]; 
        return;
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:replaysData forKey:@"radar-replays"];
    }
}

- (void)loadReplaysFromPersistentStore {
    NSData *replaysData = [[NSUserDefaults standardUserDefaults] objectForKey:@"radar-replays"];
    if (replaysData) {
        NSError *error;
        NSSet *allowedClasses = [NSSet setWithObjects:[NSArray class], [RadarReplay class], [NSDictionary class], [NSString class], [NSNumber class], nil];
        NSArray<RadarReplay *> *replays = [NSKeyedUnarchiver unarchivedObjectOfClasses:allowedClasses fromData:replaysData error:&error];
        if (error) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Error unarchiving replays"]; 
            return;
        }
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Loaded replays | length = %lu", (unsigned long)[replays count]]];
        mutableReplayBuffer = [NSMutableArray arrayWithArray:replays];
    }
}

- (void)dropOldestReplay {
    [mutableReplayBuffer removeObjectsInRange:NSMakeRange(0, 1)];
}

#pragma mark - Batch Methods

- (void)addToBatch:(NSMutableDictionary *)params options:(RadarTrackingOptions *)options {
    BOOL wasEmpty = (mutableReplayBuffer.count == 0);
    
    NSMutableDictionary *batchParams = [params mutableCopy];
    batchParams[@"replayed"] = @(YES);
    long nowMs = (long)([NSDate date].timeIntervalSince1970 * 1000);
    batchParams[@"updatedAtMs"] = @(nowMs);
    [batchParams removeObjectForKey:@"updatedAtMsDiff"];
    
    [self writeNewReplayToBuffer:batchParams];
    
    if (wasEmpty) {
        batchStartTime = [NSDate date];
        
        if (options.batchInterval > 0) {
            [self scheduleBatchTimerWithInterval:options.batchInterval];
        }
    }
    
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                       message:[NSString stringWithFormat:@"Added to batch | size = %lu",
                                                (unsigned long)mutableReplayBuffer.count]];
}

- (BOOL)shouldFlushBatchWithOptions:(RadarTrackingOptions *)options {
    if (mutableReplayBuffer.count == 0) {
        return NO;
    }
    
    if (options.batchSize > 0 && mutableReplayBuffer.count >= options.batchSize) {
        [[RadarLogger sharedInstance] logWithLevel: RadarLogLevelDebug
                                           message: @"Batch size limit reached"];
        
        return YES;
    }
    
    return NO;
}

- (void)scheduleBatchTimerWithInterval:(int)interval {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self->batchFlushTimer) {
            [self->batchFlushTimer invalidate];
            self->batchFlushTimer = nil;
        }
        
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                           message:[NSString stringWithFormat:@"Scheduling batch timer | interval = %d", interval]];
        
        self->batchFlushTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                                repeats:NO
                                                                  block:^(NSTimer *_Nonnull timer) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                               message:@"Batch timer fired"];
            self->batchStartTime = nil;
            [self flushReplaysWithCompletionHandler:nil completionHandler:nil];
        }];
    });
}

- (void)cancelBatchTimer {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self->batchFlushTimer) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                               message:@"Canceling batch timer"];
            [self->batchFlushTimer invalidate];
            self->batchFlushTimer = nil;
        }
    });
}

- (void)flushBatch {
    [self cancelBatchTimer];
    batchStartTime = nil;
    [self flushReplaysWithCompletionHandler:nil completionHandler:nil];
}

- (NSUInteger)batchCount {
    return mutableReplayBuffer.count;
}

@end
