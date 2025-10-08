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

@protocol RadarSwiftBridgeProtocol
- (void)writeToLogBufferWithLevel:(RadarLogLevel)level type:(RadarLogType)type message:(NSString * _Nonnull)message forcePersist:(BOOL)forcePersist;
- (void)setLogBufferPersistantLog:(BOOL)value;
- (void)flushReplays;
- (void)logOpenedAppConversion;
@end

@interface RadarSwiftBridge: NSObject<RadarSwiftBridgeProtocol>
@end

@interface RadarSwift : NSObject
@property (nonatomic, class, strong) id <RadarSwiftBridgeProtocol> _Nullable bridge;

+ (id <RadarSwiftBridgeProtocol> _Nullable)bridge;
+ (void)setBridge:(id <RadarSwiftBridgeProtocol> _Nullable)value;
- (nonnull instancetype)init;
@end
