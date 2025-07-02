//
//  RadarSdkConfiguration.m
//  RadarSDK
//
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import "RadarSdkConfiguration.h"
#include "Radar.h"

#import "RadarLog.h"
#import "RadarUtils.h"
#import "RadarAPIClient.h"
#import "RadarSettings.h"

@implementation RadarSdkConfiguration

- (instancetype)initWithDict:(NSDictionary *)dict {
    self = [super init];
    if (self == nil) {
        return nil;
    }

    // Set default values
    _logLevel = RadarLogLevelInfo;
    _startTrackingOnInitialize = NO;
    _trackOnceOnAppOpen = NO;
    _usePersistence = NO;
    _extendFlushReplays = NO;
    _useLogPersistence = NO;
    _useRadarModifiedBeacon = NO;
    _useLocationMetadata = NO;
    _useOpenedAppConversion = NO;
    _useForegroundLocationUpdatedAtMsDiff = NO;
    _useNotificationDiff = NO;
    _syncAfterSetUser = NO;

    if (dict == nil) {
        return self;
    }

    NSObject *logLevelObj = dict[@"logLevel"];
    if (logLevelObj && [logLevelObj isKindOfClass:[NSString class]]) {
        _logLevel = [RadarLog levelFromString:(NSString *)logLevelObj];
    }

    NSObject *startTrackingOnInitializeObj = dict[@"startTrackingOnInitialize"]; 
    if (startTrackingOnInitializeObj && [startTrackingOnInitializeObj isKindOfClass:[NSNumber class]]) {
        _startTrackingOnInitialize = [(NSNumber *)startTrackingOnInitializeObj boolValue];
    }

    NSObject *trackOnceOnAppOpenObj = dict[@"trackOnceOnAppOpen"];
    if (trackOnceOnAppOpenObj && [trackOnceOnAppOpenObj isKindOfClass:[NSNumber class]]) {
        _trackOnceOnAppOpen = [(NSNumber *)trackOnceOnAppOpenObj boolValue];
    }
    
    NSObject *usePersistenceObj = dict[@"usePersistence"];
    if (usePersistenceObj && [usePersistenceObj isKindOfClass:[NSNumber class]]) {
        _usePersistence = [(NSNumber *)usePersistenceObj boolValue];
    }

    NSObject *extendFlushReplaysObj = dict[@"extendFlushReplays"];
    if (extendFlushReplaysObj && [extendFlushReplaysObj isKindOfClass:[NSNumber class]]) {
        _extendFlushReplays = [(NSNumber *)extendFlushReplaysObj boolValue];
    }

    NSObject *useLogPersistenceObj = dict[@"useLogPersistence"];
    if (useLogPersistenceObj && [useLogPersistenceObj isKindOfClass:[NSNumber class]]) {
        _useLogPersistence = [(NSNumber *)useLogPersistenceObj boolValue];
    }
    
    NSObject *useRadarModifiedBeaconObj = dict[@"useRadarModifiedBeacon"];
    if (useRadarModifiedBeaconObj && [useRadarModifiedBeaconObj isKindOfClass:[NSNumber class]]) {
        _useRadarModifiedBeacon = [(NSNumber *)useRadarModifiedBeaconObj boolValue];
    }

    NSObject *useLocationMetadataObj = dict[@"useLocationMetadata"];
    if (useLocationMetadataObj && [useLocationMetadataObj isKindOfClass:[NSNumber class]]) {
        _useLocationMetadata = [(NSNumber *)useLocationMetadataObj boolValue];
    }

    NSObject *useOpenedAppConversionObj = dict[@"useOpenedAppConversion"];
    if (useOpenedAppConversionObj && [useOpenedAppConversionObj isKindOfClass:[NSNumber class]]) {
        _useOpenedAppConversion = [(NSNumber *)useOpenedAppConversionObj boolValue];
    }

    NSObject *useForegroundLocationUpdatedAtMsDiffObj = dict[@"foregroundLocationUseUpdatedAtMsDiff"];
    if (useForegroundLocationUpdatedAtMsDiffObj && [useForegroundLocationUpdatedAtMsDiffObj isKindOfClass:[NSNumber class]]) {
        _useForegroundLocationUpdatedAtMsDiff = [(NSNumber *)useForegroundLocationUpdatedAtMsDiffObj boolValue];
    }

    NSObject *useNotificationDiffObj = dict[@"useNotificationDiff"];
    if (useNotificationDiffObj && [useNotificationDiffObj isKindOfClass:[NSNumber class]]) {
        _useNotificationDiff = [(NSNumber *)useNotificationDiffObj boolValue];
    }
    
    NSObject *syncAfterSetUserObj = dict[@"syncAfterSetUser"];
    if (syncAfterSetUserObj && [syncAfterSetUserObj isKindOfClass:[NSNumber class]]) {
        _syncAfterSetUser = [(NSNumber *)syncAfterSetUserObj boolValue];
    }

    NSObject *useOfflineRTOUpdates = dict[@"useOfflineRTOUpdates"];
    _useOfflineRTOUpdates = NO;
    if (useOfflineRTOUpdates && [useOfflineRTOUpdates isKindOfClass:[NSNumber class]]) {
        _useOfflineRTOUpdates = [(NSNumber *)useOfflineRTOUpdates boolValue];
    }

    NSObject *remoteTrackingOptionsObj = dict[@"remoteTrackingOptions"];
    _remoteTrackingOptions = nil;
    if (remoteTrackingOptionsObj && [remoteTrackingOptionsObj isKindOfClass:[NSArray class]]) {
        _remoteTrackingOptions = [RadarRemoteTrackingOptions RemoteTrackingOptionsFromObject:remoteTrackingOptionsObj];
    }

    return self;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    
    dict[@"logLevel"] = [RadarLog stringForLogLevel:_logLevel];
    dict[@"startTrackingOnInitialize"] = @(_startTrackingOnInitialize);
    dict[@"trackOnceOnAppOpen"] = @(_trackOnceOnAppOpen);
    dict[@"usePersistence"] = @(_usePersistence);
    dict[@"extendFlushReplays"] = @(_extendFlushReplays);
    dict[@"useLogPersistence"] = @(_useLogPersistence);
    dict[@"useRadarModifiedBeacon"] = @(_useRadarModifiedBeacon);
    dict[@"useLocationMetadata"] = @(_useLocationMetadata);
    dict[@"useOpenedAppConversion"] = @(_useOpenedAppConversion);
    dict[@"useOfflineRTOUpdates"] = @(_useOfflineRTOUpdates);
    dict[@"remoteTrackingOptions"] = [RadarRemoteTrackingOptions arrayForRemoteTrackingOptions:_remoteTrackingOptions];
    dict[@"useForegroundLocationUpdatedAtMsDiff"] = @(_useForegroundLocationUpdatedAtMsDiff);
    dict[@"useNotificationDiff"] = @(_useNotificationDiff);
    dict[@"syncAfterSetUser"] = @(_syncAfterSetUser);
    
    return dict;
}

+ (void)updateSdkConfigurationFromServer {
    [[RadarAPIClient sharedInstance] getConfigForUsage:@"sdkConfigUpdate" 
                                              verified:false
                                     completionHandler:^(RadarStatus status, RadarConfig *config) {
                                         if (status != RadarStatusSuccess || !config) {
                                            return;
                                         }
                                         [RadarSettings setSdkConfiguration:config.meta.sdkConfiguration];
                                     }];
}

@end
