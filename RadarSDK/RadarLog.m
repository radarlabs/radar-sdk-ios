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
    // dict[@"createdAt"] = self.createdAt;
    dict[@"createdAt"] = @"2021-12-22T02:17:00.000Z";

    //    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //    NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    //    [dateFormatter setLocale:enUSPOSIXLocale];
    //    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    //    [dateFormatter setCalendar:[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian]];
    //
    //    NSDate *now = [NSDate date];
    //    NSString *iso8601String = [dateFormatter stringFromDate:now];

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
