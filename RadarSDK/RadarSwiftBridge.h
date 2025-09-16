//
//  RadarSwiftBridge.h
//  RadarSDK
//
//  Created by ShiCheng Lu on 9/16/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

#import "RadarEvent+Internal.h"
#import "RadarGeofence+Internal.h"
#import "RadarTrackingOptions.h"

@protocol RadarSwiftBridge
- (NSArray<RadarEvent *> * _Nullable)RadarEventsFrom:(id _Nonnull)object;
- (NSArray<RadarGeofence *> * _Nullable)RadarGeofencesFrom:(id _Nonnull)object;
@end

@interface RadarSwiftBridgeImpl: NSObject<RadarSwiftBridge>
@end

