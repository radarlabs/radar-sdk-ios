//
//  RadarLog.m
//  RadarSDK
//
//  Copyright © 2021 Radar Labs, Inc. All rights reserved.
//

#import "RadarLog.h"

@implementation RadarLog

- (instancetype _Nullable)initWithMessage:(NSString *_Nullable)message
                                    level:(RadarLogLevel)level {
    self = [super init];
    if (self) {
        _level = level;
        _message = message;
        _createdAt = [NSDate new];
    }
    return self;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[@"level"] = [Radar stringForLogLevel:self.level];
    dict[@"message"] = self.message;

    // convert (NSDate)createdAt to ISO8601 string
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];

    NSString *createdAtString = [dateFormatter stringFromDate:self.createdAt];
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
