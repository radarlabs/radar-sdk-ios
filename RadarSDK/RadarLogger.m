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

- (void)logWithLevel:(RadarLogLevel)level message:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        [Radar sendLog:level message:message];

        RadarLogLevel logLevel = [RadarSettings logLevel];
        if (logLevel >= level) {
            NSString *log = [NSString stringWithFormat:@"%@ | backgroundTimeRemaining = %g", message, [RadarUtils backgroundTimeRemaining]];

            os_log(OS_LOG_DEFAULT, "%@", log);

            [[RadarDelegateHolder sharedInstance] didLogMessage:log];
        }
    });
}

@end
