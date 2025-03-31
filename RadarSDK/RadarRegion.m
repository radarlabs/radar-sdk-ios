//
//  RadarRegion.m
//  RadarSDK
//
//  Copyright © 2019 Radar. All rights reserved.
//

#import "RadarRegion+Internal.h"

@implementation RadarRegion

- (instancetype)initWithId:(nonnull NSString *)_id
                      name:(nonnull NSString *)name
                      code:(nonnull NSString *)code
                      type:(nonnull NSString *)type
                      flag:(nullable NSString *)flag
                   allowed:(BOOL)allowed
                    passed:(BOOL)passed
           inExclusionZone:(BOOL)inExclusionZone
              inBufferZone:(BOOL)inBufferZone
          distanceToBorder:(double)distanceToBorder
                  expected:(BOOL)expected{
    self = [super init];
    if (self) {
        __id = _id;
        _name = name;
        _code = code;
        _type = type;
        _flag = flag;
        _allowed = allowed;
        _passed = passed;
        _inExclusionZone = inExclusionZone;
        _inBufferZone = inBufferZone;
        _distanceToBorder = distanceToBorder;
        _expected = expected;
    }
    return self;
}

- (nullable instancetype)initWithObject:(nullable id)object {
    if (![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *dict = (NSDictionary *)object;

    NSString *_id = @"";
    NSString *name = @"";
    NSString *code = @"";
    NSString *type = @"";
    NSString *flag = @"";
    BOOL allowed = false;
    BOOL passed = false;
    BOOL inExclusionZone = false;
    BOOL inBufferZone = false;
    double distanceToBorder = 0;
    BOOL expected = false;

    id idObj = dict[@"_id"];
    if ([idObj isKindOfClass:[NSString class]]) {
        _id = (NSString *)idObj;
    }

    id nameObj = dict[@"name"];
    if ([nameObj isKindOfClass:[NSString class]]) {
        name = (NSString *)nameObj;
    }

    id codeObj = dict[@"code"];
    if ([codeObj isKindOfClass:[NSString class]]) {
        code = (NSString *)codeObj;
    }

    id typeObj = dict[@"type"];
    if ([typeObj isKindOfClass:[NSString class]]) {
        type = (NSString *)typeObj;
    }

    id flagObj = dict[@"flag"];
    if (flagObj && [flagObj isKindOfClass:[NSString class]]) {
        flag = (NSString *)flagObj;
    }

    id allowedObj = dict[@"allowed"];
    if (allowedObj && [allowedObj isKindOfClass:[NSNumber class]]) {
        NSNumber *allowedNumber = (NSNumber *)allowedObj;

        allowed = [allowedNumber boolValue];
    }
    
    id passedObj = dict[@"passed"];
    if (passedObj && [passedObj isKindOfClass:[NSNumber class]]) {
        NSNumber *passedNumber = (NSNumber *)passedObj;

        passed = [passedNumber boolValue];
    }
    
    id inExclusionZoneObj = dict[@"inExclusionZone"];
    if (inExclusionZoneObj && [inExclusionZoneObj isKindOfClass:[NSNumber class]]) {
        NSNumber *inExclusionZoneNumber = (NSNumber *)inExclusionZoneObj;

        inExclusionZone = [inExclusionZoneNumber boolValue];
    }
    
    id inBufferZoneObj = dict[@"inBufferZone"];
    if (inBufferZoneObj && [inBufferZoneObj isKindOfClass:[NSNumber class]]) {
        NSNumber *inBufferZoneNumber = (NSNumber *)inBufferZoneObj;

        inBufferZone = [inBufferZoneNumber boolValue];
    }
    
    id distanceToBorderObj = dict[@"distanceToBorder"];
    if ([distanceToBorderObj isKindOfClass:[NSNumber class]]) {
        distanceToBorder = ((NSNumber *)distanceToBorderObj).doubleValue;
    }
    
    id expectedObj = dict[@"expected"];
    if (expectedObj && [expectedObj isKindOfClass:[NSNumber class]]) {
        NSNumber *expectedNumber = (NSNumber *)expectedObj;

        expected = [expectedNumber boolValue];
    }

    if (_id && name && code && type) {
        return [[RadarRegion alloc] initWithId:_id name:name code:code type:type flag:flag allowed:allowed passed:passed inExclusionZone:inExclusionZone inBufferZone:inBufferZone distanceToBorder:distanceToBorder expected:expected];
    }

    return nil;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setValue:self._id forKey:@"_id"];
    [dict setValue:self.name forKey:@"name"];
    [dict setValue:self.code forKey:@"code"];
    [dict setValue:self.type forKey:@"type"];
    if (self.flag) {
        [dict setValue:self.flag forKey:@"flag"];
    }
    [dict setValue:@(self.allowed) forKey:@"allowed"];
    [dict setValue:@(self.passed) forKey:@"passed"];
    [dict setValue:@(self.inExclusionZone) forKey:@"inExclusionZone"];
    [dict setValue:@(self.inBufferZone) forKey:@"inBufferZone"];
    [dict setValue:@(self.distanceToBorder) forKey:@"distanceToBorder"];
    [dict setValue:@(self.expected) forKey:@"expected"];
    return dict;
}

@end
