//
//  RadarBeacon.m
//  RadarSDK
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "RadarBeacon.h"
#import "RadarBeacon+Internal.h"

@implementation RadarBeacon

+ (NSArray<RadarBeacon *> *_Nullable)beaconsFromObject:(id _Nonnull)object {
    if (!object || ![object isKindOfClass:[NSArray class]]) {
        return nil;
    }

    NSArray *beaconsArr = (NSArray *)object;
    NSMutableArray<RadarBeacon *> *mutableBeacons = [NSMutableArray<RadarBeacon *> new];

    for (id beaconObj in beaconsArr) {
        RadarBeacon *beacon = [[RadarBeacon alloc] initWithObject:beaconObj];
        if (!beacon) {
            return nil;
        }
        [mutableBeacons addObject:beacon];
    }

    return mutableBeacons;
}

- (instancetype _Nullable)initWithId:(NSString *)_id description:(NSString *)description uuid:(NSString *)uuid major:(NSString *)major minor:(NSString *)minor {
    self = [super init];
    if (self) {
        __id = _id;
        __description = description;
        _uuid = uuid;
        _major = major;
        _minor = minor;
    }
    return self;
}

- (instancetype _Nullable)initWithObject:(id _Nonnull)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *dict = (NSDictionary *)object;

    NSString *_id;
    NSString *description;
    NSString *uuid;
    NSString *major;
    NSString *minor;

    id idObj = dict[@"_id"];
    if (idObj && [idObj isKindOfClass:[NSString class]]) {
        _id = (NSString *)idObj;
    }
    
    id descriptionObj = dict[@"description"];
    if (descriptionObj && [descriptionObj isKindOfClass:[NSString class]]) {
        __description = (NSString *)descriptionObj;
    }

    id uuidObj = dict[@"uuid"];
    if (uuidObj && [uuidObj isKindOfClass:[NSString class]]) {
        uuid = (NSString *)uuidObj;
    }

    id majorObj = dict[@"major"];
    if (majorObj && [majorObj isKindOfClass:[NSString class]]) {
        major = (NSString *)majorObj;
    }

    id minorObj = dict[@"minor"];
    if (minorObj && [minorObj isKindOfClass:[NSString class]]) {
        minor = (NSString *)minorObj;
    }

    return [[RadarBeacon alloc] initWithId:_id description:description uuid:uuid major:major minor:minor];
}

+ (NSArray<NSDictionary *> *)arrayForBeacons:(NSArray<RadarBeacon *> *)beacons {
    if (!beacons) {
        return nil;
    }

    NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:beacons.count];
    for (RadarBeacon *beacon in beacons) {
        NSDictionary *dict = [beacon dictionaryValue];
        [arr addObject:dict];
    }
    return arr;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setValue:self._id forKey:@"_id"];
    [dict setValue:self.description forKey:@"description"];
    [dict setValue:self.uuid forKey:@"uuid"];
    [dict setValue:self.major forKey:@"major"];
    [dict setValue:self.minor forKey:@"minor"];
    return dict;
}

@end
