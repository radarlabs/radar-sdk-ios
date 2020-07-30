//
//  RadarRegion.m
//  RadarSDK
//
//  Copyright © 2019 Radar. All rights reserved.
//

#import "RadarCollectionAdditions.h"
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

#pragma mark - JSON coding

- (nullable instancetype)initWithObject:(nullable id)object {
    if (![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *dict = (NSDictionary *)object;

    NSString *_id = [dict radar_stringForKey:@"_id"];
    NSString *name = [dict radar_stringForKey:@"name"];
    NSString *code = [dict radar_stringForKey:@"code"];
    NSString *type = [dict radar_stringForKey:@"type"];
    NSString *flag = [dict radar_stringForKey:@"flag"];

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
