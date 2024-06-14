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
           trackOnceOnInitialize:(BOOL)trackOnceOnInitialize
               trackOnceOnResume:(BOOL)trackOnceOnResume {
    if (self = [super init]) {
        _logLevel = logLevel;
        _startTrackingOnInitialize = startTrackingOnInitialize;
        _trackOnceOnInitialize = trackOnceOnInitialize;
        _trackOnceOnResume = trackOnceOnResume;
    }
    return self;
}

+ (RadarSdkConfiguration *_Nullable)sdkConfigurationFromDictionary:(NSDictionary *)dict {
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

    NSObject *trackOnceOnInitializeObj = dict[@"startTrackingOnInitialize"]; 
    BOOL trackOnceOnInitialize = NO;
    if (trackOnceOnInitializeObj && [trackOnceOnInitializeObj isKindOfClass:[NSNumber class]]) {
        trackOnceOnInitialize = [(NSNumber *)trackOnceOnInitializeObj boolValue];
    }

    NSObject *trackOnceOnResumeObj = dict[@"startTrackingOnInitialize"]; 
    BOOL trackOnceOnResume = NO;
    if (trackOnceOnResumeObj && [trackOnceOnResumeObj isKindOfClass:[NSNumber class]]) {
        trackOnceOnResume = [(NSNumber *)trackOnceOnResumeObj boolValue];
    }

    return [[RadarSdkConfiguration alloc] initWithLogLevel:logLevel 
                                 startTrackingOnInitialize:startTrackingOnInitialize
                                     trackOnceOnInitialize:trackOnceOnInitialize
                                         trackOnceOnResume:trackOnceOnResume];
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    NSString *logLevelString = [RadarLog stringForLogLevel:_logLevel];
    [dict setValue:logLevelString forKey:@"logLevel"];
    [dict setValue:@(_startTrackingOnInitialize) forKey:@"startTrackingOnInitialize"];
    [dict setValue:@(_trackOnceOnInitialize) forKey:@"trackOnceOnInitialize"];
    [dict setValue:@(_trackOnceOnResume) forKey:@"trackOnceOnResume"];
    
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
