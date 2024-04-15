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
#import "RadarLog.h"
#import "RadarLogBuffer.h"

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
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        self.device = [UIDevice currentDevice];
        self.device.batteryMonitoringEnabled = YES;
    }
    return self;
}

- (void)logWithLevel:(RadarLogLevel)level message:(NSString *)message {
    [self logWithLevel:level type:RadarLogTypeNone message:message];
}

- (void)logWithLevel:(RadarLogLevel)level type:(RadarLogType)type message:(NSString *)message {
   [self logWithLevel:level type:type message:message includeDate:NO includeBattery:NO];
}

- (void)logWithLevel:(RadarLogLevel)level type:(RadarLogType)type message:(NSString *)message includeDate:(BOOL)includeDate includeBattery:(BOOL)includeBattery{
    [self logWithLevel:level type:type message:message includeDate:includeDate includeBattery:includeBattery append:NO];
}

- (void)logWithLevel:(RadarLogLevel)level type:(RadarLogType)type message:(NSString *)message includeDate:(BOOL)includeDate includeBattery:(BOOL)includeBattery append:(BOOL)append{
     NSString *dateString = [self.dateFormatter stringFromDate:[NSDate date]];
    float batteryLevel = [self.device batteryLevel];
    if (includeDate && includeBattery) {
        message = [NSString stringWithFormat:@"%@ |  at %@ | with %2.f%% battery", message, dateString, batteryLevel*100];
    } else if (includeDate) {
        message = [NSString stringWithFormat:@"%@ | at %@", message, dateString];
    } else if (includeBattery) {
        message = [NSString stringWithFormat:@"%@ | with %2.f%% battery", message, batteryLevel*100];
    }
    if (append) {
        [[RadarLogBuffer sharedInstance] write:level type:type message:message forcePersist:YES];
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [Radar sendLog:level type:type message:message];

            RadarLogLevel logLevel = [RadarSettings logLevel];
            if (logLevel >= level) {
                NSString *log = [NSString stringWithFormat:@"%@ | backgroundTimeRemaining = %g", message, [RadarUtils backgroundTimeRemaining]];

                os_log(OS_LOG_DEFAULT, "%@", log);

                dispatch_async(dispatch_get_main_queue(), ^{
                    [[RadarDelegateHolder sharedInstance] didLogMessage:log];
                });
            }
        });
    }
}

@end
