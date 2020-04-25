//
//  RadarCoordinate.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarCollectionAdditions.h"
#import "RadarCoordinate+Internal.h"

NS_ASSUME_NONNULL_BEGIN

@implementation RadarCoordinate

+ (NSArray<RadarCoordinate *> *_Nullable)coordinatesFromObject:(id _Nonnull)object {
    if (!object || ![object isKindOfClass:[NSArray class]]) {
        return nil;
    }

    NSArray *coordinatesArr = (NSArray *)object;

    NSMutableArray<RadarCoordinate *> *mutableCoordinates = [NSMutableArray<RadarCoordinate *> new];

    for (id coordinateObj in coordinatesArr) {
        RadarCoordinate *coordinate = [[RadarCoordinate alloc] initWithObject:coordinateObj];

        if (!coordinate) {
            return nil;
        }

        [mutableCoordinates addObject:coordinate];
    }

    return mutableCoordinates;
}

- (instancetype _Nullable)initWithObject:(id)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *dict = (NSDictionary *)object;

    id coordinatesObj = dict[@"coordinates"];
    if (!coordinatesObj || ![coordinatesObj isKindOfClass:[NSArray class]]) {
        return nil;
    }

    NSArray *coordinatesArr = (NSArray *)coordinatesObj;
    if (coordinatesArr.count != 2) {
        return nil;
    }

    id coordinatesLongitudeObj = coordinatesArr[0];
    id coordinatesLatitudeObj = coordinatesArr[1];
    if (!coordinatesLongitudeObj || !coordinatesLatitudeObj || ![coordinatesLongitudeObj isKindOfClass:[NSNumber class]] ||
        ![coordinatesLatitudeObj isKindOfClass:[NSNumber class]]) {
        return nil;
    }

    NSNumber *coordinatesLongitudeNumber = (NSNumber *)coordinatesLongitudeObj;
    NSNumber *coordinatesLatitudeNumber = (NSNumber *)coordinatesLatitudeObj;

    float coordinatesLongitudeFloat = [coordinatesLongitudeNumber floatValue];
    float coordinatesLatitudeFloat = [coordinatesLatitudeNumber floatValue];

    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(coordinatesLatitudeFloat, coordinatesLongitudeFloat);

    return [[RadarCoordinate alloc] initWithCoordinate:coordinate];
}

- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate {
    self = [super init];
    if (self) {
        _coordinate = coordinate;
    }
    return self;
}

- (NSDictionary *)dictionaryValue {
    return @{@"type": @"Point", @"coordinates": @[@(self.coordinate.longitude), @(self.coordinate.latitude)]};
}

+ (nullable NSArray *)fromObjectArray:(nullable id)objectArray {
    if (!objectArray || ![objectArray isKindOfClass:[NSArray class]]) {
        return nil;
    }

    NSMutableArray<RadarCoordinate *> *array = [NSMutableArray array];
    for (id object in (NSArray *)objectArray) {
        RadarCoordinate *value = [[RadarCoordinate alloc] initWithObject:object];
        if (!value) {
            return nil;
        }
        [array addObject:value];
    }

    return [array copy];
}

- (nullable instancetype)initWithObject:(nullable id)radarJSON {
    if (!radarJSON || ![radarJSON isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *dict = (NSDictionary *)radarJSON;

    NSArray *coordinates = [dict radar_arrayForKey:@"coordinates"];
    if (!coordinates || coordinates.count != 2 || ![coordinates[0] isKindOfClass:[NSNumber class]] || ![coordinates[1] isKindOfClass:[NSNumber class]]) {
        return nil;
    }
    float longitude = [(NSNumber *)coordinates[0] floatValue];
    if (longitude < -180 || longitude > 180) {
        return nil;
    }
    float latitude = [(NSNumber *)coordinates[1] floatValue];
    if (latitude < -90 || latitude > 90) {
        return nil;
    }

    return [[RadarCoordinate alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude, longitude)];
}

@end

NS_ASSUME_NONNULL_END
