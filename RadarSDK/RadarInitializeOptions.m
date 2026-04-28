//
//  RadarInitializeOptions.m
//  RadarSDK
//
//  Created by Kenny Hu on 9/10/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RadarInitializeOptions.h"


@implementation RadarInitializeOptions

- (instancetype)init {
    self = [super init];
    if (self) {
        _autoLogNotificationConversions = NO;
        _autoHandleNotificationDeepLinks = NO;
        _silentPush = NO;
        _trackVerifiedAutoFailover = NO;
    }
    return self;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[@"autoLogNotificationConversions"] = @(_autoLogNotificationConversions);
    dict[@"autoHandleNotificationDeepLinks"] = @(_autoHandleNotificationDeepLinks);
    dict[@"silentPush"] = @(_silentPush);
    dict[@"trackVerifiedAutoFailover"] = @(_trackVerifiedAutoFailover);
    return dict;
}

- (instancetype)initWithDict:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _autoLogNotificationConversions = [dict[@"autoLogNotificationConversions"] boolValue];
        _autoHandleNotificationDeepLinks = [dict[@"autoHandleNotificationDeepLinks"] boolValue];
        _silentPush = [dict[@"silentPush"] boolValue];
        _trackVerifiedAutoFailover = [dict[@"trackVerifiedAutoFailover"] boolValue];
    }
    return self;
}

@end
