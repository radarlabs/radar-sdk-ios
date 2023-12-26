//
//  RadarUserDefaultsTest.m
//  RadarSDKTests
//
//  Created by Kenny Hu on 12/14/23.
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "../RadarSDK/RadarUserDefaults.h"

@interface RadarUserDefaultsTest : XCTestCase
@property (nonatomic, strong) RadarUserDefaults *radarUserDefault;

@end

@implementation RadarUserDefaultsTest

- (void)setUp {
    [super setUp];
    self.radarUserDefault = [RadarUserDefaults sharedInstance];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)test_RadarUserDefault_setAndGetMigrationFlag {
    [self.radarUserDefault setMigrationCompleteFlag:YES];
    XCTAssertTrue(self.radarUserDefault.migrationCompleteFlag);
    [self.radarUserDefault setMigrationCompleteFlag:NO];
    XCTAssertFalse(self.radarUserDefault.migrationCompleteFlag);
}

- (void)test_RadarUserDefault_setAndGetBOOL {
    [self.radarUserDefault setBool:YES forKey:@"yesValue"];
    [self.radarUserDefault setBool:NO forKey:@"noValue"];
    XCTAssertTrue([self.radarUserDefault boolForKey:@"yesValue"]);
    XCTAssertFalse([self.radarUserDefault boolForKey:@"noValue"]);
    [self.radarUserDefault setBool:YES forKey:@"noValue"];
    XCTAssertTrue([self.radarUserDefault boolForKey:@"noValue"]);
    
    
}

- (void)test_RadarUserDefault_setAndGetString {
    [self.radarUserDefault setString:@"123abc!@#" forKey:@"string1"];
    XCTAssertEqualObjects(@"123abc!@#", [self.radarUserDefault stringForKey:@"string1"]);
    [self.radarUserDefault setString:@"I like working here" forKey:@"string1"];
    XCTAssertEqualObjects(@"I like working here", [self.radarUserDefault stringForKey:@"string1"]);
    [self.radarUserDefault setString:@"hello world" forKey:@"string2"];
    XCTAssertEqualObjects(@"hello world", [self.radarUserDefault stringForKey:@"string2"]);
}

- (void)test_RadarUserDefault_setAndGetNSObj {
    NSArray<NSString *> *stringArrays = @[@"Hello", @"World"];
    NSObject *obj1 = stringArrays;
    NSArray<NSNumber *> *intArrays = @[@1, @2, @3];
    NSObject *obj2 = intArrays;
    [self.radarUserDefault setObject:obj1 forKey:@"obj1"];
    [self.radarUserDefault setObject:obj2 forKey:@"obj2"];
    XCTAssertEqualObjects(stringArrays, [self.radarUserDefault objectForKey:@"obj1"]);
    XCTAssertEqualObjects(intArrays, [self.radarUserDefault objectForKey:@"obj2"]);

}

- (void)test_RadarUserDefault_setAndGetNSDictonary {
    NSDictionary<NSString *, NSString *> *dic1 = @{@"key1": @"value1", @"key2": @"value2"};
    NSDictionary<NSString *, NSNumber *> *dic2 = @{@"key1": @1, @"key2": @2};
    [self.radarUserDefault setDictionary:dic1 forKey:@"dic1"];
    [self.radarUserDefault setDictionary:dic2 forKey:@"dic2"];
    XCTAssertEqualObjects(dic1, [self.radarUserDefault dictionaryForKey:@"dic1"]);
    XCTAssertEqualObjects(dic2, [self.radarUserDefault dictionaryForKey:@"dic2"]);
    //test fields are equal
    XCTAssertEqualObjects(dic1[@"key1"], [self.radarUserDefault dictionaryForKey:@"dic1"][@"key1"]);
    XCTAssertEqualObjects(dic1[@"key2"], [self.radarUserDefault dictionaryForKey:@"dic1"][@"key2"]);
    XCTAssertEqualObjects(dic2[@"key1"], [self.radarUserDefault dictionaryForKey:@"dic2"][@"key1"]);
    XCTAssertEqualObjects(dic2[@"key2"], [self.radarUserDefault dictionaryForKey:@"dic2"][@"key2"]);
}

- (void)test_RadarUserDefault_setAndGetDouble {
    [self.radarUserDefault setDouble:1.0 forKey:@"double1"];
    [self.radarUserDefault setDouble:2.0 forKey:@"double2"];
    XCTAssertEqual(1.0, [self.radarUserDefault doubleForKey:@"double1"]);
    XCTAssertEqual(2.0, [self.radarUserDefault doubleForKey:@"double2"]);
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
