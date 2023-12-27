//
//  RadarUserDefaultsTest.m
//  RadarSDKTests
//
//  Created by Kenny Hu on 12/14/23.
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "../RadarSDK/RadarUserDefaults.h"
#import "../RadarSDK/Include/RadarTripOptions.h"
#import "../RadarSDK/RadarFeatureSettings.h"
#import "../RadarSDK/Include/RadarTrackingOptions.h"
#import "../RadarSDK/RadarSettings.h"
#import "../RadarSDK/RadarSettings.h"

@interface RadarUserDefaultsTest : XCTestCase
@property (nonatomic, strong) RadarUserDefaults *radarUserDefault;

@end

@implementation RadarUserDefaultsTest

- (void)setUp {
    [super setUp];
    self.radarUserDefault = [RadarUserDefaults sharedInstance];
    [self.radarUserDefault removeAllObjects];
}

- (void)tearDown {
    [self.radarUserDefault removeAllObjects];
    [self.radarUserDefault setMigrationCompleteFlag:NO];
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
    //test for string
    NSString *str = @"1234567890";
    [self.radarUserDefault setObject:str forKey:@"uuid"];
    XCTAssertEqualObjects(str, [self.radarUserDefault objectForKey:@"uuid"]);
    XCTAssertEqualObjects(str, [self.radarUserDefault stringForKey:@"uuid"]);
    //test for date
    NSDate *date = [NSDate date];
    [self.radarUserDefault setObject:date forKey:@"date"];
    XCTAssertEqualObjects(date, [self.radarUserDefault objectForKey:@"date"]);
    //test for radarTripOptions
    RadarTripOptions *tripOptions = [[RadarTripOptions alloc] initWithExternalId:@"123" destinationGeofenceTag:@"456" destinationGeofenceExternalId:@"789" scheduledArrivalAt:[NSDate date]];
    [self.radarUserDefault setObject:tripOptions forKey:@"tripOptions"];
    XCTAssertEqualObjects(tripOptions, [self.radarUserDefault objectForKey:@"tripOptions"]);
    //test for radarfeatureSettings
    RadarFeatureSettings *featureSettings = [[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:YES useLogPersistence:NO];
    [self.radarUserDefault setObject:featureSettings forKey:@"featureSettings"];
    XCTAssertEqualObjects(featureSettings, [self.radarUserDefault objectForKey:@"featureSettings"]);
    //test for radartrackingOptions
    RadarTrackingOptions *trackingOptions = RadarTrackingOptions.presetContinuous;
    [self.radarUserDefault setObject:trackingOptions forKey:@"trackingOptions"];
    XCTAssertEqualObjects(trackingOptions, [self.radarUserDefault objectForKey:@"trackingOptions"]);
    
    

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

- (void)test_RadarUserDefault_setAndGetInterger {
    [self.radarUserDefault setInteger:1 forKey:@"int1"];
    [self.radarUserDefault setInteger:2 forKey:@"int2"];
    XCTAssertEqual(1, [self.radarUserDefault integerForKey:@"int1"]);
    XCTAssertEqual(2, [self.radarUserDefault integerForKey:@"int2"]);
}

- (void)test_RadarUserDefault_migration {
    // verify that the migrationFlag is off
    XCTAssertTrue(!self.radarUserDefault.migrationCompleteFlag);

    XCTAssertTrue(!self.radarUserDefault.migrationCompleteFlag);

    // start with nsuserdefault filled with values

    //keyvalues copied from radarsettings
    NSString *const kPublishableKey = @"radar-publishableKey";
    NSString *const kInstallId = @"radar-installId";
    NSString *const kSessionId = @"radar-sessionId";
    NSString *const kId = @"radar-_id";
    static NSString *const kUserId = @"radar-userId";
    NSString *const kDescription = @"radar-description";
    NSString *const kMetadata = @"radar-metadata";
    NSString *const kAnonymous = @"radar-anonymous";
    NSString *const kTracking = @"radar-tracking";
    NSString *const kTrackingOptions = @"radar-trackingOptions";
    NSString *const kPreviousTrackingOptions = @"radar-previousTrackingOptions";
    NSString *const kRemoteTrackingOptions = @"radar-remoteTrackingOptions";
    NSString *const kFeatureSettings = @"radar-featureSettings";
    NSString *const kTripOptions = @"radar-tripOptions";
    NSString *const kLogLevel = @"radar-logLevel";
    NSString *const kBeaconUUIDs = @"radar-beaconUUIDs";
    NSString *const kHost = @"radar-host";
    NSString *const kLastTrackedTime = @"radar-lastTrackedTime";
    NSString *const kVerifiedHost = @"radar-verifiedHost";
    NSString *const kLastAppOpenTime = @"radar-lastAppOpenTime";
    NSString *const kUserDebug = @"radar-userDebug";

    NSString *const dummyPublishableKey = @"dummyPublishableKey";
    [[NSUserDefaults standardUserDefaults] setObject:dummyPublishableKey forKey:kPublishableKey];
    NSString *const dummyInstallId = @"dummyInstallId";
    [[NSUserDefaults standardUserDefaults] setObject:dummyInstallId forKey:kInstallId];
    double timestampSeconds = [[NSDate date] timeIntervalSince1970];
    [[NSUserDefaults standardUserDefaults] setDouble:timestampSeconds forKey:kSessionId];
    NSString *const dummyId = @"dummyId";
    [[NSUserDefaults standardUserDefaults] setObject:dummyId forKey:kId];
    NSString *const dummyUserId = @"dummyUserId";
    [[NSUserDefaults standardUserDefaults] setObject:dummyUserId forKey:kUserId];
    NSString *const dummyDescription = @"dummyDescription";
    [[NSUserDefaults standardUserDefaults] setObject:dummyDescription forKey:kDescription];
    NSDictionary<NSString *, NSString *> *dummyMetadata = @{@"key1": @"value1", @"key2": @"value2"};
    [[NSUserDefaults standardUserDefaults] setObject:dummyMetadata forKey:kMetadata];
    BOOL dummyAnonymous = YES;
    [[NSUserDefaults standardUserDefaults] setBool:dummyAnonymous forKey:kAnonymous];
    BOOL dummyTracking = NO;
    [[NSUserDefaults standardUserDefaults] setBool:dummyTracking forKey:kTracking];
    RadarTrackingOptions *dummyTrackingOptions = RadarTrackingOptions.presetContinuous;
    [[NSUserDefaults standardUserDefaults] setObject:[dummyTrackingOptions dictionaryValue] forKey:kTrackingOptions];
    RadarFeatureSettings *dummyFeatureSettings = [[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:YES useLogPersistence:NO];
    [[NSUserDefaults standardUserDefaults] setObject:[dummyFeatureSettings dictionaryValue] forKey:kFeatureSettings];
    RadarTrackingOptions *dummyPreviousTrackingOptions = RadarTrackingOptions.presetResponsive;
    [[NSUserDefaults standardUserDefaults] setObject:[dummyPreviousTrackingOptions dictionaryValue] forKey:kPreviousTrackingOptions];
    RadarTrackingOptions *dummyRemoteTrackingOptions = RadarTrackingOptions.presetContinuous;
    [[NSUserDefaults standardUserDefaults] setObject:[dummyRemoteTrackingOptions dictionaryValue] forKey:kRemoteTrackingOptions];
    RadarTripOptions *dummyTripOptions = [[RadarTripOptions alloc] initWithExternalId:@"123" destinationGeofenceTag:@"456" destinationGeofenceExternalId:@"789" scheduledArrivalAt:[NSDate date]];
    [[NSUserDefaults standardUserDefaults] setObject:[dummyTripOptions dictionaryValue] forKey:kTripOptions];
    RadarLogLevel dummyLogLevel = RadarLogLevelDebug;
    [[NSUserDefaults standardUserDefaults] setInteger:dummyLogLevel forKey:kLogLevel];
    NSArray<NSString *> *dummyBeaconUUIDs = @[@"123", @"456"];
    [[NSUserDefaults standardUserDefaults] setObject:dummyBeaconUUIDs forKey:kBeaconUUIDs];
    NSString *const dummyHost = @"dummyHost";
    [[NSUserDefaults standardUserDefaults] setObject:dummyHost forKey:kHost];
    NSString *const dummyVerifiedHost = @"dummyVerifiedHost";
    [[NSUserDefaults standardUserDefaults] setObject:dummyVerifiedHost forKey:kVerifiedHost];
    NSString *const dummyDefaultVerifiedHost = @"dummyDefaultVerifiedHost";
    NSDate *dummyLastTrackedTime = [NSDate date];
    [[NSUserDefaults standardUserDefaults] setObject:dummyLastTrackedTime forKey:kLastTrackedTime];
    NSDate *dummyLastAppOpenTime = [NSDate date];
    [[NSUserDefaults standardUserDefaults] setObject:dummyLastAppOpenTime forKey:kLastAppOpenTime];
    BOOL dummyUserDebug = YES;
    [[NSUserDefaults standardUserDefaults] setBool:dummyUserDebug forKey:kUserDebug];

    [RadarSettings migrateIfNeeded];
    // verify that the migrationFlag is on
    XCTAssertTrue(self.radarUserDefault.migrationCompleteFlag);
    // verify that the values are written to radarStrorageSystem and readable by the new radarSetting
    XCTAssertEqualObjects(dummyPublishableKey, [RadarSettings publishableKey]);
    XCTAssertEqualObjects(dummyInstallId, [RadarSettings installId]);
    NSString *timeStampSecondString = [NSString stringWithFormat:@"%.f", timestampSeconds];
    XCTAssertEqualObjects(timeStampSecondString, [RadarSettings sessionId]);
    XCTAssertEqualObjects(dummyId, [RadarSettings _id]);
    XCTAssertEqualObjects(dummyUserId, [RadarSettings userId]);
    XCTAssertEqualObjects(dummyDescription, [RadarSettings __description]);
    XCTAssertEqualObjects(dummyMetadata, [RadarSettings metadata]);
    XCTAssertEqual(dummyAnonymous, [RadarSettings anonymousTrackingEnabled]);
    XCTAssertEqual(dummyTracking, [RadarSettings tracking]);
    XCTAssertEqualObjects(dummyTrackingOptions, [RadarSettings trackingOptions]);
    XCTAssertEqualObjects(dummyFeatureSettings, [RadarSettings featureSettings]);
    XCTAssertEqualObjects(dummyPreviousTrackingOptions, [RadarSettings previousTrackingOptions]);
    XCTAssertEqualObjects(dummyRemoteTrackingOptions, [RadarSettings remoteTrackingOptions]);
    XCTAssertEqualObjects(dummyTripOptions, [RadarSettings tripOptions]);
    XCTAssertTrue(dummyLogLevel==[RadarSettings logLevel]);
    XCTAssertEqualObjects(dummyBeaconUUIDs, [RadarSettings beaconUUIDs]);
    XCTAssertEqualObjects(dummyHost, [RadarSettings host]);
    XCTAssertEqualObjects(dummyVerifiedHost, [RadarSettings verifiedHost]);
    XCTAssertEqualObjects(dummyLastTrackedTime, [RadarSettings lastTrackedTime]);
    XCTAssertEqualObjects(dummyLastAppOpenTime, [RadarSettings lastAppOpenTime]);
    XCTAssertEqual(dummyUserDebug, [RadarSettings userDebug]);
}

@end
