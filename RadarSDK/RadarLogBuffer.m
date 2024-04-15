//
//  RadarLogBuffer.m
//  RadarSDK
//
//  Copyright © 2021 Radar Labs, Inc. All rights reserved.
//

#import "RadarLogBuffer.h"
#import "RadarLog.h"
#import "RadarFileStorage.h"
#import "RadarSettings.h"

static const int MAX_PERSISTED_BUFFER_SIZE = 500;
static const int MAX_MEMORY_BUFFER_SIZE = 200;
static const int PURGE_AMOUNT = 250;
static const int MAX_BUFFER_SIZE = 500;

static NSString *const kPurgedLogLine = @"----- purged oldest logs -----";

static int fileCounter = 0;

@implementation RadarLogBuffer {
    NSMutableArray<RadarLog *> *logBuffer;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _persistentLogFeatureFlag = [RadarSettings featureSettings].useLogPersistence;
        logBuffer = [NSMutableArray<RadarLog *> new];
        
        NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        self.logFileDir = [documentsDirectory stringByAppendingPathComponent:@"radar_logs"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.logFileDir isDirectory:nil]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:self.logFileDir withIntermediateDirectories:YES attributes:nil error:nil];
        }
        self.fileHandler = [[RadarFileStorage alloc] init];
        _timer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(persistLogs) userInfo:nil repeats:YES];
        
    }
    return self;
}

- (void)setPersistentLogFeatureFlag:(BOOL)persistentLogFeatureFlag {
    _persistentLogFeatureFlag = persistentLogFeatureFlag;
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
    [self write:level type:type message:message forcePersist:NO];
}

- (void)write:(RadarLogLevel)level type:(RadarLogType)type message:(NSString *)message forcePersist:(BOOL)forcePersist {
    RadarLog *radarLog = [[RadarLog alloc] initWithLevel:level type:type message:message];
    // bypass sync lock here to ensure that other writes or persisting logs don't block the current thread as the app is terminating
    if (forcePersist && (_persistentLogFeatureFlag || [[NSProcessInfo processInfo] environment][@"XCTestConfigurationFilePath"])) {
        [self writeToFileStorage:@[radarLog]];
        return;
    }
    @synchronized (self) {
        [logBuffer addObject:radarLog];
        if (_persistentLogFeatureFlag || [[NSProcessInfo processInfo] environment][@"XCTestConfigurationFilePath"]) { 
            if ([logBuffer count] >= MAX_MEMORY_BUFFER_SIZE) {
                [self persistLogs];
            }
        } else {
            if ([logBuffer count] >= MAX_BUFFER_SIZE) {
                [self purgeOldestLogs];
            }
        }  
    }
}

- (void)persistLogs {
    @synchronized (self) {
        if (_persistentLogFeatureFlag || [[NSProcessInfo processInfo] environment][@"XCTestConfigurationFilePath"]) {
            if ([logBuffer count] > 0) {
                [self writeToFileStorage:logBuffer];
                [logBuffer removeAllObjects];
            }
            
        }
    }
}

- (NSArray<NSString *> *)getLogFilesInTimeOrder {
    NSString *characterToStrip = @"_";
    NSComparator compareTimeStamps = ^NSComparisonResult(NSString *str1, NSString *str2) {
        NSArray<NSString *> *parts1 = [str1 componentsSeparatedByString:characterToStrip];
        NSArray<NSString *> *parts2 = [str2 componentsSeparatedByString:characterToStrip];
    
        // Compare timestamps
        NSComparisonResult result = [@([parts1[0] longLongValue]) compare:@([parts2[0] longLongValue])];
    
        // If timestamps are equal, compare file counters
        if (result == NSOrderedSame) {
            result = [@([parts1[1] intValue]) compare:@([parts2[1] intValue])];
        }
    
        return result;
    };

    return [self.fileHandler sortedFilesInDirectory:self.logFileDir usingComparator:compareTimeStamps];
}

