//
//  RadarTimeZone.m
//  RadarSDK
//
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import "RadarTimeZone.h"
#import "RadarUtils.h"

@implementation RadarTimeZone

- (instancetype _Nullable)initWithObject:(id)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    self = [super init];

    NSDictionary *dict = (NSDictionary *)object;

    id idObj = dict[@"id"];
    if ([idObj isKindOfClass:[NSString class]]) {
        __id = (NSString *)idObj;
    }

    id nameObj = dict[@"name"];
    if (nameObj && [nameObj isKindOfClass:[NSString class]]) {
        _name = (NSString *)nameObj;
    }

    id codeObj = dict[@"code"];
    if (codeObj && [codeObj isKindOfClass:[NSString class]]) {
        _code = (NSString *)codeObj;
    }

    id currentTimeObj = dict[@"currentTime"];
    if (currentTimeObj && [currentTimeObj isKindOfClass:[NSString class]]) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";
        _currentTime = [formatter dateFromString:(NSString *)currentTimeObj];
    }

    id utcOffsetObj = dict[@"utcOffset"];
    if (utcOffsetObj && [utcOffsetObj isKindOfClass:[NSNumber class]]) {
        _utcOffset = ((NSNumber *)utcOffsetObj).intValue;
    }

    id dstOffsetObj = dict[@"dstOffset"];
    if (dstOffsetObj && [dstOffsetObj isKindOfClass:[NSNumber class]]) {
        _dstOffset = ((NSNumber *)dstOffsetObj).intValue;
    }

    return self;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[@"_id"] = self._id;
    dict[@"name"] = self.name;
    dict[@"code"] = self.code;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";
    NSTimeZone *tz = nil;
    if (self._id) {
        tz = [NSTimeZone timeZoneWithName:self._id];
    }
    if (!tz) {
        tz = [NSTimeZone timeZoneForSecondsFromGMT:self.utcOffset * 3600];
    }
    formatter.timeZone = tz;
    
    dict[@"currentTime"] = [formatter stringFromDate:self.currentTime];
    dict[@"utcOffset"]   = @(self.utcOffset);
    dict[@"dstOffset"]   = @(self.dstOffset);
    
    return dict;
}

@end
