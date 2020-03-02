//
//  CLVisitMock.m
//  RadarSDKTests
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "CLVisitMock.h"

@implementation CLVisitMock

- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate
                horizontalAccuracy:(CLLocationAccuracy)horizontalAccuracy
                       arrivalDate:(NSDate *)arrivalDate
                     departureDate:(NSDate *)departureDate {
    self = [super init];
    if (self) {
        self.coordinate = coordinate;
        self.horizontalAccuracy = horizontalAccuracy;
        self.arrivalDate = arrivalDate;
        self.departureDate = departureDate;
    }
    return self;
}

- (void)setCoordinate:(CLLocationCoordinate2D)coordinate {
    self.coordinate = coordinate;
}

- (void)setHorizontalAccuracy:(CLLocationAccuracy)horizontalAccuracy {
    self.horizontalAccuracy = horizontalAccuracy;
}

- (void)setArrivalDate:(NSDate *)arrivalDate {
    self.arrivalDate = arrivalDate;
}

- (void)setDepartureDate:(NSDate *)departureDate {
    self.departureDate = departureDate;
}

@end
