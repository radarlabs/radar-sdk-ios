//
//  RadarRegion.m
//  RadarSDK
//
//  Copyright © 2019 Radar. All rights reserved.
//

#import "RadarRegion+Internal.h"

@implementation RadarRegion

- (instancetype)initWithId:(nonnull NSString *)_id name:(nonnull NSString *)name code:(nonnull NSString *)code type:(nonnull NSString *)type {
    self = [super init];
    if (self) {
        __id = _id;
        _name = name;
        _code = code;
        _type = type;
    }
    return self;
}

- (nullable instancetype)initWithObject:(nullable id)object {
    if (![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    NSDictionary *regionDict = (NSDictionary *)object;

    NSString *_id = @"";
    NSString *name = @"";
    NSString *code = @"";
    NSString *type = @"";
    
    id eventIdObj = regionDict[@"_id"];
    if ([eventIdObj isKindOfClass:[NSString class]]) {
        _id = (NSString *)eventIdObj;
    }

    id eventNameObj = regionDict[@"name"];
    if ([eventNameObj isKindOfClass:[NSString class]]) {
        name = (NSString *)eventNameObj;
    }
    
    id eventCodeObj = regionDict[@"code"];
    if ([eventCodeObj isKindOfClass:[NSString class]]) {
        code = (NSString *)eventCodeObj;
    }
    
    id eventTypeObj = regionDict[@"type"];
    if ([eventTypeObj isKindOfClass:[NSString class]]) {
        type = (NSString *)eventTypeObj;
    }
    
    return [[RadarRegion alloc] initWithId:_id name:name code:code type:type];
}

@end
