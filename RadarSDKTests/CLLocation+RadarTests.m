//
//  CLLocation+RadarTests.m
//  RadarSDKTests
//
//  Copyright © 2022 Radar Labs, Inc. All rights reserved.
//

@import CoreLocation;
@import RadarSDK;
@import XCTest;
#import "../RadarSDK/CLLocation+Radar.h"

// "1060 West Addison? That's Wrigley Field!"
// https://www.imdb.com/title/tt0080455/characters/nm0000004
#define LAT 41.947746
#define LON -87.656036

@interface CLLocation_RadarTests : XCTestCase

@end

@implementation CLLocation_RadarTests

- (void)testValidLocationOk {
    CLLocation *location = [[CLLocation alloc] initWithCoordinate: CLLocationCoordinate2DMake(LAT, LON)
                                                         altitude:1.0
                                               horizontalAccuracy:1.0
                                                 verticalAccuracy:1.0
                                                        timestamp:[NSDate new]];
    XCTAssertTrue(location.isValid);
}

- (void)testIsValidForLocationWithInvalidLatitudeReturnsFalse {
    CLLocation *location = [[CLLocation alloc] initWithCoordinate: CLLocationCoordinate2DMake(0.0, LON)
                                                         altitude:1.0
                                               horizontalAccuracy:1.0
                                                 verticalAccuracy:1.0
                                                        timestamp:[NSDate new]];
    XCTAssertFalse(location.isValid);
}

- (void)testIsValidForLocationWithLatitudeNearZeroReturnsTrue {
    CLLocation *location = [[CLLocation alloc] initWithCoordinate: CLLocationCoordinate2DMake(0.00001, LON)
                                                         altitude:1.0
                                               horizontalAccuracy:1.0
                                                 verticalAccuracy:1.0
                                                        timestamp:[NSDate new]];
    XCTAssertTrue(location.isValid);
}

- (void)testIsValidForLocationWithInvalidLongitudeReturnsFalse {
    CLLocation *location = [[CLLocation alloc] initWithCoordinate: CLLocationCoordinate2DMake(LAT, 0.0)
                                                         altitude:1.0
                                               horizontalAccuracy:1.0
                                                 verticalAccuracy:1.0
                                                        timestamp:[NSDate new]];
    XCTAssertFalse(location.isValid);
}

- (void)testIsValidForLocationWithInvalidHorizontalAccuracyReturnsFalse {
    CLLocation *location = [[CLLocation alloc] initWithCoordinate: CLLocationCoordinate2DMake(LAT, LON)
                                                         altitude:1.0
                                               horizontalAccuracy:0.0
                                                 verticalAccuracy:1.0
                                                        timestamp:[NSDate new]];
    XCTAssertFalse(location.isValid);
}

@end