- (NSMutableArray<RadarLog *> *)readFromFileStorage {

    NSArray<NSString *> *files = [self getLogFilesInTimeOrder];
    NSMutableArray<RadarLog *> *logs = [NSMutableArray array];
    if (!files) {
        return logs;
    }
    for (NSString *file in files) {
        NSString *filePath = [self.logFileDir stringByAppendingPathComponent:file];
        NSData *fileData = [self.fileHandler readFileAtPath:filePath];
        RadarLog *log = [NSKeyedUnarchiver unarchiveObjectWithData:fileData];
        if (log && log.message) {
            [logs addObject:log];
        }
    }

    return logs;
}

 - (void)writeToFileStorage:(NSArray <RadarLog *> *)logs {
    for (RadarLog *log in logs) {
        NSData *logData = [NSKeyedArchiver archivedDataWithRootObject:log];
        NSTimeInterval unixTimestamp = [log.createdAt timeIntervalSince1970];
        // Logs may be created in the same millisecond, so we append a counter to the end of the timestamp to "tiebreak"
        NSString *unixTimestampString = [NSString stringWithFormat:@"%lld_%04d", (long long)unixTimestamp, fileCounter++];
        NSString *filePath = [self.logFileDir stringByAppendingPathComponent:unixTimestampString];
        [self.fileHandler writeData:logData toFileAtPath:filePath];
    }
 }

- (NSArray<RadarLog *> *)flushableLogs {
    @synchronized (self) {
        if (_persistentLogFeatureFlag || [[NSProcessInfo processInfo] environment][@"XCTestConfigurationFilePath"]) {
            [self persistLogs];
            [self purgeOldestLogs];
            NSArray *existingLogsArray = [self.readFromFileStorage copy];
            [self removeLogs:[existingLogsArray count]]; 
            return existingLogsArray;
        } else {
            NSArray *flushableLogs = [logBuffer copy];
            [logBuffer removeAllObjects];
            return flushableLogs;
        }
    }
}

- (void)purgeOldestLogs {
    if (_persistentLogFeatureFlag || [[NSProcessInfo processInfo] environment][@"XCTestConfigurationFilePath"]) {
        NSArray<NSString *> *files = [self getLogFilesInTimeOrder];
        NSUInteger dirSize = [files count];
        BOOL printedPurgedLogs = NO;
        while (dirSize >= MAX_PERSISTED_BUFFER_SIZE) {
            [self removeLogs:PURGE_AMOUNT];
            dirSize = [[self getLogFilesInTimeOrder] count];
            if (!printedPurgedLogs) {
                printedPurgedLogs = YES;
                RadarLog *purgeLog = [[RadarLog alloc] initWithLevel:RadarLogLevelDebug type:RadarLogTypeNone message:kPurgedLogLine];
                [self writeToFileStorage:@[purgeLog]];
            }
        } 
    } else {
        // drop the oldest N logs from the buffer
        [logBuffer removeObjectsInRange:NSMakeRange(0, PURGE_AMOUNT)];
        RadarLog *purgeLog = [[RadarLog alloc] initWithLevel:RadarLogLevelDebug type:RadarLogTypeNone message:kPurgedLogLine];
        [logBuffer insertObject:purgeLog atIndex:0];
    }
}
    


- (void)removeLogs:(NSUInteger)numLogs {
    @synchronized (self) {
        if (_persistentLogFeatureFlag || [[NSProcessInfo processInfo] environment][@"XCTestConfigurationFilePath"]) {
            NSArray<NSString *> *files = [self getLogFilesInTimeOrder];
            for (NSUInteger i = 0; i < MIN(numLogs, [files count]); i++) {
                NSString *file = [files objectAtIndex:i];
                NSString *filePath = [self.logFileDir stringByAppendingPathComponent:file];
                [self.fileHandler deleteFileAtPath:filePath];
            }
        } else {
            [logBuffer removeObjectsInRange:NSMakeRange(0, MIN(numLogs, [logBuffer count]))];
        }
    }
}


- (void)onFlush:(BOOL)success logs:(NSArray<RadarLog *> *)logs{
    @synchronized (self) {
        if (_persistentLogFeatureFlag || [[NSProcessInfo processInfo] environment][@"XCTestConfigurationFilePath"]) {
            if (!success) {
                [self writeToFileStorage:logs];
                // Attempt purge to only remove the oldest logs to reduce payload size of next attempt.
                [self purgeOldestLogs];
            }
        } else {
            if (!success) {
                [logBuffer addObjectsFromArray:logs];
                if ([logBuffer count] >= MAX_BUFFER_SIZE) {
                    [self purgeOldestLogs];
                }
            }
        }
    }
}

/**
* Clears the in-memory buffer and deletes all persisted logs. (For use in testing only.)
*/
-(void)clearBuffer {
    @synchronized (self) {
        [logBuffer removeAllObjects];
        NSArray<NSString *> *files = [self getLogFilesInTimeOrder];
        if (files) {
            for (NSString *file in files) {
                NSString *filePath = [self.logFileDir stringByAppendingPathComponent:file];
                [self.fileHandler deleteFileAtPath:filePath];
            }
        }
    }
}

@end
