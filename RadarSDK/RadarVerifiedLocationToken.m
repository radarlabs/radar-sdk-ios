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

- (instancetype _Nullable)initWithUser:(RadarUser *_Nullable)user
                                events:(NSArray<RadarEvent *> *_Nullable)events
                                 token:(NSString *_Nonnull)token
                             expiresAt:(NSDate *_Nonnull)expiresAt
                             expiresIn:(NSTimeInterval)expiresIn
                                passed:(BOOL)passed
                        failureReasons:(NSArray<NSString *> * _Nullable)failureReasons
                                   _id:(NSString * _Nonnull)_id
                                format:(RadarTokenFormat)format
                               fullDict:(NSDictionary *_Nonnull)fullDict {
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
        _format = format;
        _fullDict = fullDict;
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
    NSArray<NSString *> *failureReasons;
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
    
    id passedObj = dict[@"passed"];
    if (passedObj && [passedObj isKindOfClass:[NSNumber class]]) {
        NSNumber *passedNumber = (NSNumber *)passedObj;
        passed = [passedNumber boolValue];
    }
    
    id userObj = dict[@"user"];
    if (userObj && [userObj isKindOfClass:[NSDictionary class]]) {
        user = [[RadarUser alloc] initWithObject:userObj];
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
    
    RadarTokenFormat format = RadarTokenFormatJWS;
    id formatObj = dict[@"format"];
    if (formatObj && [formatObj isKindOfClass:[NSString class]] && [[(NSString *)formatObj uppercaseString] isEqualToString:@"JWE"]) {
        format = RadarTokenFormatJWE;
    }

    // legacy JWS behavior: default absent failureReasons to an empty array. In JWE (protected)
    // mode the reasons only exist inside the encrypted token, so keep nil rather than reporting
    // "no failures" — the token can have passed == NO with reasons that are simply unavailable.
    if (format == RadarTokenFormatJWS && !failureReasons) {
        failureReasons = @[];
    }
    
    // in JWE (protected) mode the user and events only exist inside the encrypted token
    BOOL hasRequiredFields = token && expiresAt && (format == RadarTokenFormatJWE || (user && events));
    if (hasRequiredFields) {
        return [[RadarVerifiedLocationToken alloc] initWithUser:user events:events token:token expiresAt:expiresAt expiresIn:expiresIn passed:passed failureReasons:failureReasons _id:_id format:format fullDict:dict];
    }
    
    return nil;
}

- (NSDictionary *)dictionaryValue {
    return self.fullDict;
}

@end
