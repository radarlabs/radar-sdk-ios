//
//  RadarSdkConfiguration.m
//  RadarSDK
//
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import "RadarSdkConfiguration.h"
#include "Radar.h"

#import "RadarAPIClient.h"
#import "RadarSettings.h"
#import "RadarSDK/RadarSDK-Swift.h"

@implementation RadarSdkConfiguration

- (instancetype)initWithDict:(NSDictionary *)dict {
    self = [super init];
    if (self == nil) {
        return nil;
    }

    NSObject *logLevelObj = dict[@"logLevel"];
    _logLevel = RadarLogLevelInfo;
    if (logLevelObj && [logLevelObj isKindOfClass:[NSString class]]) {
        _logLevel = [RadarLog levelFromString:(NSString *)logLevelObj];
    }

    NSObject *startTrackingOnInitializeObj = dict[@"startTrackingOnInitialize"]; 
    _startTrackingOnInitialize = NO;
    if (startTrackingOnInitializeObj && [startTrackingOnInitializeObj isKindOfClass:[NSNumber class]]) {
        _startTrackingOnInitialize = [(NSNumber *)startTrackingOnInitializeObj boolValue];
    }

    NSObject *trackOnceOnAppOpenObj = dict[@"trackOnceOnAppOpen"];
    _trackOnceOnAppOpen = NO;
    if (trackOnceOnAppOpenObj && [trackOnceOnAppOpenObj isKindOfClass:[NSNumber class]]) {
        _trackOnceOnAppOpen = [(NSNumber *)trackOnceOnAppOpenObj boolValue];
    }
    
    NSObject *usePersistenceObj = dict[@"usePersistence"];
    _usePersistence = NO;
    if (usePersistenceObj && [usePersistenceObj isKindOfClass:[NSNumber class]]) {
        _usePersistence = [(NSNumber *)usePersistenceObj boolValue];
    }

    NSObject *extendFlushReplaysObj = dict[@"extendFlushReplays"];
    _extendFlushReplays = NO;
    if (extendFlushReplaysObj && [extendFlushReplaysObj isKindOfClass:[NSNumber class]]) {
        _extendFlushReplays = [(NSNumber *)extendFlushReplaysObj boolValue];
    }

    NSObject *useLogPersistenceObj = dict[@"useLogPersistence"];
    _useLogPersistence = NO;
    if (useLogPersistenceObj && [useLogPersistenceObj isKindOfClass:[NSNumber class]]) {
        _useLogPersistence = [(NSNumber *)useLogPersistenceObj boolValue];
    }
    
    NSObject *useRadarModifiedBeaconObj = dict[@"useRadarModifiedBeacon"];
    _useRadarModifiedBeacon = NO;
    if (useRadarModifiedBeaconObj && [useRadarModifiedBeaconObj isKindOfClass:[NSNumber class]]) {
        _useRadarModifiedBeacon = [(NSNumber *)useRadarModifiedBeaconObj boolValue];
    }

    NSObject *useLocationMetadataObj = dict[@"useLocationMetadata"];
    _useLocationMetadata = NO;
    if (useLocationMetadataObj && [useLocationMetadataObj isKindOfClass:[NSNumber class]]) {
        _useLocationMetadata = [(NSNumber *)useLocationMetadataObj boolValue];
    }

    NSObject *useOpenedAppConversion = dict[@"useOpenedAppConversion"];
    _useOpenedAppConversion = NO;
    if (useOpenedAppConversion && [useOpenedAppConversion isKindOfClass:[NSNumber class]]) {
        _useOpenedAppConversion = [(NSNumber *)useOpenedAppConversion boolValue];
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
