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
#import "RadarState.h"
#import "RadarAPIClient.h"

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

- (NSArray<NSString *> * _Nullable)geofenceIds {
    return [RadarState geofenceIds];
}

- (NSArray<NSString *> * _Nullable)beaconIds {
    return [RadarState beaconIds];
}

- (NSString * _Nullable)placeId {
    return [RadarState placeId];
}

- (RadarTripOptions * _Nullable)getTripOptions {
    return [Radar getTripOptions];
}

- (CLLocation * _Nullable)lastLocation {
    return [RadarState lastLocation];
}

- (void)fetchSyncRegionWithLatitude:(double)latitude longitude:(double)longitude completionHandler:(void (^)(RadarStatus status, NSDictionary * _Nullable res))completionHandler {
    [[RadarAPIClient sharedInstance] syncRegionWithLatitude:latitude longitude:longitude completionHandler:completionHandler];
}

- (BOOL)isStopped {
    return [RadarState stopped];
}

@end
