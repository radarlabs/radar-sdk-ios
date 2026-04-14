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
#import "RadarLogger.h"

@implementation RadarSwiftBridge

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

- (BOOL)isStopped {
    return [RadarState stopped];
}

- (void)logCampaignConversionWithName:(NSString *)name metadata:(NSDictionary<NSString *, id> * _Nonnull)metadata campaign:(NSString * _Nullable)campaign {
    [Radar sendLogConversionRequestWithName:name metadata:metadata campaign:campaign completionHandler:^(RadarStatus status, RadarEvent * _Nullable event) {
        NSString *message = [NSString stringWithFormat:@"Conversion name = %@: status = %@; event = %@", event.conversionName, [Radar stringForStatus:status], event];
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:message];
    }];
}

@end
