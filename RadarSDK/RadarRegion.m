//
//  RadarRegion.m
//  RadarSDK
//
//  Copyright © 2019 Radar. All rights reserved.
//

#import "RadarRegion+Internal.h"

@implementation RadarRegion

- (instancetype)initWithId:(nonnull NSString *)_id name:(nonnull NSString *)name code:(nonnull NSString *)code type:(nonnull NSString *)type flag:(nullable NSString *)flag {
    self = [super init];
    if (self) {
        __id = _id;
        _name = name;
        _code = code;
        _type = type;
        _flag = flag;
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

    if (_id && name && code && type) {
        return [[RadarRegion alloc] initWithId:_id name:name code:code type:type flag:flag];
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
    return dict;
}

@end
