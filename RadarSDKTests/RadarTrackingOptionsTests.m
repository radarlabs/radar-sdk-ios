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

- (void)testDictionaryWithDates {
    RadarTrackingOptions *options = RadarTrackingOptions.presetResponsive;
    NSDate *startTrackingAfter = [NSDate new];
    options.startTrackingAfter = startTrackingAfter;
    NSDate *stopTrackingAfter = [startTrackingAfter dateByAddingTimeInterval:10000];
    options.stopTrackingAfter = stopTrackingAfter;

    NSMutableDictionary *optionsDict = [[NSMutableDictionary alloc] initWithDictionary: options.dictionaryValue];
    XCTAssertTrue([optionsDict[@"startTrackingAfter"] isKindOfClass:NSString.class]);
    XCTAssertTrue([optionsDict[@"stopTrackingAfter"] isKindOfClass:NSString.class]);

    RadarTrackingOptions *deserializedFromDateOptions = [RadarTrackingOptions trackingOptionsFromDictionary:optionsDict];
    NSTimeInterval startInterval = [deserializedFromDateOptions.startTrackingAfter timeIntervalSinceDate: startTrackingAfter];
    XCTAssertTrue(-1.0 < startInterval && startInterval < 1.0);

    NSTimeInterval stopInterval = [deserializedFromDateOptions.stopTrackingAfter timeIntervalSinceDate: stopTrackingAfter];
    XCTAssertTrue(-1.0 < stopInterval && stopInterval < 1.0);
}

- (void)testDictionaryWithDateStrings {
    RadarTrackingOptions *options = RadarTrackingOptions.presetResponsive;
    NSDate *startTrackingAfter = [NSDate new];
    options.startTrackingAfter = startTrackingAfter;
    NSDate *stopTrackingAfter = [startTrackingAfter dateByAddingTimeInterval:10000];
    options.stopTrackingAfter = stopTrackingAfter;

    NSMutableDictionary *optionsDict = [[NSMutableDictionary alloc] initWithDictionary: options.dictionaryValue];

    // Convert the tracking dates into ISO8601 strings.
    optionsDict[@"startTrackingAfter"] = [NSISO8601DateFormatter stringFromDate:startTrackingAfter
                                                                       timeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]
                                                                  formatOptions:NSISO8601DateFormatWithInternetDateTime];
    optionsDict[@"stopTrackingAfter"] = [NSISO8601DateFormatter stringFromDate:stopTrackingAfter
                                                                      timeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]
                                                                 formatOptions:NSISO8601DateFormatWithInternetDateTime];
    RadarTrackingOptions *deserializedFromStringOptions = [RadarTrackingOptions trackingOptionsFromDictionary:optionsDict];
    NSTimeInterval startInterval = [deserializedFromStringOptions.startTrackingAfter timeIntervalSinceDate: startTrackingAfter];
    XCTAssertTrue(-1.0 < startInterval && startInterval < 1.0);

    NSTimeInterval stopInterval = [deserializedFromStringOptions.stopTrackingAfter timeIntervalSinceDate: stopTrackingAfter];
    XCTAssertTrue(-1.0 < stopInterval && stopInterval < 1.0);
}

@end
