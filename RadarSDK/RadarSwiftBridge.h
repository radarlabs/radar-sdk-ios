//
//  RadarSwiftBridge.h
//  RadarSDK
//
//  Created by ShiCheng Lu on 9/16/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

#import "RadarEvent+Internal.h"
#import "RadarGeofence+Internal.h"
#import "RadarLogBuffer.h"
#import "RadarTrackingOptions.h"
#import "RadarOfflineManager.h"

@protocol RadarSwiftBridge
- (NSArray<RadarEvent *> * _Nullable)RadarEventsFrom:(id _Nonnull)object;
- (NSArray<RadarGeofence *> * _Nullable)RadarGeofencesFrom:(id _Nonnull)object;
- (void)writeToLogBufferWithLevel:(RadarLogLevel)level type:(RadarLogType)type message:(NSString * _Nonnull)message forcePersist:(BOOL)forcePersist;
- (RadarOfflineManager* _Nullable)RadarOfflineManager;
@end

@interface RadarSwiftBridgeImpl: NSObject<RadarSwiftBridge>
@end

@interface RadarSwiftBridgeHolder : NSObject
+ (id <RadarSwiftBridge> _Nullable)shared;
+ (void)setShared:(id <RadarSwiftBridge> _Nullable)value;
- (nonnull instancetype)init;
@end
