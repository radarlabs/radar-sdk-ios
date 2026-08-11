//
//  CLVisitMock.m
//  RadarSDKTests
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "CLVisitMock.h"

@implementation CLVisitMock {
    CLLocationCoordinate2D _storedCoordinate;
    CLLocationAccuracy _storedHorizontalAccuracy;
    NSDate *_storedArrivalDate;
    NSDate *_storedDepartureDate;
}

- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate
                horizontalAccuracy:(CLLocationAccuracy)horizontalAccuracy
                       arrivalDate:(NSDate *)arrivalDate
                     departureDate:(NSDate *)departureDate {
    self = [super init];
    if (self) {
        _storedCoordinate = coordinate;
        _storedHorizontalAccuracy = horizontalAccuracy;
        _storedArrivalDate = arrivalDate;
        _storedDepartureDate = departureDate;
    }
    return self;
}

- (CLLocationCoordinate2D)coordinate {
    return _storedCoordinate;
}

- (CLLocationAccuracy)horizontalAccuracy {
    return _storedHorizontalAccuracy;
}

- (NSDate *)arrivalDate {
    return _storedArrivalDate;
}

- (NSDate *)departureDate {
    return _storedDepartureDate;
}

@end
