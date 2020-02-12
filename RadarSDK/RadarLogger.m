//
//  RadarLogger.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarLogger.h"

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
    RadarLogLevel logLevel = [RadarSettings logLevel];
    if (logLevel >= level) {
        message = [NSString stringWithFormat:@"%@ | backgroundTimeRemaining = %g", message, [RadarUtils backgroundTimeRemaining]];
        
        NSLog(@"%@", message);
        
        if (self.delegate) {
            [self.delegate didLogMessage:message];
        }
    }
}

@end
