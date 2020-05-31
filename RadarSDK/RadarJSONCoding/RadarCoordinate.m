//
//  RadarCoordinate.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarCollectionAdditions.h"
#import "RadarCoordinate+Internal.h"
#import "RadarUtils.h"

NS_ASSUME_NONNULL_BEGIN

@implementation RadarCoordinate

#pragma mark - JSONCoding

+ (nullable NSArray<RadarCoordinate *> *)fromObjectArray:(nullable id)objectArray {
    if (!objectArray || ![objectArray isKindOfClass:[NSArray class]]) {
        return nil;
    }

    NSArray *coordinatesArr = (NSArray *)objectArray;

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

- (nullable instancetype)initWithObject:(nullable id)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *dict = (NSDictionary *)object;

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

- (NSDictionary *)dictionaryValue {
    return @{@"type": @"Point", @"coordinates": @[@(self.coordinate.longitude), @(self.coordinate.latitude)]};
}

#pragma mark - copy and equal

- (id)copyWithZone:(nullable NSZone *)zone {
    return self;
}

- (BOOL)isEqual:(RadarCoordinate *)object {
    if (self == object) {
        return YES;
    } else if (object == nil || ![object isKindOfClass:[self class]]) {
        return NO;
    }

    return [RadarUtils compareDouble:_coordinate.latitude withAnotherDouble:object->_coordinate.latitude] && [RadarUtils compareDouble:_coordinate.longitude
                                                                                                                     withAnotherDouble:object->_coordinate.longitude];
}

#pragma mark - designated init

- (nullable instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate {
    self = [super init];
    if (self) {
        _coordinate = coordinate;
    }
    return self;
}

@end

NS_ASSUME_NONNULL_END
