//
//  RadarCoordinate.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarCoordinate+Internal.h"

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

@end
