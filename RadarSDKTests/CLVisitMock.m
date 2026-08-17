//
//  CLVisitMock.m
//  RadarSDKTests
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "CLVisitMock.h"

@interface CLVisitMock ()

@property(nonatomic, assign) CLLocationCoordinate2D mockCoordinate;
@property(nonatomic, assign) CLLocationAccuracy mockHorizontalAccuracy;
@property(nonatomic, copy) NSDate *mockArrivalDate;
@property(nonatomic, copy) NSDate *mockDepartureDate;

@end

@implementation CLVisitMock

- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate
                horizontalAccuracy:(CLLocationAccuracy)horizontalAccuracy
                       arrivalDate:(NSDate *)arrivalDate
                     departureDate:(NSDate *)departureDate {
    self = [super init];
    if (self) {
        _mockCoordinate = coordinate;
        _mockHorizontalAccuracy = horizontalAccuracy;
        _mockArrivalDate = [arrivalDate copy];
        _mockDepartureDate = [departureDate copy];
    }
    return self;
}

- (CLLocationCoordinate2D)coordinate {
    return self.mockCoordinate;
}

- (CLLocationAccuracy)horizontalAccuracy {
    return self.mockHorizontalAccuracy;
}

- (NSDate *)arrivalDate {
    return self.mockArrivalDate;
}

- (NSDate *)departureDate {
    return self.mockDepartureDate;
}

@end
