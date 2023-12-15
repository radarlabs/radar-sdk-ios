//
//  RadarUserDefaultsTest.m
//  RadarSDKTests
//
//  Created by Kenny Hu on 12/14/23.
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface RadarUserDefaultsTest : XCTestCase

@end

@implementation RadarUserDefaultsTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

- (void)test_RadarUserDefault_setAndGetMigrationFlag {
    
}

- (void)test_RadarUserDefault_setAndGetBOOL {
    
}

- (void)test_RadarUserDefault_setAndGetString {
    
}

- (void)test_RadarUserDefault_setAndGetNSObj {
    
}

- (void)test_RadarUserDefault_setAndGetNSDictonary {
    
}

- (void)test_RadarUserDefault_migration {
    // verify that the migrationFlag is off
    // start with nsuserdefault filled with values
    // with each type
    // call the migration code
    // ensure that the migrationFlag is turned on
    // assert that the value is written to radarStrorageSystem and readable by the new radarSetting
}

@end
