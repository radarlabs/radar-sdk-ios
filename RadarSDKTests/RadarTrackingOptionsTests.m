//  Copyright © 2022 Radar Labs, Inc. All rights reserved.

@import RadarSDK;
@import XCTest;

@interface RadarTrackingOptionsTests : XCTestCase

@end

@implementation RadarTrackingOptionsTests

- (void)testDictionarySerialization {
    RadarTrackingOptions *options = RadarTrackingOptions.presetResponsive;
    options.startTrackingAfter = [NSDate new];
    options.stopTrackingAfter = [NSDate new];
    NSDictionary *optionsDict = options.dictionaryValue;
    RadarTrackingOptions *deserializedOptions = [RadarTrackingOptions trackingOptionsFromDictionary:optionsDict];
    XCTAssertTrue([options isEqual:deserializedOptions]);
}

- (void)testIsEquals {
    RadarTrackingOptions *optionsA = RadarTrackingOptions.presetResponsive;
    RadarTrackingOptions *optionsB = RadarTrackingOptions.presetResponsive;
    XCTAssertTrue([optionsA isEqual:optionsB]);

    NSDate *dateA = [NSDate new];
    NSDate *dateB = [NSDate new];
    XCTAssertTrue([dateA isEqualToDate:dateB]);

    optionsA.startTrackingAfter = dateA;
    XCTAssertFalse([optionsA isEqual:optionsB]);

    optionsB.startTrackingAfter = optionsA.startTrackingAfter;
    XCTAssertTrue([optionsA isEqual:optionsB]);

    optionsA.stopTrackingAfter = dateB;
    XCTAssertFalse([optionsA isEqual:optionsB]);

    optionsB.stopTrackingAfter = dateB;
    XCTAssertTrue([optionsA isEqual:optionsB]);
}

- (void)testDictionaryJSONSerialization {
    RadarTrackingOptions *options = RadarTrackingOptions.presetResponsive;
    options.startTrackingAfter = [NSDate new];
    NSDictionary *optionsDict = options.dictionaryValue;
    NSData *data = [NSJSONSerialization dataWithJSONObject:optionsDict options:0 error:NULL];
    NSDictionary *deserializedOptionDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    RadarTrackingOptions *deserializedOptions = [RadarTrackingOptions trackingOptionsFromDictionary:deserializedOptionDict];
    XCTAssertTrue([options isEqual:deserializedOptions]);
}

@end
