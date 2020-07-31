//
//  RadarCoordinate.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarCollectionAdditions.h"
#import "RadarCoordinate+Internal.h"

@implementation RadarCoordinate

+ (NSArray<RadarCoordinate *> *_Nullable)coordinatesFromObject:(id _Nonnull)object {
    FROM_JSON_ARRAY_DEFAULT_IMP(object, RadarCoordinate);
}

- (instancetype _Nullable)initWithObject:(id)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *dict = (NSDictionary *)object;

    return [self initWithJSONCoordinate:dict[@"coordinates"]];
}

+ (NSArray<RadarCoordinate *> *_Nullable)coordinatesFromJSONCoordinates:(id)coordinateArrayObject {
    if (!coordinateArrayObject || ![coordinateArrayObject isKindOfClass:[NSArray class]]) {
        return nil;
    }

    NSMutableArray<RadarCoordinate *> *mutableArray = [NSMutableArray array];

    for (id coordinateObject in (NSArray *)coordinateArrayObject) {
        RadarCoordinate *coordinate = [[RadarCoordinate alloc] initWithJSONCoordinate:coordinateObject];
        if (!coordinate) {
            return nil;
        }
        [mutableArray addObject:coordinate];
    }
    return [mutableArray copy];
}

- (instancetype _Nullable)initWithJSONCoordinate:(id)coordinateObject {
    if (!coordinateObject || ![coordinateObject isKindOfClass:[NSArray class]]) {
        return nil;
    }

    NSArray *coordinate = (NSArray *)coordinateObject;

    if (!coordinate || coordinate.count != 2 || ![coordinate[0] isKindOfClass:[NSNumber class]] || ![coordinate[1] isKindOfClass:[NSNumber class]]) {
        return nil;
    }
    float longitude = [(NSNumber *)coordinate[0] floatValue];
    if (longitude < -180 || longitude > 180) {
        return nil;
    }
    float latitude = [(NSNumber *)coordinate[1] floatValue];
    if (latitude < -90 || latitude > 90) {
        return nil;
    }

    return [self initWithCoordinate:CLLocationCoordinate2DMake(latitude, longitude)];
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
