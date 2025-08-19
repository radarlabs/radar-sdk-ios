//
//  CLLocation+RadarTests.m
//  RadarSDKTests
//
//  Copyright © 2022 Radar Labs, Inc. All rights reserved.
//

@import CoreLocation;
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
    [self assertValidLocation:LAT longitude:LON horizontalAccuracy:1.0 shouldBeValid:true];
}

- (void)testIsValidForLocationWithInvalidLatitudeReturnsFalse {
    [self assertValidLocation:0.0 longitude:LON horizontalAccuracy:1.0 shouldBeValid:false];
}

- (void)testIsValidForLocationWithLatitudeNearZeroReturnsTrue {
    [self assertValidLocation:0.000001 longitude:LON horizontalAccuracy:1.0 shouldBeValid:true];
}

- (void)testIsValidForLocationWithLatitudeWithinFloatEpsilonOfZeroReturnsFalse {
    [self assertValidLocation:0.000000009 longitude:LON horizontalAccuracy:1.0 shouldBeValid:false];
}

- (void)testIsValidForLocationWithInvalidLongitudeReturnsFalse {
    [self assertValidLocation:LAT longitude:0.0 horizontalAccuracy:1.0 shouldBeValid:false];
}

- (void)testIsValidForLocationWithInvalidHorizontalAccuracyReturnsFalse {
    [self assertValidLocation:LAT longitude:LON horizontalAccuracy:0.0 shouldBeValid:false];
}

- (void)assertValidLocation:(CLLocationDegrees)latitude
                  longitude:(CLLocationDegrees)longitude
         horizontalAccuracy:(CLLocationDegrees)horizontalAccuracy
              shouldBeValid:(BOOL)isValid {
    CLLocationCoordinate2D coords = CLLocationCoordinate2DMake(latitude, longitude);
    CLLocation *location = [[CLLocation alloc] initWithCoordinate:coords altitude:1.0 horizontalAccuracy:horizontalAccuracy verticalAccuracy:1.0 timestamp:[NSDate new]];
    XCTAssertEqual(location.isValid, isValid);
}

@end
