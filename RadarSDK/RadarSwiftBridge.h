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
#import "RadarState.h"
#import "RadarBeacon+Internal.h"
#import "RadarPlace+Internal.h"
#import "RadarTripOptions.h"
#import <CoreLocation/CoreLocation.h>

@protocol RadarSwiftBridgeProtocol
- (void)flushReplays;
- (void)logOpenedAppConversion;
- (void)invokeWithTarget:(NSObject * _Nonnull)target selector:(SEL _Nonnull)selector args:(NSArray * _Nonnull)args;

- (NSArray<NSString *> * _Nullable)geofenceIds;
- (NSArray<NSString *> * _Nullable)beaconIds;
- (NSString * _Nullable)placeId;
- (CLLocation * _Nullable)lastLocation;
- (BOOL)isStopped;
- (RadarEvent * _Nullable)createEventWithDict:(NSDictionary * _Nonnull)dict;
- (RadarUser * _Nullable)createUserWithDict:(NSDictionary * _Nonnull)dict;
- (RadarGeofence * _Nullable)createGeofenceWithDict:(NSDictionary * _Nonnull)dict;
- (BOOL)isForeground;
- (RadarTripOptions * _Nullable)getTripOptions;
- (RadarUser * _Nullable)radarUser;
- (void)didReceiveEvents:(NSArray<RadarEvent *> * _Nonnull)events user:(RadarUser * _Nonnull)user;
@end

@interface RadarSwiftBridge: NSObject<RadarSwiftBridgeProtocol>
@end

@interface RadarSwift : NSObject
@property (nonatomic, class, strong) id <RadarSwiftBridgeProtocol> _Nullable bridge;

+ (id <RadarSwiftBridgeProtocol> _Nullable)bridge;
+ (void)setBridge:(id <RadarSwiftBridgeProtocol> _Nullable)value;
- (nonnull instancetype)init;
@end
