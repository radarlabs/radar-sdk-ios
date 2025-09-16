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

@implementation RadarSwiftBridgeImpl

- (NSArray<RadarEvent *> * _Nullable)RadarEventsFrom:(id _Nonnull)object {
    return [RadarEvent eventsFromObject:object];
}

- (NSArray<RadarGeofence *> * _Nullable)RadarGeofencesFrom:(id _Nonnull)object {
    return [RadarGeofence geofencesFromObject:object];
}

@end
