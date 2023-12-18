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

static int counter = 0;

@implementation RadarLogBuffer {
    NSMutableArray<RadarLog *> *mutableLogBuffer;
    NSMutableArray<RadarLog *> *inMemoryLogBuffer;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _persistentLogFeatureFlag = [RadarSettings featureSettings].useLogPersistence;
        mutableLogBuffer = [NSMutableArray<RadarLog *> new];
        inMemoryLogBuffer = [NSMutableArray<RadarLog *> new];
        
        NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        self.logFileDir = [documentsDirectory stringByAppendingPathComponent:@"radar_logs"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.logFileDir isDirectory:nil]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:self.logFileDir withIntermediateDirectories:YES attributes:nil error:nil];
        }
        self.fileHandler = [[RadarFileStorage alloc] init];
        _timer = [NSTimer scheduledTimerWithTimeInterval:20.0 target:self selector:@selector(persistLogs) userInfo:nil repeats:YES];
        
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
    @synchronized (self) {
        NSUInteger logLength = [mutableLogBuffer count];
        if (logLength >= MAX_BUFFER_SIZE) {
            [self purgeOldestLogs];
        }
        // add new log to buffer
        RadarLog *radarLog = [[RadarLog alloc] initWithLevel:level type:type message:message];
        [mutableLogBuffer addObject:radarLog];

        if (_persistentLogFeatureFlag || [[NSProcessInfo processInfo] environment][@"XCTestConfigurationFilePath"]) {
            RadarLog *radarLog = [[RadarLog alloc] initWithLevel:level type:type message:message];
            [inMemoryLogBuffer addObject:radarLog];
            NSUInteger logLength = [inMemoryLogBuffer count];
            if (logLength >= MAX_MEMORY_BUFFER_SIZE) {
                [self persistLogs];
            }
        }   
    }
}

- (void)persistLogs {
    @synchronized (self) {
        if (_persistentLogFeatureFlag || [[NSProcessInfo processInfo] environment][@"XCTestConfigurationFilePath"]) {
            NSArray *flushableLogs = [inMemoryLogBuffer copy];
            [self addLogsToBuffer:flushableLogs];
            [inMemoryLogBuffer removeAllObjects]; 
        }
    }
}

- (NSArray<NSString *> *)getLogFilesInTimeOrder {
    NSComparator compareTimeStamps = ^NSComparisonResult(NSString *str1, NSString *str2) {
        return [@([str1 integerValue]) compare:@([str2 integerValue])];
    };

    return [self.fileHandler allFilesInDirectory:self.logFileDir withComparator:compareTimeStamps];
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
        NSString *unixTimestampString = [NSString stringWithFormat:@"%lld%04d", (long long)unixTimestamp, counter++];
        NSString *filePath = [self.logFileDir stringByAppendingPathComponent:unixTimestampString];
        [self.fileHandler writeData:logData toFileAtPath:filePath];
    }
 }

- (void)append:(RadarLogLevel)level type:(RadarLogType)type message:(NSString *)message {
    @synchronized (self) {
        if (_persistentLogFeatureFlag || [[NSProcessInfo processInfo] environment][@"XCTestConfigurationFilePath"]) {
            [self writeToFileStorage:@[[[RadarLog alloc] initWithLevel:level type:type message:message]]];
        } else {
            [self write:level type:type message:message];
        }
    }
}

- (NSArray<RadarLog *> *)flushableLogs {
    @synchronized (self) {
        if (_persistentLogFeatureFlag || [[NSProcessInfo processInfo] environment][@"XCTestConfigurationFilePath"]) {
            [self persistLogs];
            NSArray *existingLogsArray = [self.readFromFileStorage copy];
            return existingLogsArray;
        } else {
            NSArray *flushableLogs = [mutableLogBuffer copy];
            return flushableLogs;
        }
    }
}

- (void)purgeOldestLogs {
    // drop the oldest N logs from the buffer
    [mutableLogBuffer removeObjectsInRange:NSMakeRange(0, PURGE_AMOUNT)];
    RadarLog *purgeLog = [[RadarLog alloc] initWithLevel:RadarLogLevelDebug type:RadarLogTypeNone message:kPurgedLogLine];
    [mutableLogBuffer insertObject:purgeLog atIndex:0];
}


- (void)removeLogsFromBuffer:(NSUInteger)numLogs {
    @synchronized (self) {
        
        [mutableLogBuffer removeObjectsInRange:NSMakeRange(0, MIN(numLogs, [mutableLogBuffer count]))];
        if (_persistentLogFeatureFlag || [[NSProcessInfo processInfo] environment][@"XCTestConfigurationFilePath"]) {
            NSArray<NSString *> *files = [self getLogFilesInTimeOrder];
            for (NSUInteger i = 0; i < MIN(numLogs, [files count]); i++) {
                NSString *file = [files objectAtIndex:i];
                NSString *filePath = [self.logFileDir stringByAppendingPathComponent:file];
                [self.fileHandler deleteFileAtPath:filePath];
            }
        }
    }
}

- (void)addLogsToBuffer:(NSArray<RadarLog *> *)logs {
    @synchronized (self) {
        [mutableLogBuffer addObjectsFromArray:logs];
        if (_persistentLogFeatureFlag || [[NSProcessInfo processInfo] environment][@"XCTestConfigurationFilePath"]) {
            NSArray<NSString *> *files = [self getLogFilesInTimeOrder];
            NSUInteger bufferSize = [files count];
            NSUInteger logLength = [logs count];
            while (bufferSize + logLength >= MAX_PERSISTED_BUFFER_SIZE) {
                [self removeLogsFromBuffer:PURGE_AMOUNT];
                bufferSize = [[self getLogFilesInTimeOrder] count];
                RadarLog *purgeLog = [[RadarLog alloc] initWithLevel:RadarLogLevelDebug type:RadarLogTypeNone message:kPurgedLogLine];
                [self writeToFileStorage:@[purgeLog]];
            }
            [self writeToFileStorage:logs];
        } 
    }
}

//for use in testing
-(void)clearBuffer {
    @synchronized (self) {
        [inMemoryLogBuffer removeAllObjects];
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
