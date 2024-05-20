//
//  RadarSdkConfiguration.m
//  RadarSDK
//
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import "RadarSdkConfiguration.h"

@implementation RadarSdkConfiguration

- (instancetype)initWithLogLevel:(RadarLogLevel)logLevel {
    if (self = [super init]) {
        _logLevel = logLevel;
    }
    return self;
}

+ (RadarSdkConfiguration *_Nullable)sdkConfigurationFromDictionary:(NSDictionary *)dict {
    if (!dict) {
        return [[RadarSdkConfiguration alloc] initWithLogLevel:0];
    }

    NSObject *logLevelObj = dict[@"logLevel"]; 
    RadarLogLevel logLevel = 0;
    if (logLevelObj && [logLevelObj isKindOfClass:[NSNumber class]]) {
        logLevel = [(NSNumber *)logLevelObj intValue];
    }

    return [[RadarSdkConfiguration alloc] initWithLogLevel:logLevel];
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setValue:@(self.logLevel) forKey:@"logLevel"];
    
    return dict;
}

@end
