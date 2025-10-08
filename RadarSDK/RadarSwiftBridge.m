//
//  RadarSwiftBridge.m
//  RadarSDK
//
//  Created by ShiCheng Lu on 9/16/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RadarSwiftBridge.h"
#import "RadarEvent+Internal.h"
#import "RadarGeofence+Internal.h"
#import "Radar+Internal.h"

@implementation RadarSwiftBridgeImpl

- (NSArray<RadarEvent *> * _Nullable)RadarEventsFrom:(id _Nonnull)object {
    return [RadarEvent eventsFromObject:object];
}

- (NSArray<RadarGeofence *> * _Nullable)RadarGeofencesFrom:(id _Nonnull)object {
    return [RadarGeofence geofencesFromObject:object];
}

- (void)writeToLogBufferWithLevel:(RadarLogLevel)level type:(RadarLogType)type message:(NSString * _Nonnull)message forcePersist:(BOOL)forcePersist {
    [[RadarLogBuffer sharedInstance] write:level type:type message:message forcePersist:forcePersist];
}

- (RadarOfflineManager* _Nullable)RadarOfflineManager {
    return Radar.offlineManager;
}

@end
