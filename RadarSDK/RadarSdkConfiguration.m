//
//  RadarSdkConfiguration.m
//  RadarSDK
//
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import "RadarSdkConfiguration.h"

#import "RadarLog.h"
#import "RadarUtils.h"

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
    RadarLogLevel logLevel = 1;
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

@end
