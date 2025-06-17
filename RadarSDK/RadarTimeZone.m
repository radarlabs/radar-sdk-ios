//
//  RadarTimeZone.m
//  RadarSDK
//
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import "RadarTimeZone.h"
#import "RadarUtils.h"

NSDateFormatter *_timezoneDateFormatter = nil;
NSDateFormatter * timezoneDateFormatter(void) {
    if (_timezoneDateFormatter == nil) {
        _timezoneDateFormatter = [[NSDateFormatter alloc] init];
        _timezoneDateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        [_timezoneDateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    }
    return _timezoneDateFormatter;
}

@implementation RadarTimeZone

- (instancetype _Nullable)initWithObject:(id)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    self = [super init];

    NSDictionary *dict = (NSDictionary *)object;

    id idObj = dict[@"id"];
    if ([idObj isKindOfClass:[NSString class]]) {
        _id = (NSString *)idObj;
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
        
        _currentTime = [timezoneDateFormatter() dateFromString:(NSString *)currentTimeObj];
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
    dict[@"id"] = self.id;
    dict[@"name"] = self.name;
    dict[@"code"] = self.code;
    dict[@"currentTime"] = [timezoneDateFormatter() stringFromDate:self.currentTime];
    dict[@"utcOffset"] = @(self.utcOffset);
    dict[@"dstOffset"] = @(self.dstOffset);
    return dict;
}

@end
