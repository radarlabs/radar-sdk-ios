//
//  RadarSDKConfiguration.m
//  RadarSDK
//
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import "RadarSDKConfiguration.h"

#import "RadarLog.h"

@implementation RadarSDKConfiguration

- (instancetype)initWithLogLevel:(RadarLogLevel)logLevel {
    if (self = [super init]) {
        _logLevel = logLevel;
    }
    return self;
}

+ (RadarSDKConfiguration *_Nullable)sdkConfigurationFromDictionary:(NSDictionary *)dict {
    if (!dict) {
        return NULL;
    }

    NSObject *logLevelObj = dict[@"logLevel"];
    RadarLogLevel logLevel = 0;
    if (logLevelObj && [logLevelObj isKindOfClass:[NSString class]]) {
        logLevel = [RadarLog levelFromString:(NSString *)logLevelObj];
    }

    return [[RadarSDKConfiguration alloc] initWithLogLevel:logLevel];
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    NSString *logLevelString = [RadarLog stringForLogLevel:_logLevel];
    [dict setValue:logLevelString forKey:@"logLevel"];
    
    return dict;
}

@end
