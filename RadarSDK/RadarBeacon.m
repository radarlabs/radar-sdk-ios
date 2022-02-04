//
//  RadarBeacon.m
//  RadarSDK
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "RadarBeacon.h"
#import "RadarBeacon+Internal.h"
#import "RadarCoordinate+Internal.h"

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

- (instancetype _Nullable)initWithId:(NSString *)_id
                         description:(NSString *)description
                                 tag:(NSString *)tag
                          externalId:(NSString *)externalId
                                uuid:(NSString *)uuid
                               major:(NSString *)major
                               minor:(NSString *)minor
                            metadata:(NSDictionary *_Nullable)metadata
                            geometry:(RadarCoordinate *)geometry {
    self = [super init];
    if (self) {
        __id = _id;
        ___description = description;
        _tag = tag;
        _externalId = externalId;
        _uuid = uuid;
        _major = major;
        _minor = minor;
        _metadata = metadata;
        _geometry = geometry;
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
    NSString *tag;
    NSString *externalId;
    NSString *uuid;
    NSString *major;
    NSString *minor;
    NSDictionary *metadata;
    RadarCoordinate *geometry = [[RadarCoordinate alloc] initWithCoordinate:CLLocationCoordinate2DMake(0, 0)];

    id idObj = dict[@"_id"];
    if (idObj && [idObj isKindOfClass:[NSString class]]) {
        _id = (NSString *)idObj;
    }

    id descriptionObj = dict[@"description"];
    if (descriptionObj && [descriptionObj isKindOfClass:[NSString class]]) {
        description = (NSString *)descriptionObj;
    }

    id tagObj = dict[@"tag"];
    if (tagObj && [tagObj isKindOfClass:[NSString class]]) {
        tag = (NSString *)tagObj;
    }

    id externalIdObj = dict[@"externalId"];
    if (externalIdObj && [externalIdObj isKindOfClass:[NSString class]]) {
        externalId = (NSString *)externalIdObj;
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

    id metadataObj = dict[@"metadata"];
    if (metadataObj && [metadataObj isKindOfClass:[NSDictionary class]]) {
        metadata = (NSDictionary *)metadataObj;
    }

    id geometryObj = dict[@"geometry"];
    if (geometryObj && [geometryObj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *geometryDict = (NSDictionary *)geometryObj;

        id geometryCoordinatesObj = geometryDict[@"coordinates"];
        if (!geometryCoordinatesObj || ![geometryCoordinatesObj isKindOfClass:[NSArray class]]) {
            return nil;
        }

        NSArray *geometryCoordinatesArr = (NSArray *)geometryCoordinatesObj;
        if (geometryCoordinatesArr.count != 2) {
            return nil;
        }

        id geometryCoordinatesLongitudeObj = geometryCoordinatesArr[0];
        id geometryCoordinatesLatitudeObj = geometryCoordinatesArr[1];
        if (!geometryCoordinatesLongitudeObj || !geometryCoordinatesLatitudeObj || ![geometryCoordinatesLongitudeObj isKindOfClass:[NSNumber class]] ||
            ![geometryCoordinatesLatitudeObj isKindOfClass:[NSNumber class]]) {
            return nil;
        }

        NSNumber *geometryCoordinatesLongitudeNumber = (NSNumber *)geometryCoordinatesLongitudeObj;
        NSNumber *geometryCoordinatesLatitudeNumber = (NSNumber *)geometryCoordinatesLatitudeObj;

        float geometryCoordinatesLongitudeFloat = [geometryCoordinatesLongitudeNumber floatValue];
        float geometryCoordinatesLatitudeFloat = [geometryCoordinatesLatitudeNumber floatValue];

        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(geometryCoordinatesLatitudeFloat, geometryCoordinatesLongitudeFloat);
        geometry = [[RadarCoordinate alloc] initWithCoordinate:coordinate];
    }

    return [[RadarBeacon alloc] initWithId:_id description:description tag:tag externalId:externalId uuid:uuid major:major minor:minor metadata:metadata geometry:geometry];
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
    [dict setValue:self.__description forKey:@"description"];
    [dict setValue:self.tag forKey:@"tag"];
    [dict setValue:self.externalId forKey:@"externalId"];
    [dict setValue:self.uuid forKey:@"uuid"];
    [dict setValue:self.major forKey:@"major"];
    [dict setValue:self.minor forKey:@"minor"];
    [dict setValue:self.metadata forKey:@"metadata"];
    return dict;
}

@end
