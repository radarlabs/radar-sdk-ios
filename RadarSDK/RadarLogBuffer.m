//
//  RadarLogBuffer.m
//  RadarSDK
//
//  Copyright © 2021 Radar Labs, Inc. All rights reserved.
//

#import "RadarLogBuffer.h"
#import "RadarLog.h"

static const int MAX_BUFFER_SIZE = 500;
static const int PURGE_AMOUNT = 200;

static NSString *const kPurgedLogLine = @"----- purged oldest logs -----";

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

- (void)write:(RadarLogLevel)level type:(RadarLogType *)type message:(NSString *)message {
    // purge oldest if reached the max buffer size
    NSUInteger logLength = [mutableLogBuffer count];
    if (logLength >= MAX_BUFFER_SIZE) {
        [self purgeOldestLogs];
    }
    // add new log to buffer
    RadarLog *radarLog = [[RadarLog alloc] initWithLevel:level type:type message:message];
    [mutableLogBuffer addObject:radarLog];
}

/**
 * Return copy of logs from the buffer to flush
 */
- (NSArray<RadarLog *> *)flushableLogs {
    NSArray *flushableLogs = [mutableLogBuffer copy];
    return flushableLogs;
}

/**
 * Clears oldest logs and adds a "purged" log line
 */
- (void)purgeOldestLogs {
    // drop the oldest N logs from the buffer
    [mutableLogBuffer removeObjectsInRange:NSMakeRange(0, PURGE_AMOUNT)];
    RadarLog *purgeLog = [[RadarLog alloc] initWithLevel:RadarLogLevelDebug type:NULL message:kPurgedLogLine];
    [mutableLogBuffer insertObject:purgeLog atIndex:0];
}
/**
 * Removes the number of oldest logs from the buffer
 */
- (void)removeLogsFromBuffer:(NSUInteger)numLogs {
    [mutableLogBuffer removeObjectsInRange:NSMakeRange(0, numLogs)];
}

/**
 * Adds array of logs to the buffer
 */
- (void)addLogsToBuffer:(NSArray<RadarLog *> *)logs {
    [mutableLogBuffer addObjectsFromArray:logs];
}

@end
