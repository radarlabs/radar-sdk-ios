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

     if (self.logFilePath) {
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.logFilePath];
        if (!fileHandle) {
            [[NSFileManager defaultManager] createFileAtPath:self.logFilePath contents:nil attributes:nil];
            fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.logFilePath];
        }
        
        if (fileHandle) {
            [fileHandle seekToEndOfFile];
            NSData *log = [NSKeyedArchiver archivedDataWithRootObject:radarLog requiringSecureCoding:NO error:nil];
            [fileHandle writeData:[log dataUsingEncoding:NSUTF8StringEncoding]];
            [fileHandle closeFile];
        }
    }    
}

- (void)flushlocalLogs {
    // read logs from file
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:self.logFilePath];
    if (fileHandle) {
        NSData *data = [fileHandle readDataToEndOfFile];
        [fileHandle closeFile];
        
        // delete file
        [[NSFileManager defaultManager] removeItemAtPath:self.logFilePath error:nil];
        
        // send logs
        NSString *logString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSArray<RadarLog *> *localLogs = [RadarLog parseLogs:logString];
        for (RadarLog *localLog in localLogs) {
 
            dispatch_async(dispatch_get_main_queue(), ^{
                [Radar sendLog:localLog.level type:localLog.type message:localLog.message];

                RadarLogLevel logLevel = [RadarSettings logLevel];
                if (logLevel >= localLog.level) {
                    NSString *log = [NSString stringWithFormat:@"%@ | backgroundTimeRemaining = %g", localLog.message, [RadarUtils backgroundTimeRemaining]];

                    os_log(OS_LOG_DEFAULT, "%@", log);

                    [[RadarDelegateHolder sharedInstance] didLogMessage:log];
                }
            });
        }
    }
   
}

@end
