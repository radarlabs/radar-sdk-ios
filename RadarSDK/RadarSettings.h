//
//  RadarSettings.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

#import "Radar.h"
#import "RadarTrackingOptions.h"
#import "RadarSdkConfiguration.h"
#import "RadarInitializeOptions.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarSettings : NSObject

+ (NSString *_Nullable)publishableKey;
+ (void)setPublishableKey:(NSString *)publishableKey;
+ (NSString *)installId;
+ (BOOL)updateSessionId;
+ (NSString *)sessionId;
+ (NSString *_Nullable)_id;
+ (void)setId:(NSString *_Nullable)_id;
+ (NSString *_Nullable)userId;
+ (void)setUserId:(NSString *_Nullable)userId;
+ (NSString *_Nullable)__description;
+ (void)setDescription:(NSString *_Nullable)description;
+ (NSString *_Nullable)product;
+ (void)setProduct:(NSString *_Nullable)product;
+ (NSDictionary *_Nullable)metadata;
+ (void)setMetadata:(NSDictionary *_Nullable)metadata;
+ (BOOL)anonymousTrackingEnabled;
+ (void)setAnonymousTrackingEnabled:(BOOL)enabled;
+ (BOOL)tracking;
+ (void)setTracking:(BOOL)tracking;
+ (RadarTrackingOptions *_Nullable)trackingOptions;
+ (void)setTrackingOptions:(RadarTrackingOptions *_Nonnull)options;
+ (void)removeTrackingOptions;
+ (RadarTrackingOptions *_Nullable)previousTrackingOptions;
+ (void)setPreviousTrackingOptions:(RadarTrackingOptions *_Nonnull)options;
+ (void)removePreviousTrackingOptions;
+ (RadarTrackingOptions *_Nullable)remoteTrackingOptions;
+ (void)setRemoteTrackingOptions:(RadarTrackingOptions *_Nonnull)options;
+ (void)removeRemoteTrackingOptions;
+ (RadarTripOptions *_Nullable)tripOptions;
+ (void)setTripOptions:(RadarTripOptions *_Nullable)options;
+ (NSDictionary *)clientSdkConfiguration;
+ (void) setClientSdkConfiguration:(NSDictionary *)sdkConfiguration;
+ (RadarSdkConfiguration *_Nullable)sdkConfiguration;
+ (void)setSdkConfiguration:(RadarSdkConfiguration *_Nullable)sdkConfiguration;
+ (BOOL)isDebugBuild;
+ (RadarLogLevel)logLevel;
+ (void)setLogLevel:(RadarLogLevel)level;
+ (NSArray<NSString *> *_Nullable)beaconUUIDs;
+ (void)setBeaconUUIDs:(NSArray<NSString *> *_Nullable)beaconUUIDs;
+ (NSString *)host;
+ (void)updateLastTrackedTime;
+ (NSDate *)lastTrackedTime;
+ (NSString *)verifiedHost;
+ (BOOL)userDebug;
+ (void)setUserDebug:(BOOL)userDebug;
+ (void)updateLastAppOpenTime;
+ (NSDate *)lastAppOpenTime;
+ (BOOL)useRadarModifiedBeacon;
+ (BOOL)useLocationMetadata;
+ (BOOL)xPlatform;
+ (NSString *)xPlatformSDKType;
+ (NSString *)xPlatformSDKVersion;
+ (BOOL)useOpenedAppConversion;
+ (void)setInitializeOptions:(RadarInitializeOptions *)options;
+ (RadarInitializeOptions *)initializeOptions;

@end

NS_ASSUME_NONNULL_END
