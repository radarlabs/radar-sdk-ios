//
//  RadarLogBuffer.m
//  RadarSDK
//
//  Copyright © 2021 Radar Labs, Inc. All rights reserved.
//

#import "Radar.h"
#import "RadarLog.h"
#import "RadarLogBuffer.h"

static const int MAX_BUFFER_SIZE = 500;
static const int PURGE_AMOUNT = 200;

static NSString *const kPurgedLogLine = @"----purged oldest logs! ----";

@implementation RadarLogBuffer {
    NSMutableArray<RadarLog *> *mutableLogBuffer; // define log buffer
}

- (instancetype)init {
    self = [super init];
    if (self) {
        mutableLogBuffer = [NSMutableArray<RadarLog *> new]; // initialize log buffer
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

- (void)write:(RadarLogLevel)level message:(NSString *)message {
    // purge oldest if reached the max buffer size
    NSUInteger logLength = [mutableLogBuffer count];
    if (logLength >= MAX_BUFFER_SIZE) {
        [self purgeOldestLogs];
    }
    // add new log to buffer
    RadarLog *radarLog = [[RadarLog alloc] initWithMessage:message level:level];
    [mutableLogBuffer addObject:radarLog];
}

/**
 * Clears oldest logs and adds a "purged" log line
 */
- (void)purgeOldestLogs {
    // drop the oldest N logs from the buffer
    [mutableLogBuffer removeObjectsInRange:NSMakeRange(0, PURGE_AMOUNT)];
    RadarLog *purgeLog = [[RadarLog alloc] initWithMessage:kPurgedLogLine level:RadarLogLevelDebug];
    [mutableLogBuffer insertObject:purgeLog atIndex:0];
}
/**
 * Clears logs that have been successfuly synced to server
 */
- (void)clearSyncedLogsFromBuffer:(NSUInteger)numLogs {
    [mutableLogBuffer removeObjectsInRange:NSMakeRange(0, numLogs)];
}

/**
 * Return copy of logs from the buffer to flush
 */
- (NSArray<RadarLog *> *)getFlushableLogs {
    NSArray *flushableLogs = [mutableLogBuffer copy];
    return flushableLogs;
}


@end
