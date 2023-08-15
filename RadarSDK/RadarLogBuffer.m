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
    NSMutableArray<RadarLog *> *mutableLogBuffer;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        mutableLogBuffer = [NSMutableArray<RadarLog *> new];
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

- (void)write:(RadarLogLevel)level type:(RadarLogType)type message:(NSString *)message {
    // purge oldest log if reached the max buffer size
    NSUInteger logLength = [mutableLogBuffer count];
    if (logLength >= MAX_BUFFER_SIZE) {
        [self purgeOldestLogs];
    }
    // add new log to buffer
    RadarLog *radarLog = [[RadarLog alloc] initWithLevel:level type:type message:message];
    [mutableLogBuffer addObject:radarLog];

    // save the mutableLogBuffer to NSUserDefaults
    NSData *logData = [NSKeyedArchiver archivedDataWithRootObject:mutableLogBuffer];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:@"radar-log-buffer"];
}

- (NSArray<RadarLog *> *)flushableLogs {
    NSArray *flushableLogs = [mutableLogBuffer copy];
    return flushableLogs;
}

- (void)purgeOldestLogs {
    // drop the oldest N logs from the buffer
    [mutableLogBuffer removeObjectsInRange:NSMakeRange(0, PURGE_AMOUNT)];
    RadarLog *purgeLog = [[RadarLog alloc] initWithLevel:RadarLogLevelDebug type:RadarLogTypeNone message:kPurgedLogLine];
    [mutableLogBuffer insertObject:purgeLog atIndex:0];

    // save the mutableLogBuffer to NSUserDefaults
    NSData *logData = [NSKeyedArchiver archivedDataWithRootObject:mutableLogBuffer];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:@"radar-log-buffer"];
}

// populate the mutableLogBuffer from NSUserDefaults
// think through whether we should just flush this immediately
- (void)loadLogsFromPersistentStore {
    NSData *logData = [[NSUserDefaults standardUserDefaults] objectForKey:@"radar-log-buffer"];
    if (logData) {
        NSArray *logArray = [NSKeyedUnarchiver unarchiveObjectWithData:logData];
        mutableLogBuffer = [NSMutableArray arrayWithArray:logArray];
    }
}

- (void)removeLogsFromBuffer:(NSUInteger)numLogs {
    [mutableLogBuffer removeObjectsInRange:NSMakeRange(0, numLogs)];
    // save the mutableLogBuffer to NSUserDefaults
    NSData *logData = [NSKeyedArchiver archivedDataWithRootObject:mutableLogBuffer];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:@"radar-log-buffer"];
}

- (void)addLogsToBuffer:(NSArray<RadarLog *> *)logs {
    [mutableLogBuffer addObjectsFromArray:logs];
    // save the mutableLogBuffer to NSUserDefaults
    NSData *logData = [NSKeyedArchiver archivedDataWithRootObject:mutableLogBuffer];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:@"radar-log-buffer"];
}

@end
