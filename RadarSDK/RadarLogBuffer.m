//
//  RadarLogBuffer.m
//  RadarSDK
//
//  Copyright © 2021 Radar Labs, Inc. All rights reserved.
//

#import "RadarLogBuffer.h"
#import "RadarLog.h"
#import "RadarFileSystem.h"

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
        NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        NSString *logFileName = @"RadarLogs.txt";
        self.logFilePath = [documentsDirectory stringByAppendingPathComponent:logFileName];
        self.fileHandler = [[RadarFileSystem alloc] init];
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
    @synchronized (self) {
    RadarLog *radarLog = [[RadarLog alloc] initWithLevel:level type:type message:message];
    NSMutableArray *existingLogs = [self readFromFileSystem];
    NSUInteger logLength = [existingLogs count];
    // purge oldest log if reached the max buffer size
    if (logLength >= MAX_BUFFER_SIZE) {
        [self purgeOldestLogs];
    }
    [existingLogs addObject:radarLog];
    [self writeToFileSystem:existingLogs];
    // [mutableLogBuffer addObject:radarLog];
    }
}


- (NSMutableArray<RadarLog *> *)readFromFileSystem {
    NSData *fileData = [self.fileHandler readFileAtPath:self.logFilePath];
    NSMutableArray<RadarLog *> *existingLogs = [NSMutableArray array];
    if (fileData) {
        NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:fileData options:0 error:nil];
        for (NSDictionary *jsonDict in jsonArray) {
            RadarLog *existingLog = [[RadarLog alloc] initWithDictionary:jsonDict];
            //NSLog(@"reading log%@", existingLog.message);
            [existingLogs addObject:existingLog];
        }
    }
    return existingLogs;
}

- (void) writeToFileSystem:(NSMutableArray<RadarLog *> * )logs {
    NSMutableArray *updatedLogsArray = [NSMutableArray array];
    for (RadarLog *log in logs) {
        [updatedLogsArray addObject:[log dictionaryValue]];
    }
    NSData *updatedLogData = [NSJSONSerialization dataWithJSONObject:updatedLogsArray options:0 error:nil];
    [self.fileHandler writeData:updatedLogData toFileAtPath:self.logFilePath];
}

- (NSArray<RadarLog *> *)flushableLogs {
    @synchronized (self) {
    NSArray *existingLogsArray = [self.readFromFileSystem copy];
    // NSArray *flushableLogs = [mutableLogBuffer copy];
   // turn both arrays into sets of strings by turning each elem into a json string
    // NSMutableSet *existingLogsSet = [NSMutableSet set];
    // NSMutableSet *flushableLogsSet = [NSMutableSet set];
    // for (RadarLog *log in existingLogsArray) {
    //     [existingLogsSet addObject:[log dictionaryValue]];
    // }
    // for (RadarLog *log in flushableLogs) {
    //     [flushableLogsSet addObject:[log dictionaryValue]];
    // }
    // find the difference between the two sets
    // [flushableLogsSet minusSet:existingLogsSet];
    // [existingLogsSet minusSet:flushableLogsSet];
    // NSLog(@"mem logs size: %lu, set: %@, ", (unsigned long)[flushableLogsSet count], flushableLogsSet);
    // NSLog(@"file system logs size: %lu, set: %@, ", (unsigned long)[existingLogsSet count], existingLogsSet);

    
    return existingLogsArray;
    }
}

- (void)purgeOldestLogs {
    // drop the oldest N logs from the buffer
    //[mutableLogBuffer removeObjectsInRange:NSMakeRange(0, PURGE_AMOUNT)];
    RadarLog *purgeLog = [[RadarLog alloc] initWithLevel:RadarLogLevelDebug type:RadarLogTypeNone message:kPurgedLogLine];
    //[mutableLogBuffer insertObject:purgeLog atIndex:0];
    //new version
    NSMutableArray *existingLogs = [self readFromFileSystem];
    [existingLogs removeObjectsInRange:NSMakeRange(0, PURGE_AMOUNT)];
    [existingLogs insertObject:purgeLog atIndex:0];
    [self writeToFileSystem:existingLogs];    
    // [mutableLogBuffer removeObjectsInRange:NSMakeRange(0, PURGE_AMOUNT)];
    // [mutableLogBuffer insertObject:purgeLog atIndex:0];
}

- (void)removeLogsFromBuffer:(NSUInteger)numLogs {
    @synchronized (self) {
    // [mutableLogBuffer removeObjectsInRange:NSMakeRange(0, numLogs)];
    // new version
    NSMutableArray *existingLogs = [self readFromFileSystem];
    [existingLogs removeObjectsInRange:NSMakeRange(0, numLogs)];
    [self writeToFileSystem:existingLogs];
    } 
}

- (void)addLogsToBuffer:(NSArray<RadarLog *> *)logs {
    @synchronized (self) {
    // [mutableLogBuffer addObjectsFromArray:logs];
    NSMutableArray *existingLogs = [self readFromFileSystem];
    [existingLogs addObjectsFromArray:logs];
    [self writeToFileSystem:existingLogs]; 
    }
}

-(void)clear {
    @synchronized (self) {
    // [mutableLogBuffer removeAllObjects];
    [self.fileHandler deleteFileAtPath:self.logFilePath];
    }
}

@end
