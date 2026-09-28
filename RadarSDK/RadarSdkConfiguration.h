//
//  RadarSdkConfiguration.h
//  RadarSDK
//
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Radar.h"
@class RadarRemoteTrackingOptions;

NS_ASSUME_NONNULL_BEGIN

// Declares the internal Swift class RadarSdkConfiguration for Objective-C code in the SDK. Keep
// in sync with RadarSdkConfiguration.swift. This is a project header, not public.
@interface RadarSdkConfiguration : NSObject

@property (nonatomic, readonly) RadarLogLevel logLevel;
@property (nonatomic, readonly) BOOL startTrackingOnInitialize;
@property (nonatomic, readonly) BOOL trackOnceOnAppOpen;
@property (nonatomic, readonly) BOOL usePersistence;
@property (nonatomic, readonly) BOOL extendFlushReplays;
@property (nonatomic, readonly) BOOL useLogPersistence;
@property (nonatomic, readonly) BOOL useRadarModifiedBeacon;
@property (nonatomic, readonly) BOOL useOpenedAppConversion;
@property (nonatomic, readonly) BOOL useForegroundLocationUpdatedAtMsDiff;
@property (nonatomic, readonly) BOOL syncAfterSetUser;
@property (nonatomic, readonly) BOOL useSyncRegion;
@property (nonatomic, readonly) NSInteger defaultGeofenceDwellThreshold;
@property (nonatomic, readonly) BOOL bufferGeofenceEntries;
@property (nonatomic, readonly) BOOL bufferGeofenceExits;
@property (nonatomic, readonly) BOOL stopDetection;
@property (nonatomic, readonly) BOOL skipForegroundCheck;
@property (nonatomic, readonly) BOOL useOfflineRTOUpdates;
@property (nonatomic, readonly) BOOL offlineEventGenerationEnabled;
@property (nonatomic, readonly) BOOL useSwiftLocationManager;
@property (nonatomic, readonly) BOOL startUpdatesWhileInUse;
@property (nullable, nonatomic, readonly) NSArray<RadarRemoteTrackingOptions *> *remoteTrackingOptions;
@property (nonatomic, readonly) BOOL useSwiftVerificationManager;

- (instancetype)initWithDict:(NSDictionary<NSString *, id> *_Nullable)dict;
- (NSDictionary<NSString *, id> *)dictionaryValue;

@end

/**
 Represents server-side sdk configuration.
 
 @see https://radar.com/documentation/sdk/ios
 */
@interface RadarSdkConfiguration_ObjC : NSObject

+ (void)updateSdkConfigurationFromServer;

@end

NS_ASSUME_NONNULL_END
