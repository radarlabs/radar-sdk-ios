//
//  RadarLog.m
//  RadarSDK
//
//  Copyright © 2021 Radar Labs, Inc. All rights reserved.
//

#import "RadarLog.h"
#import "RadarUtils.h"

@implementation RadarLog

- (instancetype _Nullable)initWithLevel:(RadarLogLevel)level type:(RadarLogType)type message:(NSString *_Nullable)message {
    self = [super init];
    if (self) {
        _level = level;
        _type = type;
        _message = message;
        _createdAt = [NSDate new];
    }
    return self;
}

+ (NSString *)stringForLogLevel:(RadarLogLevel)level {
    NSString *str;
    switch (level) {
    case RadarLogLevelNone:
        str = @"none";
        break;
    case RadarLogLevelError:
        str = @"error";
        break;
    case RadarLogLevelWarning:
        str = @"warning";
        break;
    case RadarLogLevelInfo:
        str = @"info";
        break;
    case RadarLogLevelDebug:
        str = @"debug";
        break;
    }
    return str;
}

+ (NSString *)stringForLogType:(RadarLogType)type {
    NSString *str;
    switch (type) {
    case RadarLogTypeNone:
        str = @"NONE";
        break;
    case RadarLogTypeSDKCall:
        str = @"SDK_CALL";
        break;
    case RadarLogTypeSDKError:
        str = @"SDK_ERROR";
        break;
    case RadarLogTypeSDKException:
        str = @"SDK_EXCEPTION";
        break;
    case RadarLogTypeAppLifecycleEvent:
        str = @"APP_LIFECYCLE_EVENT";
        break;
    case RadarLogTypePermissionEvent:
        str = @"PERMISSION_EVENT";
        break;
    }
    return str;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[@"level"] = [RadarLog stringForLogLevel:self.level];
    dict[@"message"] = self.message;
    if (self.type) {
        dict[@"type"] = [RadarLog stringForLogType:self.type];
    }
    NSString *createdAtString = [RadarUtils.isoDateFormatter stringFromDate:self.createdAt];
    dict[@"createdAt"] = createdAtString;

    return dict;
}

+ (NSArray<NSDictionary *> *)arrayForLogs:(NSArray<RadarLog *> *)logs {
    if (!logs) {
        return nil;
    }

    NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:logs.count];
    for (RadarLog *log in logs) {
        NSDictionary *dict = [log dictionaryValue];
        [arr addObject:dict];
    }
    return arr;
}

@end
