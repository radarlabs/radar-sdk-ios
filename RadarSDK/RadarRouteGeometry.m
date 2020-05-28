//
//  RadarRouteGeometry.m
//  RadarSDK
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "RadarRouteGeometry.h"

#import "RadarCoordinate+Internal.h"

@implementation RadarRouteGeometry

- (instancetype)initWithCoordinates:(NSArray *)coordinates {
    self = [super init];
    if (self) {
        _coordinates = coordinates;
    }
    return self;
}

- (instancetype _Nullable)initWithObject:(id)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *dict = (NSDictionary *)object;

    id coordinatesObj = dict[@"coordinates"];
    if (![coordinatesObj isKindOfClass:[NSArray class]]) {
        return nil;
    }

    NSArray *coordinatesArr = (NSArray *)coordinatesObj;

    NSMutableArray<RadarCoordinate *> *mutableCoordinates = [NSMutableArray<RadarCoordinate *> arrayWithCapacity:coordinatesArr.count];

    for (uint i = 0; i < coordinatesArr.count; i++) {
        id coordinateObj = coordinatesArr[i];
        if (![coordinateObj isKindOfClass:[NSArray class]]) {
            return nil;
        }

        NSArray *coordinateArr = (NSArray *)coordinateObj;
        if (coordinateArr.count != 2) {
            return nil;
        }

        id coordinateLongitudeObj = coordinateArr[0];
        id coordinateLatitudeObj = coordinateArr[1];
        if (![coordinateLongitudeObj isKindOfClass:[NSNumber class]] || ![coordinateLatitudeObj isKindOfClass:[NSNumber class]]) {
            return nil;
        }

        float polygonCoordinateLongitude = [((NSNumber *)coordinateLongitudeObj) floatValue];
        float polygonCoordinateLatitude = [((NSNumber *)coordinateLatitudeObj) floatValue];

        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(polygonCoordinateLatitude, polygonCoordinateLongitude);
        mutableCoordinates[i] = [[RadarCoordinate alloc] initWithCoordinate:coordinate];
    }

    return [[RadarRouteGeometry alloc] initWithCoordinates:mutableCoordinates];
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setValue:@"LineString" forKey:@"type"];
    if (self.coordinates) {
        NSMutableArray<NSArray *> *mutableCoordinates = [NSMutableArray<NSArray *> new];
        for (uint i = 0; i < self.coordinates.count; i++) {
            CLLocationCoordinate2D coordinate = self.coordinates[i].coordinate;
            mutableCoordinates[i] = @[@(coordinate.longitude), @(coordinate.latitude)];
        }
        [dict setValue:mutableCoordinates forKey:@"coordinates"];
    }
    return dict;
}

@end
