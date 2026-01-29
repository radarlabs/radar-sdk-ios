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
#import "RadarState.h"
#import "RadarBeacon+Internal.h"
#import "RadarPlace+Internal.h"
#import "RadarTripOptions.h"
#import <CoreLocation/CoreLocation.h>

@protocol RadarSwiftBridgeProtocol
- (void)writeToLogBufferWithLevel:(RadarLogLevel)level type:(RadarLogType)type message:(NSString * _Nonnull)message forcePersist:(BOOL)forcePersist;
- (void)setLogBufferPersistantLog:(BOOL)value;
- (void)flushReplays;
- (void)logOpenedAppConversion;

- (CLCircularRegion * _Nullable)syncedRegion;
- (NSArray<NSString *> * _Nullable)geofenceIds;
- (NSArray<NSString *> * _Nullable)beaconIds;
- (NSString * _Nullable)placeId;
- (NSArray<RadarGeofence *> * _Nullable)nearbyGeofences;
- (NSArray<RadarBeacon *> * _Nullable)nearbyBeacons;
- (NSArray<RadarPlace *> * _Nullable)nearbyPlaces;
- (RadarTripOptions * _Nullable)getTripOptions;
@end

@interface RadarSwiftBridge: NSObject<RadarSwiftBridgeProtocol>
@end

@interface RadarSwift : NSObject
@property (nonatomic, class, strong) id <RadarSwiftBridgeProtocol> _Nullable bridge;

+ (id <RadarSwiftBridgeProtocol> _Nullable)bridge;
+ (void)setBridge:(id <RadarSwiftBridgeProtocol> _Nullable)value;
- (nonnull instancetype)init;
@end
