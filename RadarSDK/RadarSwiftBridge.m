//
//  RadarSwiftBridge.m
//  RadarSDK
//
//  Created by ShiCheng Lu on 9/16/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RadarSwiftBridge.h"
#import "RadarReplayBuffer.h"
#import "Radar+Internal.h"

@implementation RadarSwiftBridge

- (void)setLogBufferPersistantLog:(BOOL)value { 
    [[RadarLogBuffer sharedInstance] setPersistentLogFeatureFlag:value];
}

- (void)writeToLogBufferWithLevel:(RadarLogLevel)level type:(RadarLogType)type message:(NSString * _Nonnull)message forcePersist:(BOOL)forcePersist { 
    [[RadarLogBuffer sharedInstance] write:level type:type message:message forcePersist:forcePersist];
}

- (void)flushReplays {
    [[RadarReplayBuffer sharedInstance] flushReplaysWithCompletionHandler:nil completionHandler:nil];
}

- (void)logOpenedAppConversion {
    [Radar logOpenedAppConversion];
}

- (void)invokeWithTarget:(NSObject * _Nonnull)target selector:(SEL _Nonnull)selector args:(NSArray * _Nonnull)args {
    NSMethodSignature *signature = [target methodSignatureForSelector:selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = target;
    invocation.selector = selector;

    // Note: Objective-C method arguments start at index 2 (0 = self, 1 = _cmd).
    for (int i = 0; i < args.count; ++i) {
        id arg = args[i];
        [invocation setArgument:&arg atIndex:i + 2];
    }

    [invocation invoke];
}

@end
