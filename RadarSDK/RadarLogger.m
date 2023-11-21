//
//  RadarLogger.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarLogger.h"
#import "Radar+Internal.h"
#import "RadarDelegateHolder.h"
#import "RadarSettings.h"
#import "RadarUtils.h"
#import <os/log.h>
#import "RadarFileSystem.h"
#import "RadarLog.h"

@implementation RadarLogger

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Set the default log file path
        NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        NSString *logFileName = @"RadarLogs.txt";
        self.logFilePath = [documentsDirectory stringByAppendingPathComponent:logFileName];
        self.fileHandler = [[RadarFileSystem alloc] init];
    }
    return self;
}

- (void)logWithLevel:(RadarLogLevel)level message:(NSString *)message {
    [self logWithLevel:level type:RadarLogTypeNone message:message];
}

- (void)logWithLevel:(RadarLogLevel)level type:(RadarLogType)type message:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        [Radar sendLog:level type:type message:message];

        RadarLogLevel logLevel = [RadarSettings logLevel];
        if (logLevel >= level) {
            NSString *log = [NSString stringWithFormat:@"%@ | backgroundTimeRemaining = %g", message, [RadarUtils backgroundTimeRemaining]];

            os_log(OS_LOG_DEFAULT, "%@", log);

            [[RadarDelegateHolder sharedInstance] didLogMessage:log];
        }
    });
}

- (void) logWithLevelLocal:(RadarLogLevel)level message:(NSString *)message {
    [self logWithLevelLocal:level type:RadarLogTypeNone message:message];
}

- (void) logWithLevelLocal:(RadarLogLevel)level type:(RadarLogType)type message:(NSString *)message {
    RadarLog *radarLog = [[RadarLog alloc] initWithLevel:level type:type message:message];

    NSData *fileData = [self.fileHandler readFileAtPath:self.logFilePath];
    NSMutableArray<RadarLog *> *existingLogs = [NSMutableArray array];
    if (fileData) {
        NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:fileData options:0 error:nil];
        for (NSDictionary *jsonDict in jsonArray) {
            RadarLog *existingLog = [[RadarLog alloc] initWithDictionary:jsonDict];
            [existingLogs addObject:existingLog];
        }
    }
    [existingLogs addObject:radarLog];

    NSMutableArray *updatedLogsArray = [NSMutableArray array];
    for (RadarLog *log in existingLogs) {
        [updatedLogsArray addObject:[log dictionaryValue]];
    }

    NSData *updatedLogData = [NSJSONSerialization dataWithJSONObject:updatedLogsArray options:0 error:nil];
    [self.fileHandler writeData:updatedLogData toFileAtPath:self.logFilePath];
}

- (void)flushLocalLogs {
    NSData *fileData = [self.fileHandler readFileAtPath:self.logFilePath];
    if (fileData) {
        NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:fileData options:0 error:nil];
        NSMutableArray<RadarLog *> *existingLogs = [NSMutableArray array];

        for (NSDictionary *jsonDict in jsonArray) {
            RadarLog *existingLog = [[RadarLog alloc] initWithDictionary:jsonDict];
            [existingLogs addObject:existingLog];
        }

        for (RadarLog *retrievedLog in existingLogs) {
            NSLog(@"retrieved log: %@", retrievedLog.message);

            dispatch_async(dispatch_get_main_queue(), ^{
                [Radar sendLog:retrievedLog.level type:retrievedLog.type message:retrievedLog.message];

                RadarLogLevel logLevel = [RadarSettings logLevel];
                if (logLevel >= retrievedLog.level) {
                    NSString *log = [NSString stringWithFormat:@"%@ | backgroundTimeRemaining = %g", retrievedLog.message, [RadarUtils backgroundTimeRemaining]];

                    os_log(OS_LOG_DEFAULT, "%@", log);

                    [[RadarDelegateHolder sharedInstance] didLogMessage:log];
                }
            });
        }

        [self.fileHandler deleteFileAtPath:self.logFilePath];
    }
}



@end
