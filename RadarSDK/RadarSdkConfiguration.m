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

- (instancetype)initWithLogLevel:(RadarLogLevel)logLevel
       startTrackingOnInitialize:(bool)startTrackingOnInitialize
              trackOnceOnAppOpen:(BOOL)trackOnceOnAppOpen {
    if (self = [super init]) {
        _logLevel = logLevel;
        _startTrackingOnInitialize = startTrackingOnInitialize;
        _trackOnceOnAppOpen = trackOnceOnAppOpen;
    }
    return self;
}

+ (RadarSdkConfiguration *_Nullable)sdkConfigurationFromDictionary:(NSDictionary *_Nullable)dict {
    if (!dict) {
        return nil;
    }

    NSObject *logLevelObj = dict[@"logLevel"];
    RadarLogLevel logLevel = RadarLogLevelInfo;
    if (logLevelObj && [logLevelObj isKindOfClass:[NSString class]]) {
        logLevel = [RadarLog levelFromString:(NSString *)logLevelObj];
    }

    NSObject *startTrackingOnInitializeObj = dict[@"startTrackingOnInitialize"]; 
    BOOL startTrackingOnInitialize = NO;
    if (startTrackingOnInitializeObj && [startTrackingOnInitializeObj isKindOfClass:[NSNumber class]]) {
        startTrackingOnInitialize = [(NSNumber *)startTrackingOnInitializeObj boolValue];
    }

    NSObject *trackOnceOnAppOpenObj = dict[@"trackOnceOnAppOpen"];
    BOOL trackOnceOnAppOpen = NO;
    if (trackOnceOnAppOpenObj && [trackOnceOnAppOpenObj isKindOfClass:[NSNumber class]]) {
        trackOnceOnAppOpen = [(NSNumber *)trackOnceOnAppOpenObj boolValue];
    }

    return [[RadarSdkConfiguration alloc] initWithLogLevel:logLevel 
                                 startTrackingOnInitialize:startTrackingOnInitialize
                                        trackOnceOnAppOpen:trackOnceOnAppOpen];
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    NSString *logLevelString = [RadarLog stringForLogLevel:_logLevel];
    [dict setValue:logLevelString forKey:@"logLevel"];
    [dict setValue:@(_startTrackingOnInitialize) forKey:@"startTrackingOnInitialize"];
    [dict setValue:@(_trackOnceOnAppOpen) forKey:@"trackOnceOnAppOpen"];
    
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
