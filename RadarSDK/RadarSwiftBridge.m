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
#import "RadarLogger.h"

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

- (void)logCampaignConversionWithName:(NSString *)name metadata:(NSDictionary<NSString *, id> * _Nonnull)metadata campaign:(NSString * _Nullable)campaign {
    [Radar sendLogConversionRequestWithName:name metadata:metadata campaign:campaign completionHandler:^(RadarStatus status, RadarEvent * _Nullable event) {
        NSString *message = [NSString stringWithFormat:@"Conversion name = %@: status = %@; event = %@", event.conversionName, [Radar stringForStatus:status], event];
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:message];
    }];
}

@end
