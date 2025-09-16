//
//  RadarSwiftBridge.m
//  RadarSDK
//
//  Created by ShiCheng Lu on 9/16/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RadarSwiftBridge.h"

@implementation RadarSwiftBridge

- (void)setLogBufferPersistantLog:(BOOL)value { 
    [[RadarLogBuffer sharedInstance] setPersistentLogFeatureFlag:value];
}

- (void)writeToLogBufferWithLevel:(RadarLogLevel)level type:(RadarLogType)type message:(NSString * _Nonnull)message forcePersist:(BOOL)forcePersist { 
    [[RadarLogBuffer sharedInstance] write:level type:type message:message forcePersist:forcePersist];
}

@end
