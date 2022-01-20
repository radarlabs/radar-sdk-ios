//
//  RadarLogger.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarLogger.h"

#import "RadarDelegateHolder.h"
#import "RadarSettings.h"
#import "RadarUtils.h"

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
        RadarLogLevel logLevel = [RadarSettings logLevel];
        if (logLevel >= level) {
            NSString *log = [NSString stringWithFormat:@"%@ | backgroundTimeRemaining = %g", message, [RadarUtils backgroundTimeRemaining]];

            NSLog(@"%@", log);

            [[RadarDelegateHolder sharedInstance] didLogMessage:log];
        }
    });
}

@end
