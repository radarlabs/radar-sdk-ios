//
//  RadarSdkConfiguration.m
//  RadarSDK
//
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import "RadarSdkConfiguration.h"

#import "RadarLog.h"
#import "RadarUtils.h"
#import "RadarAPIClient.h"
#import "RadarSettings.h"

#import "RadarLogger.h"

@implementation RadarSdkConfiguration

- (instancetype)initWithLogLevel:(RadarLogLevel)logLevel {
    if (self = [super init]) {
        _logLevel = logLevel;
    }
    return self;
}

+ (RadarSdkConfiguration *_Nullable)sdkConfigurationFromDictionary:(NSDictionary *)dict {
    if (!dict) {
        return nil;
    }

    NSObject *logLevelObj = dict[@"logLevel"];
    RadarLogLevel logLevel = 3;
    if (logLevelObj && [logLevelObj isKindOfClass:[NSString class]]) {
        logLevel = [RadarLog levelFromString:(NSString *)logLevelObj];
    }

    return [[RadarSdkConfiguration alloc] initWithLogLevel:logLevel];
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    NSString *logLevelString = [RadarLog stringForLogLevel:_logLevel];
    [dict setValue:logLevelString forKey:@"logLevel"];
    
    return dict;
}

+ (void)updateSdkConfigurationFromServer:(NSDictionary *_Nonnull)sdkConfiguration {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelNone
        message:[NSString stringWithFormat:@"config = %@",
                            [RadarUtils dictionaryToJson:[RadarSettings clientSdkConfiguration]]]];
    
    
    [[RadarAPIClient sharedInstance] updateSdkConfiguration:sdkConfiguration
                                          completionHandler:^(RadarStatus status, RadarConfig *config) {
                                         if (status != RadarStatusSuccess || !config) {
                                            return;
                                         }
                                         [RadarSettings setSdkConfiguration:config.meta.sdkConfiguration];
                                     }];
}

@end
