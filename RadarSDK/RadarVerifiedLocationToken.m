//
//  RadarVerifiedLocationToken.m
//  RadarSDK
//
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import "RadarVerifiedLocationToken.h"
#import "RadarEvent+Internal.h"
#import "RadarVerifiedLocationToken+Internal.h"
#import "RadarUser+Internal.h"
#import "RadarUtils.h"

@implementation RadarVerifiedLocationToken

- (instancetype _Nullable)initWithUser:(RadarUser *_Nonnull)user
                                events:(NSArray<RadarEvent *> *_Nonnull)events
                                 token:(NSString *_Nonnull)token
                             expiresAt:(NSDate *_Nonnull)expiresAt
                             expiresIn:(NSTimeInterval)expiresIn
                                passed:(BOOL)passed
                        failureReasons:(NSArray<NSString *> * _Nonnull)failureReasons
                                   _id:(NSString * _Nonnull)_id
                               rawDict:(NSDictionary * _Nonnull)rawDict {
    self = [super init];
    if (self) {
        _user = user;
        _events = events;
        _token = token;
        _expiresAt = expiresAt;
        _expiresIn = expiresIn;
        _passed = passed;
        _failureReasons = failureReasons;
        __id = _id;
        _rawDict = rawDict;
    }
    return self;
}

- (instancetype _Nullable)initWithObject:(id _Nonnull)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    NSDictionary *dict = (NSDictionary *)object;
    
    RadarUser *user;
    NSArray<RadarEvent *> *events;
    NSString *token;
    NSDate *expiresAt;
    NSTimeInterval expiresIn = 0;
    BOOL passed = NO;
    NSArray<NSString *> *failureReasons = @[];
    NSString *_id;
    
    id tokenObj = dict[@"token"];
    if (tokenObj && [tokenObj isKindOfClass:[NSString class]]) {
        token = (NSString *)tokenObj;
    }
    
    id expiresAtObj = dict[@"expiresAt"];
    if (expiresAtObj && [expiresAtObj isKindOfClass:[NSString class]]) {
        NSString *expiresAtStr = (NSString *)expiresAtObj;
        expiresAt = [RadarUtils.isoDateFormatter dateFromString:expiresAtStr];
    }
    
    id expiresInObj = dict[@"expiresIn"];
    if (expiresInObj && [expiresInObj isKindOfClass:[NSNumber class]]) {
        NSNumber *expiresInNumber = (NSNumber *)expiresInObj;
        expiresIn = [expiresInNumber floatValue];
    }
    
    id userObj = dict[@"user"];
    if (userObj && [userObj isKindOfClass:[NSDictionary class]]) {
        user = [[RadarUser alloc] initWithObject:userObj];
        
        passed = user && user.fraud && user.fraud.passed && user.country && user.country.passed && user.state && user.state.passed;
    }
    
    id eventsObj = dict[@"events"];
    if (eventsObj && [eventsObj isKindOfClass:[NSArray class]]) {
        events = [RadarEvent eventsFromObject:eventsObj];
    }
    
    id failureReasonsObj = dict[@"failureReasons"];
    if (failureReasonsObj && [failureReasonsObj isKindOfClass:[NSArray class]]) {
        failureReasons = (NSArray *)failureReasonsObj;
    }
    
    id idObj = dict[@"_id"];
    if (idObj && [idObj isKindOfClass:[NSString class]]) {
        _id = (NSString *)idObj;
    }
    
    if (user && events && token && expiresAt) {
        return [[RadarVerifiedLocationToken alloc] initWithUser:user events:events token:token expiresAt:expiresAt expiresIn:expiresIn passed:passed failureReasons:failureReasons _id:_id rawDict:dict];
    }
    
    return nil;
}

- (NSDictionary *)dictionaryValue {
    return self.rawDict;
}

@end
