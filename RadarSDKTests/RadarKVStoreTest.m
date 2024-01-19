//
//  RadarKVStoreTest.m
//  RadarSDKTests
//
//  Created by Kenny Hu on 12/14/23.
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//
@import RadarSDK;
#import <XCTest/XCTest.h>

#import "../RadarSDK/RadarKVStore.h"
#import "../RadarSDK/Include/RadarTripOptions.h"
#import "../RadarSDK/RadarFeatureSettings.h"
#import "../RadarSDK/Include/RadarTrackingOptions.h"
#import "../RadarSDK/RadarSettings.h"
#import "../RadarSDK/RadarSettings.h"
#import "../RadarSDK/RadarState.h"
#import "../RadarSDK/RadarUtils.h"
#import "../RadarSDK/RadarReplay.h"
#import "../RadarSDK/RadarReplayBuffer.h"
#import "../RadarSDK/RadarLogBuffer.h"
//remove, this is just for a sanity check
#import "../RadarSDK/RadarLogger.h"


@interface RadarKVStoreTest : XCTestCase
@property (nonatomic, strong) RadarKVStore *radarKVStore;

@end

@implementation RadarKVStoreTest

static NSString *const kPublishableKey = @"radar-publishableKey";
static NSString *const kInstallId = @"radar-installId";
static NSString *const kSessionId = @"radar-sessionId";
static NSString *const kId = @"radar-_id";
static NSString *const kUserId = @"radar-userId";
static NSString *const kDescription = @"radar-description";
static NSString *const kMetadata = @"radar-metadata";
static NSString *const kAnonymous = @"radar-anonymous";
static NSString *const kTracking = @"radar-tracking";
static NSString *const kTrackingOptions = @"radar-trackingOptions";
static NSString *const kPreviousTrackingOptions = @"radar-previousTrackingOptions";
static NSString *const kRemoteTrackingOptions = @"radar-remoteTrackingOptions";
static NSString *const kFeatureSettings = @"radar-featureSettings";
static NSString *const kTripOptions = @"radar-tripOptions";
static NSString *const kLogLevel = @"radar-logLevel";
static NSString *const kBeaconUUIDs = @"radar-beaconUUIDs";
static NSString *const kHost = @"radar-host";
static NSString *const kLastTrackedTime = @"radar-lastTrackedTime";
static NSString *const kVerifiedHost = @"radar-verifiedHost";
static NSString *const kLastAppOpenTime = @"radar-lastAppOpenTime";
static NSString *const kUserDebug = @"radar-userDebug";

static NSString *const kLastLocation = @"radar-lastLocation";
static NSString *const kLastMovedLocation = @"radar-lastMovedLocation";
static NSString *const kLastMovedAt = @"radar-lastMovedAt";
static NSString *const kStopped = @"radar-stopped";
static NSString *const kLastSentAt = @"radar-lastSentAt";
static NSString *const kCanExit = @"radar-canExit";
static NSString *const kLastFailedStoppedLocation = @"radar-lastFailedStoppedLocation";
static NSString *const kGeofenceIds = @"radar-geofenceIds";
static NSString *const kPlaceId = @"radar-placeId";
static NSString *const kRegionIds = @"radar-regionIds";
static NSString *const kBeaconIds = @"radar-beaconIds";

static NSString *const kReplayBuffer = @"radar-replays";

- (void)setUp {
    [super setUp];
    self.radarKVStore = [RadarKVStore sharedInstance];
    [self.radarKVStore removeAllObjects];
    [self.radarKVStore setRadarKVStoreMigrationComplete:NO];
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    [[RadarLogBuffer sharedInstance] clearBuffer];
}

- (void)tearDown {
    [self.radarKVStore removeAllObjects];
    [self.radarKVStore setRadarKVStoreMigrationComplete:NO];
    [[RadarLogBuffer sharedInstance] clearBuffer];
}

- (void)test_RadarKVStore_removeAllObjects {
    [self.radarKVStore setString:@"123abc!@#" forKey:@"string1"];
    [self.radarKVStore setString:@"I like working here" forKey:@"string2"];
    [self.radarKVStore setString:@"hello world" forKey:@"string3"];
    [self.radarKVStore setBool:YES forKey:@"yesValue"];
    [self.radarKVStore setObject:@1 forKey:@"int1"];
    [self.radarKVStore removeAllObjects];
    XCTAssertNil([self.radarKVStore stringForKey:@"string1"]);
    XCTAssertNil([self.radarKVStore stringForKey:@"string2"]);
    XCTAssertNil([self.radarKVStore stringForKey:@"string3"]);
    XCTAssertFalse([self.radarKVStore boolForKey:@"yesValue"]);
    XCTAssertEqual(0, [self.radarKVStore integerForKey:@"int1"]);
}

- (void)test_RadarKVStore_setAndGetMigrationFlag {
    [self.radarKVStore setRadarKVStoreMigrationComplete:YES];
    XCTAssertTrue(self.radarKVStore.radarKVStoreMigrationComplete);
    [self.radarKVStore setRadarKVStoreMigrationComplete:NO];
    XCTAssertFalse(self.radarKVStore.radarKVStoreMigrationComplete);
}

- (void)test_RadarKVStore_setAndGetBOOL {
    [self.radarKVStore setBool:YES forKey:@"yesValue"];
    [self.radarKVStore setBool:NO forKey:@"noValue"];
    XCTAssertTrue([self.radarKVStore boolForKey:@"yesValue"]);
    XCTAssertFalse([self.radarKVStore boolForKey:@"noValue"]);
    [self.radarKVStore setBool:YES forKey:@"noValue"];
    XCTAssertTrue([self.radarKVStore boolForKey:@"noValue"]);
    
    // test for meaningful default values
    XCTAssertFalse([self.radarKVStore boolForKey:@"emptyKey"]);
}

- (void)test_RadarKVStore_setAndGetString {
    [self.radarKVStore setString:@"123abc!@#" forKey:@"string1"];
    XCTAssertEqualObjects(@"123abc!@#", [self.radarKVStore stringForKey:@"string1"]);
    [self.radarKVStore setString:@"I like working here" forKey:@"string1"];
    XCTAssertEqualObjects(@"I like working here", [self.radarKVStore stringForKey:@"string1"]);
    [self.radarKVStore setString:@"hello world" forKey:@"string2"];
    XCTAssertEqualObjects(@"hello world", [self.radarKVStore stringForKey:@"string2"]);
    
    // test for meaningful default values
    XCTAssertNil([self.radarKVStore stringForKey:@"emptyKey"]);

    // test setting null removes data
    [self.radarKVStore setString:nil forKey:@"string1"];
    XCTAssertNil([self.radarKVStore stringForKey:@"string1"]);
    [self.radarKVStore setString:nil forKey:@"string1"];
}

- (void)test_RadarKVStore_setAndGetNSObj {
    NSArray<NSString *> *stringArrays = @[@"Hello", @"World"];
    NSObject *obj1 = stringArrays;
    NSArray<NSNumber *> *intArrays = @[@1, @2, @3];
    NSObject *obj2 = intArrays;
    [self.radarKVStore setObject:obj1 forKey:@"obj1"];
    [self.radarKVStore setObject:obj2 forKey:@"obj2"];
    XCTAssertEqualObjects(stringArrays, [self.radarKVStore objectForKey:@"obj1"]);
    XCTAssertEqualObjects(intArrays, [self.radarKVStore objectForKey:@"obj2"]);
    // test for string
    NSString *str = @"1234567890";
    [self.radarKVStore setObject:str forKey:@"uuid"];
    XCTAssertEqualObjects(str, [self.radarKVStore objectForKey:@"uuid"]);
    XCTAssertEqualObjects(str, [self.radarKVStore stringForKey:@"uuid"]);
    // test for date
    NSDate *date = [NSDate date];
    [self.radarKVStore setObject:date forKey:@"date"];
    XCTAssertEqualObjects(date, [self.radarKVStore objectForKey:@"date"]);
    // test for radarTripOptions
    NSDictionary *tripOptionDict = @{@"externalId": @"123", @"destinationGeofenceTag": @"456", @"destinationGeofenceExternalId": @"789", @"scheduledArrivalAt": [NSDate date], @"metadata": @{@"key1": @"value1", @"key2": @"value2"}, @"mode": @"car", @"approachingThreshold": @100};
    RadarTripOptions *tripOptions = [RadarTripOptions tripOptionsFromDictionary:tripOptionDict];
    [self.radarKVStore setObject:tripOptions forKey:@"tripOptions"];
    XCTAssertEqualObjects(tripOptions, [self.radarKVStore objectForKey:@"tripOptions"]);
    // test for radarFeatureSettings
    RadarFeatureSettings *featureSettings = [[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:YES useLogPersistence:NO useRadarKVStore:NO];
    [self.radarKVStore setObject:featureSettings forKey:@"featureSettings"];
    XCTAssertEqualObjects(featureSettings, [self.radarKVStore objectForKey:@"featureSettings"]);
    // test for radarTrackingOptions
    [self.radarKVStore setObject:RadarTrackingOptions.presetContinuous forKey:@"trackingOptions"];
    XCTAssertEqualObjects(RadarTrackingOptions.presetContinuous, [self.radarKVStore objectForKey:@"trackingOptions"]);
    [self.radarKVStore setObject:RadarTrackingOptions.presetResponsive forKey:@"trackingOptions"];
    XCTAssertEqualObjects(RadarTrackingOptions.presetResponsive, [self.radarKVStore objectForKey:@"trackingOptions"]);
    [self.radarKVStore setObject:RadarTrackingOptions.presetEfficient forKey:@"trackingOptions"];
    XCTAssertEqualObjects(RadarTrackingOptions.presetEfficient, [self.radarKVStore objectForKey:@"trackingOptions"]);
    // test for CLLocation
    CLLocation *location = [[CLLocation alloc] initWithLatitude:1.0 longitude:2.0];
    [self.radarKVStore setObject:location forKey:@"location"];
    CLLocation *location2= [self.radarKVStore objectForKey:@"location"];
    XCTAssertTrue(location.coordinate.latitude == location2.coordinate.latitude);
    XCTAssertTrue(location.coordinate.longitude == location2.coordinate.longitude);
    XCTAssertEqualObjects(location.timestamp, location2.timestamp);
    
    // test for meaningful default values
    XCTAssertNil([self.radarKVStore objectForKey:@"emptyKey"]);

    // test setting null removes data
    [self.radarKVStore setObject:nil forKey:@"obj1"];
    XCTAssertNil([self.radarKVStore objectForKey:@"obj1"]);
}

- (void)test_RadarKVStore_setAndGetNSDictonary {
    NSDictionary<NSString *, NSString *> *dic1 = @{@"key1": @"value1", @"key2": @"value2"};
    NSDictionary<NSString *, NSNumber *> *dic2 = @{@"key1": @1, @"key2": @2};
    [self.radarKVStore setDictionary:dic1 forKey:@"dic1"];
    [self.radarKVStore setDictionary:dic2 forKey:@"dic2"];
    XCTAssertEqualObjects(dic1, [self.radarKVStore dictionaryForKey:@"dic1"]);
    XCTAssertEqualObjects(dic2, [self.radarKVStore dictionaryForKey:@"dic2"]);
    //test fields are equal
    XCTAssertEqualObjects(dic1[@"key1"], [self.radarKVStore dictionaryForKey:@"dic1"][@"key1"]);
    XCTAssertEqualObjects(dic1[@"key2"], [self.radarKVStore dictionaryForKey:@"dic1"][@"key2"]);
    XCTAssertEqualObjects(dic2[@"key1"], [self.radarKVStore dictionaryForKey:@"dic2"][@"key1"]);
    XCTAssertEqualObjects(dic2[@"key2"], [self.radarKVStore dictionaryForKey:@"dic2"][@"key2"]);
    
    // test for meaningful default values
    XCTAssertNil([self.radarKVStore dictionaryForKey:@"emptyKey"]);

    // test setting null removes data
    [self.radarKVStore setDictionary:nil forKey:@"dic1"];
    XCTAssertNil([self.radarKVStore dictionaryForKey:@"dic1"]);
    [self.radarKVStore setDictionary:nil forKey:@"dic1"];
}

- (void)test_RadarKVStore_setAndGetDouble {
    [self.radarKVStore setDouble:1.0 forKey:@"double1"];
    [self.radarKVStore setDouble:2.0 forKey:@"double2"];
    XCTAssertEqual(1.0, [self.radarKVStore doubleForKey:@"double1"]);
    XCTAssertEqual(2.0, [self.radarKVStore doubleForKey:@"double2"]);
    
    // test for meaningful default values
    XCTAssertEqual(0, [self.radarKVStore doubleForKey:@"emptyKey"]);
}

- (void)test_RadarKVStore_setAndGetInterger {
    [self.radarKVStore setInteger:1 forKey:@"int1"];
    [self.radarKVStore setInteger:2 forKey:@"int2"];
    XCTAssertEqual(1, [self.radarKVStore integerForKey:@"int1"]);
    XCTAssertEqual(2, [self.radarKVStore integerForKey:@"int2"]);
    
    // test for meaningful default values
    XCTAssertEqual(0, [self.radarKVStore integerForKey:@"emptyKey"]);
}

-  (void)test_RadarSetting_migration {
    // verify that the migrationFlag is off
    XCTAssertTrue(!self.radarKVStore.radarKVStoreMigrationComplete);

    XCTAssertTrue(!self.radarKVStore.radarKVStoreMigrationComplete);

    // start with nsuserdefault filled with values

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
    RadarFeatureSettings *dummyFeatureSettings = [[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:YES useLogPersistence:NO useRadarKVStore:NO];
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
    NSDate *dummyLastTrackedTime = [NSDate date];
    [[NSUserDefaults standardUserDefaults] setObject:dummyLastTrackedTime forKey:kLastTrackedTime];
    NSDate *dummyLastAppOpenTime = [NSDate date];
    [[NSUserDefaults standardUserDefaults] setObject:dummyLastAppOpenTime forKey:kLastAppOpenTime];
    BOOL dummyUserDebug = YES;
    [[NSUserDefaults standardUserDefaults] setBool:dummyUserDebug forKey:kUserDebug];

    [RadarSettings migrateToRadarKVStore];

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

// for each settings
//      write with settings off
//      read with settings off
//      remove with setting off
//      write with setting on
//      read with setting on
//      remove with setting on
//      assert that no logs are created (indicates discrepency)
//      check that discrepency will trigger logging

// reads and writes with NSUserDefaults
// read and writes with RadarKVStore
// ensure that no logs are created by the discrepency
// check that discrepency will trigger logging

- (void)test_RadarSettings_publishableKey {
    // reads and writes with NSUserDefaults
   [RadarSettings setPublishableKey:@"123abc!@#"];
    XCTAssertEqualObjects(@"123abc!@#", [RadarSettings publishableKey]);
    // read and writes with RadarKVStore
    [RadarSettings setFeatureSettings:[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:YES]];
    [RadarSettings setPublishableKey:@"678abc!@#"];
    XCTAssertEqualObjects(@"678abc!@#", [RadarSettings publishableKey]);
    // ensure that no logs are created by the discrepency
    XCTAssertEqual(0, [[RadarLogBuffer sharedInstance] flushableLogs].count);
    // check that discrepency will trigger logging
    [RadarSettings setFeatureSettings:[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:NO]];
    [RadarSettings publishableKey];
    [[NSUserDefaults standardUserDefaults] setObject:@"321abc!@#" forKey:kPublishableKey];
    [RadarSettings publishableKey];
    XCTAssertEqual(2, [[RadarLogBuffer sharedInstance] flushableLogs].count);
}

- (void)test_RadarSettings_installId {
    // read and writes with NSUserDefaults
    NSString *dummyInstallId = [RadarSettings installId];
    XCTAssertEqualObjects(dummyInstallId, [RadarSettings installId]);
    // read and writes with RadarKVStore
    [RadarSettings setFeatureSettings:[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:YES]];
    dummyInstallId = [RadarSettings installId];
    XCTAssertEqualObjects(dummyInstallId, [RadarSettings installId]);
    // ensure that no logs are created by the discrepency
    XCTAssertEqual(0, [[RadarLogBuffer sharedInstance] flushableLogs].count);
    // check that discrepency will trigger logging
    [RadarSettings setFeatureSettings:[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:NO]];
    [[NSUserDefaults standardUserDefaults] setObject:@"1234" forKey:kInstallId];
    [RadarSettings installId];
    XCTAssertEqual(1, [[RadarLogBuffer sharedInstance] flushableLogs].count);
}

- (void)test_RadarSettings_sessionId {
    // reads and writes with NSUserDefaults
    XCTAssertTrue([RadarSettings updateSessionId]);
    XCTAssertTrue(([RadarSettings sessionId].doubleValue - [[NSDate date] timeIntervalSince1970]) < 10);
    // read and writes with RadarKVStore
    [RadarSettings setFeatureSettings:[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:YES]];
    XCTAssertFalse([RadarSettings updateSessionId]);
    XCTAssertTrue(([RadarSettings sessionId].doubleValue - [[NSDate date] timeIntervalSince1970]) < 10);
    // ensure that no logs are created by the discrepency
    XCTAssertEqual(0, [[RadarLogBuffer sharedInstance] flushableLogs].count);
    // check that discrepency will trigger logging
    [RadarSettings setFeatureSettings:[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:NO]];
    [[NSUserDefaults standardUserDefaults] setDouble:1234 forKey:kSessionId];
    [RadarSettings sessionId];
    XCTAssertEqual(1, [[RadarLogBuffer sharedInstance] flushableLogs].count);
    }

- (void)test_RadarSettings_Id {
   // reads and writes with NSUserDefaults
    NSString *dummyId = @"dummyId";
    [RadarSettings setId:dummyId];
    XCTAssertEqualObjects(dummyId, [RadarSettings _id]);
    [RadarSettings setId:nil];
    XCTAssertNil([RadarSettings _id]);
    // read and writes with RadarKVStore
    [RadarSettings setFeatureSettings:[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:YES]];
    dummyId = @"dummyId2";
    [RadarSettings setId:dummyId];
    XCTAssertEqualObjects(dummyId, [RadarSettings _id]);
    [RadarSettings setId:nil];
    XCTAssertNil([RadarSettings _id]);
    // ensure that no logs are created by the discrepency
    XCTAssertEqual(0, [[RadarLogBuffer sharedInstance] flushableLogs].count);
    // check that discrepency will trigger logging
    [RadarSettings setFeatureSettings:[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:NO]];
    [[NSUserDefaults standardUserDefaults] setObject:@"1234" forKey:kId]; 
    [RadarSettings _id];
    [RadarSettings setId:dummyId]; 
    [[NSUserDefaults standardUserDefaults] setObject:@"1234" forKey:kId];
    [RadarSettings _id];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kId];
    [RadarSettings _id];
    XCTAssertEqual(3, [[RadarLogBuffer sharedInstance] flushableLogs].count);
}

- (void)test_RadarSettings_userId {
    // reads and writes with NSUserDefaults
    NSString *dummyUserId = @"dummyUserId";
    [RadarSettings setUserId:dummyUserId];
    XCTAssertEqualObjects(dummyUserId, [RadarSettings userId]);
    [RadarSettings setUserId:nil];
    XCTAssertNil([RadarSettings userId]);
    // read and writes with RadarKVStore
    [RadarSettings setFeatureSettings:[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:YES]];
    dummyUserId = @"dummyUserId2";
    [RadarSettings setUserId:dummyUserId];
    XCTAssertEqualObjects(dummyUserId, [RadarSettings userId]);
    [RadarSettings setUserId:nil];
    XCTAssertNil([RadarSettings userId]);
    // ensure that no logs are created by the discrepency
    XCTAssertEqual(0, [[RadarLogBuffer sharedInstance] flushableLogs].count);
    // check that discrepency will trigger logging
    [RadarSettings setFeatureSettings:[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:NO]];
    [[NSUserDefaults standardUserDefaults] setObject:@"1234" forKey:kUserId];
    [RadarSettings userId];
    [RadarSettings setUserId:dummyUserId];
    [[NSUserDefaults standardUserDefaults] setObject:@"1234" forKey:kUserId];
    [RadarSettings userId];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kUserId];
    [RadarSettings userId];
    XCTAssertEqual(3, [[RadarLogBuffer sharedInstance] flushableLogs].count);
}

- (void) test_RadarSettings_description {
    // reads and writes with NSUserDefaults
    NSString *dummyDescription = @"dummyDescription";
    [RadarSettings setDescription:dummyDescription];
    XCTAssertEqualObjects(dummyDescription, [RadarSettings __description]);
    [RadarSettings setDescription:nil];
    XCTAssertNil([RadarSettings __description]);
    // read and writes with RadarKVStore
    [RadarSettings setFeatureSettings:[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:YES]];
    dummyDescription = @"dummyDescription2";
    [RadarSettings setDescription:dummyDescription];
    XCTAssertEqualObjects(dummyDescription, [RadarSettings __description]);
    [RadarSettings setDescription:nil];
    XCTAssertNil([RadarSettings __description]);
    // ensure that no logs are created by the discrepency
    XCTAssertEqual(0, [[RadarLogBuffer sharedInstance] flushableLogs].count);
    // check that discrepency will trigger logging
    [RadarSettings setFeatureSettings:[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:NO]];
    [[NSUserDefaults standardUserDefaults] setObject:@"1234" forKey:kDescription];
    [RadarSettings __description];
    [RadarSettings setDescription:dummyDescription];
    [[NSUserDefaults standardUserDefaults] setObject:@"1234" forKey:kDescription];
    [RadarSettings __description];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kDescription];
    [RadarSettings __description];
    XCTAssertEqual(3, [[RadarLogBuffer sharedInstance] flushableLogs].count);
}

- (void)test_RadarSettings_metadata {
    // reads and writes with NSUserDefaults
    NSDictionary<NSString *, NSString *> *dummyMetadata = @{@"key1": @"value1", @"key2": @"value2"};
    [RadarSettings setMetadata:dummyMetadata];
    XCTAssertEqualObjects(dummyMetadata, [RadarSettings metadata]);
    [RadarSettings setMetadata:nil];
    XCTAssertNil([RadarSettings metadata]);
    // read and writes with RadarKVStore
    [RadarSettings setFeatureSettings:[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:YES]];
    NSDictionary<NSString *, NSString *> *dummyMetadata2 = @{@"key3": @"value3", @"key4": @"value4"};
    [RadarSettings setMetadata:dummyMetadata2];
    XCTAssertEqualObjects(dummyMetadata2, [RadarSettings metadata]);
    [RadarSettings setMetadata:nil];
    XCTAssertNil([RadarSettings metadata]);
    // ensure that no logs are created by the discrepency
    XCTAssertEqual(0, [[RadarLogBuffer sharedInstance] flushableLogs].count);
    // check that discrepency will trigger logging
    [RadarSettings setFeatureSettings:[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:NO]];
    [[NSUserDefaults standardUserDefaults] setObject:dummyMetadata forKey:kMetadata];
    [RadarSettings metadata];
    [RadarSettings setMetadata:dummyMetadata2];
    [[NSUserDefaults standardUserDefaults] setObject:dummyMetadata forKey:kMetadata]; 
    [RadarSettings metadata];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kMetadata];
    [RadarSettings metadata];
    XCTAssertEqual(3, [[RadarLogBuffer sharedInstance] flushableLogs].count);
}

- (void)test_RadarSettings_anonymousTrackingEnabled {
    // reads and writes with NSUserDefaults
    BOOL dummyAnonymous = YES;
    [RadarSettings setAnonymousTrackingEnabled:dummyAnonymous];
    XCTAssertEqual(dummyAnonymous, [RadarSettings anonymousTrackingEnabled]);
    // read and writes with RadarKVStore
    [RadarSettings setFeatureSettings:[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:YES]];
    BOOL dummyAnonymous2 = NO;
    [RadarSettings setAnonymousTrackingEnabled:dummyAnonymous2];
    XCTAssertEqual(dummyAnonymous2, [RadarSettings anonymousTrackingEnabled]);
    // ensure that no logs are created by the discrepency
    XCTAssertEqual(0, [[RadarLogBuffer sharedInstance] flushableLogs].count);
    // check that discrepency will trigger logging
    [RadarSettings setFeatureSettings:[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:NO]];
    [RadarSettings anonymousTrackingEnabled];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kAnonymous];
    [RadarSettings anonymousTrackingEnabled];
    XCTAssertEqual(2, [[RadarLogBuffer sharedInstance] flushableLogs].count);
}

- (void)test_RadarSettings_tracking {
    // reads and writes with NSUserDefaults
    BOOL dummyTracking = YES;
    [RadarSettings setTracking:dummyTracking];
    XCTAssertEqual(dummyTracking, [RadarSettings tracking]);
    // read and writes with RadarKVStore
    [RadarSettings setFeatureSettings:[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:YES]];
    BOOL dummyTracking2 = NO;
    [RadarSettings setTracking:dummyTracking2];
    XCTAssertEqual(dummyTracking2, [RadarSettings tracking]);
    // ensure that no logs are created by the discrepency
    XCTAssertEqual(0, [[RadarLogBuffer sharedInstance] flushableLogs].count);
    // check that discrepency will trigger logging
    [RadarSettings setFeatureSettings:[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:NO]];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kTracking];
    [RadarSettings tracking];
    XCTAssertEqual(1, [[RadarLogBuffer sharedInstance] flushableLogs].count);
}

- (void)test_RadarSettings_trackingOptions {
    // reads, deletes and writes with NSUserDefaults
    RadarTrackingOptions *dummyTrackingOptions = RadarTrackingOptions.presetContinuous;
    [RadarSettings setTrackingOptions:dummyTrackingOptions];
    XCTAssertEqualObjects(dummyTrackingOptions, [RadarSettings trackingOptions]);
    [RadarSettings removeTrackingOptions];
    XCTAssertEqualObjects(RadarTrackingOptions.presetEfficient, [RadarSettings trackingOptions]);
    // read, deletes and writes with RadarKVStore
    [RadarSettings setFeatureSettings:[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:YES]];
    RadarTrackingOptions *dummyTrackingOptions2 = RadarTrackingOptions.presetResponsive;
    [RadarSettings setTrackingOptions:dummyTrackingOptions2];
    XCTAssertEqualObjects(dummyTrackingOptions2, [RadarSettings trackingOptions]);
    [RadarSettings removeTrackingOptions];
    XCTAssertEqualObjects(RadarTrackingOptions.presetEfficient, [RadarSettings trackingOptions]);
    // ensure that no logs are created by the discrepency
    XCTAssertEqual(0, [[RadarLogBuffer sharedInstance] flushableLogs].count);
    // check that discrepency will trigger logging
    [RadarSettings setFeatureSettings:[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:NO]];
    [[NSUserDefaults standardUserDefaults] setObject:[dummyTrackingOptions dictionaryValue] forKey:kTrackingOptions];
    [RadarSettings trackingOptions];
    [RadarSettings setTrackingOptions:dummyTrackingOptions];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kTrackingOptions];
    [RadarSettings trackingOptions];
    [[NSUserDefaults standardUserDefaults] setObject:[dummyTrackingOptions2 dictionaryValue] forKey:kTrackingOptions];
    [RadarSettings trackingOptions];
    XCTAssertEqual(3, [[RadarLogBuffer sharedInstance] flushableLogs].count);
}

- (void)test_RadarSettings_previousTrackingOptions {
    // reads, deletes and writes with NSUserDefaults
    RadarTrackingOptions *dummyPreviousTrackingOptions = RadarTrackingOptions.presetContinuous;
    [RadarSettings setPreviousTrackingOptions:dummyPreviousTrackingOptions];
    XCTAssertEqualObjects(dummyPreviousTrackingOptions, [RadarSettings previousTrackingOptions]);
    [RadarSettings removePreviousTrackingOptions];
    XCTAssertNil([RadarSettings previousTrackingOptions]);
    // read, deletes and writes with RadarKVStore
    [RadarSettings setFeatureSettings:[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:YES]];
    RadarTrackingOptions *dummyPreviousTrackingOptions2 = RadarTrackingOptions.presetResponsive;
    [RadarSettings setPreviousTrackingOptions:dummyPreviousTrackingOptions2];
    XCTAssertEqualObjects(dummyPreviousTrackingOptions2, [RadarSettings previousTrackingOptions]);
    [RadarSettings removePreviousTrackingOptions];
    XCTAssertNil([RadarSettings previousTrackingOptions]);
    // ensure that no logs are created by the discrepency
    XCTAssertEqual(0, [[RadarLogBuffer sharedInstance] flushableLogs].count);
    // check that discrepency will trigger logging
    [RadarSettings setFeatureSettings:[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:NO]];
    [[NSUserDefaults standardUserDefaults] setObject:[dummyPreviousTrackingOptions dictionaryValue] forKey:kPreviousTrackingOptions];
    [RadarSettings previousTrackingOptions];
    [RadarSettings setPreviousTrackingOptions:dummyPreviousTrackingOptions];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kPreviousTrackingOptions];
    [RadarSettings previousTrackingOptions];
    [[NSUserDefaults standardUserDefaults] setObject:[dummyPreviousTrackingOptions2 dictionaryValue] forKey:kPreviousTrackingOptions];
    [RadarSettings previousTrackingOptions];
    XCTAssertEqual(3, [[RadarLogBuffer sharedInstance] flushableLogs].count);
}

- (void)test_RadarSettings_remoteTrackingOptions {
    // reads, deletes and writes with NSUserDefaults
    RadarTrackingOptions *dummyRemoteTrackingOptions = RadarTrackingOptions.presetContinuous;
    [RadarSettings setRemoteTrackingOptions:dummyRemoteTrackingOptions];
    XCTAssertEqualObjects(dummyRemoteTrackingOptions, [RadarSettings remoteTrackingOptions]);
    [RadarSettings removeRemoteTrackingOptions];
    XCTAssertNil([RadarSettings remoteTrackingOptions]);
    // read, deletes and writes with RadarKVStore
    [RadarSettings setFeatureSettings:[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:YES]];
    RadarTrackingOptions *dummyRemoteTrackingOptions2 = RadarTrackingOptions.presetResponsive;
    [RadarSettings setRemoteTrackingOptions:dummyRemoteTrackingOptions2];
    XCTAssertEqualObjects(dummyRemoteTrackingOptions2, [RadarSettings remoteTrackingOptions]);
    [RadarSettings removeRemoteTrackingOptions];
    XCTAssertNil([RadarSettings remoteTrackingOptions]);
    // ensure that no logs are created by the discrepency
    XCTAssertEqual(0, [[RadarLogBuffer sharedInstance] flushableLogs].count);
    // check that discrepency will trigger logging
    [RadarSettings setFeatureSettings:[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:NO]];
    [[NSUserDefaults standardUserDefaults] setObject:[dummyRemoteTrackingOptions dictionaryValue] forKey:kRemoteTrackingOptions];
    [RadarSettings remoteTrackingOptions];
    [RadarSettings setRemoteTrackingOptions:dummyRemoteTrackingOptions];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kRemoteTrackingOptions];
    [RadarSettings remoteTrackingOptions];
    [[NSUserDefaults standardUserDefaults] setObject:[dummyRemoteTrackingOptions2 dictionaryValue] forKey:kRemoteTrackingOptions];
    [RadarSettings remoteTrackingOptions];
    XCTAssertEqual(3, [[RadarLogBuffer sharedInstance] flushableLogs].count);
}

- (void)test_RadarSettings_tripOptions {
    // reads, deletes and writes with NSUserDefaults
    RadarTripOptions *dummyTripOptions = [[RadarTripOptions alloc] initWithExternalId:@"123" destinationGeofenceTag:@"456" destinationGeofenceExternalId:@"789" scheduledArrivalAt:[NSDate date]];
    [RadarSettings setTripOptions:dummyTripOptions];
    XCTAssertEqualObjects(dummyTripOptions, [RadarSettings tripOptions]);
    [RadarSettings setTripOptions:nil];
    XCTAssertNil([RadarSettings tripOptions]);
    // read, deletes and writes with RadarKVStore
    RadarTripOptions *dummyTripOptions2 = [[RadarTripOptions alloc] initWithExternalId:@"1234" destinationGeofenceTag:@"4567" destinationGeofenceExternalId:@"7890" scheduledArrivalAt:[NSDate date]];
    [RadarSettings setTripOptions:dummyTripOptions2];
    XCTAssertEqualObjects(dummyTripOptions2, [RadarSettings tripOptions]);
    [RadarSettings setTripOptions:nil];
    XCTAssertNil([RadarSettings tripOptions]);
    // ensure that no logs are created by the discrepency
    XCTAssertEqual(0, [[RadarLogBuffer sharedInstance] flushableLogs].count);
    // check that discrepency will trigger logging
    [[NSUserDefaults standardUserDefaults] setObject:[dummyTripOptions dictionaryValue] forKey:kTripOptions];
    [RadarSettings tripOptions];
    [RadarSettings setTripOptions:dummyTripOptions];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kTripOptions];
    [RadarSettings tripOptions];
    [[NSUserDefaults standardUserDefaults] setObject:[dummyTripOptions2 dictionaryValue] forKey:kTripOptions];
    [RadarSettings tripOptions];
    XCTAssertEqual(3, [[RadarLogBuffer sharedInstance] flushableLogs].count);
}

- (void)test_RadarSetting_logLevel {
    // reads and writes with NSUserDefaults
    RadarLogLevel dummyLogLevel = RadarLogLevelDebug;
    [RadarSettings setLogLevel:dummyLogLevel];
    XCTAssertEqual(dummyLogLevel, [RadarSettings logLevel]);
    // read and writes with RadarKVStore
    [RadarSettings setFeatureSettings:[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:YES]];
    [RadarSettings setLogLevel:RadarLogLevelNone];
    XCTAssertEqual(RadarLogLevelNone, [RadarSettings logLevel]);
    // ensure that no logs are created by the discrepency
    XCTAssertEqual(0, [[RadarLogBuffer sharedInstance] flushableLogs].count);

    // check that discrepency will trigger logging
    [RadarSettings setFeatureSettings:[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:NO]];
    [[NSUserDefaults standardUserDefaults] setInteger:RadarLogLevelDebug forKey:kLogLevel];
    [RadarSettings logLevel];
    XCTAssertEqual(1, [[RadarLogBuffer sharedInstance] flushableLogs].count);
}

- (void)test_RadarSettings_beaconsUUIDs {
    // reads and writes with NSUserDefaults
    NSArray<NSString *> *dummyBeaconUUIDs = @[@"123", @"456"];
    [RadarSettings setBeaconUUIDs:dummyBeaconUUIDs];
    XCTAssertEqualObjects(dummyBeaconUUIDs, [RadarSettings beaconUUIDs]);
    [RadarSettings setBeaconUUIDs:nil];
    XCTAssertNil([RadarSettings beaconUUIDs]);
    // read and writes with RadarKVStore
    [RadarSettings setFeatureSettings :[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:YES]];
    NSArray<NSString *> *dummyBeaconUUIDs2 = @[@"1234", @"4567"];
    [RadarSettings setBeaconUUIDs:dummyBeaconUUIDs2];
    XCTAssertEqualObjects(dummyBeaconUUIDs2, [RadarSettings beaconUUIDs]);
    [RadarSettings setBeaconUUIDs:nil];
    XCTAssertNil([RadarSettings beaconUUIDs]);
    // ensure that no logs are created by the discrepency
    XCTAssertEqual(0, [[RadarLogBuffer sharedInstance] flushableLogs].count);
    // check that discrepency will trigger logging
    [RadarSettings setFeatureSettings :[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:NO]];
    [[NSUserDefaults standardUserDefaults] setObject:dummyBeaconUUIDs forKey:kBeaconUUIDs];
    [RadarSettings beaconUUIDs];
    [RadarSettings setBeaconUUIDs:dummyBeaconUUIDs];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kBeaconUUIDs];
    [RadarSettings beaconUUIDs];
    [[NSUserDefaults standardUserDefaults] setObject:dummyBeaconUUIDs2 forKey:kBeaconUUIDs];
    [RadarSettings beaconUUIDs];
    XCTAssertEqual(3, [[RadarLogBuffer sharedInstance] flushableLogs].count);
}

- (void)test_RadarSettings_host {
    // reads with NSUserDefaults
    NSString *const dummyHost = @"dummyHost";
    [[NSUserDefaults standardUserDefaults] setObject:dummyHost forKey:kHost];
    [[RadarKVStore sharedInstance] setObject:dummyHost forKey:kHost];
    XCTAssertEqualObjects(dummyHost, [RadarSettings host]);
    // read and writes with RadarKVStore
    [RadarSettings setFeatureSettings :[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:YES]];
    XCTAssertEqualObjects(dummyHost, [RadarSettings host]);
    // ensure that no logs are created by the discrepency
    XCTAssertEqual(0, [[RadarLogBuffer sharedInstance] flushableLogs].count);
    // check that discrepency will not trigger logging
    [RadarSettings setFeatureSettings :[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:NO]];
    [[NSUserDefaults standardUserDefaults] setObject:@"1234" forKey:kHost];
    [RadarSettings host];
    XCTAssertEqual(1, [[RadarLogBuffer sharedInstance] flushableLogs].count);
}

- (void)test_RadarSettings_lastTrackedTime {
    // reads and writes with NSUserDefaults
    [RadarSettings updateLastTrackedTime];
    XCTAssertTrue(([[RadarSettings lastTrackedTime] timeIntervalSince1970] - [[NSDate date] timeIntervalSince1970]) < 10);
    // read and writes with RadarKVStore
    [RadarSettings setFeatureSettings :[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:YES]];
    [RadarSettings updateLastTrackedTime];
    XCTAssertTrue(([[RadarSettings lastTrackedTime] timeIntervalSince1970] - [[NSDate date] timeIntervalSince1970]) < 10);
    // ensure that no logs are created by the discrepency
    XCTAssertEqual(0, [[RadarLogBuffer sharedInstance] flushableLogs].count);
    // check that discrepency will not trigger logging
    [RadarSettings setFeatureSettings :[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:NO]];
    [[NSUserDefaults standardUserDefaults] setDouble:1234 forKey:kLastTrackedTime];
    [RadarSettings lastTrackedTime];
    XCTAssertEqual(1, [[RadarLogBuffer sharedInstance] flushableLogs].count);
}

- (void)test_RadarSettings_verifiedHost {
   // read with NSUserDefaults
   NSString *const dummyVerifiedHost = @"dummyVerifiedHost";
   [[NSUserDefaults standardUserDefaults] setObject:dummyVerifiedHost forKey:kVerifiedHost];
   [[RadarKVStore sharedInstance] setObject:dummyVerifiedHost forKey:kVerifiedHost];
    XCTAssertEqualObjects(dummyVerifiedHost, [RadarSettings verifiedHost]);
    // read and writes with RadarKVStore
    [RadarSettings setFeatureSettings :[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:YES]];
    XCTAssertEqualObjects(dummyVerifiedHost, [RadarSettings verifiedHost]);
    // ensure that no logs are created by the discrepency
    XCTAssertEqual(0, [[RadarLogBuffer sharedInstance] flushableLogs].count);
    // check that discrepency will not trigger logging
    [RadarSettings setFeatureSettings :[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:NO]];
    [[NSUserDefaults standardUserDefaults] setObject:@"1234" forKey:kVerifiedHost];
    [RadarSettings verifiedHost];
    XCTAssertEqual(1, [[RadarLogBuffer sharedInstance] flushableLogs].count); 
}

- (void)test_RadarSettings_userDebug {
    //reads and writes with NSUserDefaults
    BOOL dummyUserDebug = YES;
    [RadarSettings setUserDebug:dummyUserDebug];
    XCTAssertEqual(dummyUserDebug, [RadarSettings userDebug]);
    // read and writes with RadarKVStore
    [RadarSettings setFeatureSettings :[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:YES]];
    BOOL dummyUserDebug2 = NO;
    [RadarSettings setUserDebug:dummyUserDebug2];
    XCTAssertEqual(dummyUserDebug2, [RadarSettings userDebug]);
    // ensure that no logs are created by the discrepency
    XCTAssertEqual(0, [[RadarLogBuffer sharedInstance] flushableLogs].count);
    // check that discrepency will trigger logging
    [RadarSettings setFeatureSettings :[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:NO]];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kUserDebug];
    [RadarSettings userDebug];
    XCTAssertEqual(1, [[RadarLogBuffer sharedInstance] flushableLogs].count);
}

- (void)test_RadarSettings_lastAppOpenTime {
    // reads and writes with NSUserDefaults
    [RadarSettings updateLastAppOpenTime];
    XCTAssertTrue(([[RadarSettings lastAppOpenTime] timeIntervalSince1970] - [[NSDate date] timeIntervalSince1970]) < 10);
    // read and writes with RadarKVStore
    [RadarSettings setFeatureSettings :[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:YES]];
    [RadarSettings updateLastAppOpenTime];
    XCTAssertTrue(([[RadarSettings lastAppOpenTime] timeIntervalSince1970] - [[NSDate date] timeIntervalSince1970]) < 10);
    // ensure that no logs are created by the discrepency
    XCTAssertEqual(0, [[RadarLogBuffer sharedInstance] flushableLogs].count);
    // check that discrepency will not trigger logging
    [RadarSettings setFeatureSettings :[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:NO]];
    [[NSUserDefaults standardUserDefaults] setDouble:1234 forKey:kLastAppOpenTime];
    [RadarSettings lastAppOpenTime];
    XCTAssertEqual(1, [[RadarLogBuffer sharedInstance] flushableLogs].count);
}

// test radar state migration
- (void)test_RadarState_migration {

    // verify that the migrationFlag is off
    XCTAssertTrue(!self.radarKVStore.radarKVStoreMigrationComplete);

    // start with nsuserdefault filled with values
    CLLocationCoordinate2D dummyCoordinate = CLLocationCoordinate2DMake(1.0, 2.0);
    CLLocation *dummyLastLocation = [[CLLocation alloc] initWithCoordinate:dummyCoordinate altitude:1.0 horizontalAccuracy:3.0 verticalAccuracy:4.0 timestamp:[NSDate date]];
    NSDictionary *dummyLastLocationDict = [RadarUtils dictionaryForLocation:dummyLastLocation];
    [[NSUserDefaults standardUserDefaults] setObject:dummyLastLocationDict forKey:kLastLocation];
    CLLocationCoordinate2D dummyCoordinate2 = CLLocationCoordinate2DMake(3.0, 4.0);
    CLLocation *dummyLastMovedLocation = [[CLLocation alloc] initWithCoordinate:dummyCoordinate2 altitude:3.0 horizontalAccuracy:4.0 verticalAccuracy:5.0 timestamp:[NSDate date]];
    NSDictionary *dummyLastMovedLocationDict = [RadarUtils dictionaryForLocation:dummyLastMovedLocation];
    [[NSUserDefaults standardUserDefaults] setObject:dummyLastMovedLocationDict forKey:kLastMovedLocation];
    NSDate *dummyLastMovedAt = [NSDate date];
    [[NSUserDefaults standardUserDefaults] setObject:dummyLastMovedAt forKey:kLastMovedAt];
    BOOL dummyStopped = YES;
    [[NSUserDefaults standardUserDefaults] setBool:dummyStopped forKey:kStopped];
    NSDate *dummyLastSentAt = [NSDate date];
    [[NSUserDefaults standardUserDefaults] setObject:dummyLastSentAt forKey:kLastSentAt];
    BOOL dummyCanExit = YES;
    [[NSUserDefaults standardUserDefaults] setBool:dummyCanExit forKey:kCanExit];
    CLLocationCoordinate2D dummyCoordinate3 = CLLocationCoordinate2DMake(5.0, 6.0);
    CLLocation *dummyLastFailedStoppedLocation = [[CLLocation alloc] initWithCoordinate:dummyCoordinate3 altitude:5.0 horizontalAccuracy:6.0 verticalAccuracy:7.0 timestamp:[NSDate date]];
    NSDictionary *dummyLastFailedStoppedLocationDict = [RadarUtils dictionaryForLocation:dummyLastFailedStoppedLocation];
    [[NSUserDefaults standardUserDefaults] setObject:dummyLastFailedStoppedLocationDict forKey:kLastFailedStoppedLocation];
    NSArray<NSString *> *dummyGeofenceIds = @[@"123", @"456"];
    [[NSUserDefaults standardUserDefaults] setObject:dummyGeofenceIds forKey:kGeofenceIds];
    NSString *const dummyPlaceId = @"dummyPlaceId";
    [[NSUserDefaults standardUserDefaults] setObject:dummyPlaceId forKey:kPlaceId];
    NSArray<NSString *> *dummyRegionIds = @[@"123", @"456"];
    [[NSUserDefaults standardUserDefaults] setObject:dummyRegionIds forKey:kRegionIds];
    NSArray<NSString *> *dummyBeaconIds = @[@"123", @"456"];
    [[NSUserDefaults standardUserDefaults] setObject:dummyBeaconIds forKey:kBeaconIds];

    [RadarState migrateToRadarKVStore];
    // verify that the values are written to radarStrorageSystem and readable by the new radarState
    XCTAssertTrue([self compareCLLocation:dummyLastLocation with:[RadarState lastLocation]]);
    XCTAssertTrue([self compareCLLocation:dummyLastMovedLocation with:[RadarState lastMovedLocation]]);
    XCTAssertEqualObjects(dummyLastMovedAt, [RadarState lastMovedAt]);
    XCTAssertEqual(dummyStopped, [RadarState stopped]);
    XCTAssertEqualObjects(dummyLastSentAt, [RadarState lastSentAt]);
    XCTAssertEqual(dummyCanExit, [RadarState canExit]);
    XCTAssertTrue([self compareCLLocation:dummyLastFailedStoppedLocation with:[RadarState lastFailedStoppedLocation]]);
    XCTAssertEqualObjects(dummyGeofenceIds, [RadarState geofenceIds]);
    XCTAssertEqualObjects(dummyPlaceId, [RadarState placeId]);
    XCTAssertEqualObjects(dummyRegionIds, [RadarState regionIds]);
    XCTAssertEqualObjects(dummyBeaconIds, [RadarState beaconIds]);
}

- (void)test_RadarState_lastLocation {
    // reads and writes with NSUserDefaults
    CLLocationCoordinate2D dummyCoordinate = CLLocationCoordinate2DMake(1.0, 2.0);
    CLLocation *dummyLastLocation = [[CLLocation alloc] initWithCoordinate:dummyCoordinate altitude:1.0 horizontalAccuracy:3.0 verticalAccuracy:4.0 timestamp:[NSDate date]];
    [RadarState setLastLocation:dummyLastLocation];
    XCTAssertTrue([self compareCLLocation:dummyLastLocation with:[RadarState lastLocation]]);
    // read and writes with RadarKVStore
    [RadarSettings setFeatureSettings :[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:YES]];
    CLLocationCoordinate2D dummyCoordinate2 = CLLocationCoordinate2DMake(3.0, 4.0);
    CLLocation *dummyLastLocation2 = [[CLLocation alloc] initWithCoordinate:dummyCoordinate2 altitude:3.0 horizontalAccuracy:4.0 verticalAccuracy:5.0 timestamp:[NSDate date]];
    [RadarState setLastLocation:dummyLastLocation2];
    XCTAssertTrue([self compareCLLocation:dummyLastLocation2 with:[RadarState lastLocation]]);
    // ensure that no logs are created by the discrepency
    XCTAssertEqual(0, [[RadarLogBuffer sharedInstance] flushableLogs].count);
    // ensure that discrepency will trigger logging
    [RadarSettings setFeatureSettings :[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:NO]]; 
    [RadarState lastLocation];
    [[NSUserDefaults standardUserDefaults] setObject:[RadarUtils dictionaryForLocation:dummyLastLocation] forKey:kLastLocation];
    [RadarState lastLocation];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kLastLocation];
    [RadarState lastLocation];
    XCTAssertEqual(3, [[RadarLogBuffer sharedInstance] flushableLogs].count);
}

- (void)test_RadarState_lastMovedLocation {
    // reads and writes with NSUserDefaults
    CLLocationCoordinate2D dummyCoordinate = CLLocationCoordinate2DMake(1.0, 2.0);
    CLLocation *dummyLastMovedLocation = [[CLLocation alloc] initWithCoordinate:dummyCoordinate altitude:1.0 horizontalAccuracy:3.0 verticalAccuracy:4.0 timestamp:[NSDate date]];
    [RadarState setLastMovedLocation:dummyLastMovedLocation];
    XCTAssertTrue([self compareCLLocation:dummyLastMovedLocation with:[RadarState lastMovedLocation]]);
    // read and writes with RadarKVStore
    [RadarSettings setFeatureSettings :[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:YES]]; 
    CLLocationCoordinate2D dummyCoordinate2 = CLLocationCoordinate2DMake(3.0, 4.0);
    CLLocation *dummyLastMovedLocation2 = [[CLLocation alloc] initWithCoordinate:dummyCoordinate2 altitude:3.0 horizontalAccuracy:4.0 verticalAccuracy:5.0 timestamp:[NSDate date]];
    [RadarState setLastMovedLocation:dummyLastMovedLocation2];
    XCTAssertTrue([self compareCLLocation:dummyLastMovedLocation2 with:[RadarState lastMovedLocation]]);
    // ensure that no logs are created by the discrepency
    XCTAssertEqual(0, [[RadarLogBuffer sharedInstance] flushableLogs].count); 
    // ensure that discrepency will trigger logging
    [RadarSettings setFeatureSettings :[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:NO]]; 
    [RadarState lastMovedLocation];
    [[NSUserDefaults standardUserDefaults] setObject:[RadarUtils dictionaryForLocation:dummyLastMovedLocation] forKey:kLastMovedLocation];
    [RadarState lastMovedLocation];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kLastMovedLocation];
    [RadarState lastMovedLocation];
    XCTAssertEqual(3, [[RadarLogBuffer sharedInstance] flushableLogs].count);
}

- (void)test_RadarStare_lastMovedAt {
    // reads and writes with NSUserDefaults
    NSDate *dummyLastMovedAt = [NSDate date];
    [RadarState setLastMovedAt:dummyLastMovedAt];
    XCTAssertEqualObjects(dummyLastMovedAt, [RadarState lastMovedAt]);
    // read and writes with RadarKVStore
    [RadarSettings setFeatureSettings :[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:YES]];
    NSDate *dummyLastMovedAt2 = [NSDate date];
    [RadarState setLastMovedAt:dummyLastMovedAt2];
    XCTAssertEqualObjects(dummyLastMovedAt2, [RadarState lastMovedAt]);
    // ensure that no logs are created by the discrepency
    XCTAssertEqual(0, [[RadarLogBuffer sharedInstance] flushableLogs].count); 
    // ensure that discrepency will trigger logging
    [RadarSettings setFeatureSettings :[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:NO]];
    [RadarState lastMovedAt];
    [[NSUserDefaults standardUserDefaults] setObject:dummyLastMovedAt forKey:kLastMovedAt];
    [RadarState lastMovedAt];
    [RadarState setLastMovedAt:dummyLastMovedAt];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kLastMovedAt];
    [RadarState lastMovedAt];
    XCTAssertEqual(3, [[RadarLogBuffer sharedInstance] flushableLogs].count);
}

- (void)test_RadarState_stopped {
    // reads and writes with NSUserDefaults
    BOOL dummyStopped = YES;
    [RadarState setStopped:dummyStopped];
    XCTAssertEqual(dummyStopped, [RadarState stopped]);
    // read and writes with RadarKVStore
    [RadarSettings setFeatureSettings :[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:YES]]; 
    BOOL dummyStopped2 = NO;
    [RadarState setStopped:dummyStopped2];
    XCTAssertEqual(dummyStopped2, [RadarState stopped]);
    // ensure that no logs are created by the discrepency
    XCTAssertEqual(0, [[RadarLogBuffer sharedInstance] flushableLogs].count); 
    // ensure that discrepency will trigger logging
    [RadarSettings setFeatureSettings :[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:NO]]; 
    [RadarState stopped];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kStopped];
    [RadarState stopped];
    [RadarState setStopped:dummyStopped];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kStopped];
    [RadarState stopped];
    XCTAssertEqual(3, [[RadarLogBuffer sharedInstance] flushableLogs].count);
}

- (void)test_RadarState_lastSentAt {
    // reads and writes with NSUserDefaults
    [RadarState updateLastSentAt];
    XCTAssertTrue(([[RadarState lastSentAt] timeIntervalSince1970] - [[NSDate date] timeIntervalSince1970]) < 1);
    // read and writes with RadarKVStore
    [RadarSettings setFeatureSettings :[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO  useRadarKVStore:YES]]; 
    [RadarState updateLastSentAt];
    XCTAssertTrue(([[RadarState lastSentAt] timeIntervalSince1970] - [[NSDate date] timeIntervalSince1970]) < 1);
    // ensure that no logs are created by the discrepency
    XCTAssertEqual(0, [[RadarLogBuffer sharedInstance] flushableLogs].count); 
    // ensure that discrepency will trigger logging
    [RadarSettings setFeatureSettings :[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO  useRadarKVStore:NO]]; 
    [RadarState lastSentAt];
    NSDate *dummyLastSentAt = [NSDate date];
    [[NSUserDefaults standardUserDefaults] setObject:dummyLastSentAt forKey:kLastSentAt];
    [RadarState lastSentAt];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kLastSentAt];
    [RadarState lastSentAt];
    XCTAssertEqual(3, [[RadarLogBuffer sharedInstance] flushableLogs].count);
}

- (void)test_RadarState_canExit {
    // reads and writes with NSUserDefaults
    BOOL dummyCanExit = YES;
    [RadarState setCanExit:dummyCanExit];
    XCTAssertEqual(dummyCanExit, [RadarState canExit]);
    // read and writes with RadarKVStore
    [RadarSettings setFeatureSettings :[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO  useRadarKVStore:YES]]; 
    BOOL dummyCanExit2 = NO;
    [RadarState setCanExit:dummyCanExit2];
    XCTAssertEqual(dummyCanExit2, [RadarState canExit]);
    // ensure that no logs are created by the discrepency
    XCTAssertEqual(0, [[RadarLogBuffer sharedInstance] flushableLogs].count); 
    // ensure that discrepency will trigger logging
    [RadarSettings setFeatureSettings :[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO  useRadarKVStore:NO]]; 
    [RadarState canExit];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kCanExit];
    [RadarState canExit];
    [RadarState setCanExit:dummyCanExit];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCanExit];
    [RadarState canExit];
    XCTAssertEqual(3, [[RadarLogBuffer sharedInstance] flushableLogs].count);
}

- (void)test_RadarState_lastFailedStoppedLocation {
    // reads and writes with NSUserDefaults
    CLLocationCoordinate2D dummyCoordinate = CLLocationCoordinate2DMake(1.0, 2.0);
    CLLocation *dummyLastFailedStoppedLocation = [[CLLocation alloc] initWithCoordinate:dummyCoordinate altitude:1.0 horizontalAccuracy:3.0 verticalAccuracy:4.0 timestamp:[NSDate date]];
    [RadarState setLastFailedStoppedLocation:dummyLastFailedStoppedLocation];
    XCTAssertTrue([self compareCLLocation:dummyLastFailedStoppedLocation with:[RadarState lastFailedStoppedLocation]]);
    [RadarState setLastFailedStoppedLocation:nil];
    XCTAssertNil([RadarState lastFailedStoppedLocation]);
    // read and writes with RadarKVStore
    [RadarSettings setFeatureSettings :[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO  useRadarKVStore:YES]]; 
    CLLocationCoordinate2D dummyCoordinate2 = CLLocationCoordinate2DMake(3.0, 4.0);
    CLLocation *dummyLastFailedStoppedLocation2 = [[CLLocation alloc] initWithCoordinate:dummyCoordinate2 altitude:3.0 horizontalAccuracy:4.0 verticalAccuracy:5.0 timestamp:[NSDate date]];
    [RadarState setLastFailedStoppedLocation:dummyLastFailedStoppedLocation2];
    XCTAssertTrue([self compareCLLocation:dummyLastFailedStoppedLocation2 with:[RadarState lastFailedStoppedLocation]]);
    [RadarState setLastFailedStoppedLocation:nil];
    XCTAssertNil([RadarState lastFailedStoppedLocation]);
    // ensure that no logs are created by the discrepency
    XCTAssertEqual(0, [[RadarLogBuffer sharedInstance] flushableLogs].count); 
    // ensure that discrepency will trigger logging
    [RadarSettings setFeatureSettings :[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO  useRadarKVStore:NO]]; 
    [[NSUserDefaults standardUserDefaults] setObject:[RadarUtils dictionaryForLocation:dummyLastFailedStoppedLocation] forKey:kLastFailedStoppedLocation];
    [RadarState lastFailedStoppedLocation];
    [RadarState setLastFailedStoppedLocation:dummyLastFailedStoppedLocation];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kLastFailedStoppedLocation];
    [RadarState lastFailedStoppedLocation];
    [[NSUserDefaults standardUserDefaults] setObject:[RadarUtils dictionaryForLocation:dummyLastFailedStoppedLocation2] forKey:kLastFailedStoppedLocation];
    [RadarState lastFailedStoppedLocation]; 
    XCTAssertEqual(3, [[RadarLogBuffer sharedInstance] flushableLogs].count);
}

- (void)test_RadarState_geofenceIds {
    // reads and writes with NSUserDefaults
    NSArray<NSString *> *dummyGeofenceIds = @[@"123", @"456"];
    [RadarState setGeofenceIds:dummyGeofenceIds];
    XCTAssertEqualObjects(dummyGeofenceIds, [RadarState geofenceIds]);
    [RadarState setGeofenceIds:nil];
    XCTAssertNil([RadarState geofenceIds]);
    // read and writes with RadarKVStore
    [RadarSettings setFeatureSettings :[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO  useRadarKVStore:YES]]; 
    NSArray<NSString *> *dummyGeofenceIds2 = @[@"1234", @"4567"];
    [RadarState setGeofenceIds:dummyGeofenceIds2];
    XCTAssertEqualObjects(dummyGeofenceIds2, [RadarState geofenceIds]);
    [RadarState setGeofenceIds:nil];
    XCTAssertNil([RadarState geofenceIds]);
    // ensure that no logs are created by the discrepency
    XCTAssertEqual(0, [[RadarLogBuffer sharedInstance] flushableLogs].count); 
    // ensure that discrepency will trigger logging
    [RadarSettings setFeatureSettings :[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO  useRadarKVStore:NO]]; 
    [[NSUserDefaults standardUserDefaults] setObject:dummyGeofenceIds forKey:kGeofenceIds];
    [RadarState geofenceIds];
    [RadarState setGeofenceIds:dummyGeofenceIds];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kGeofenceIds];
    [RadarState geofenceIds];
    [[NSUserDefaults standardUserDefaults] setObject:dummyGeofenceIds2 forKey:kGeofenceIds];
    [RadarState geofenceIds];
    XCTAssertEqual(3, [[RadarLogBuffer sharedInstance] flushableLogs].count);
}

- (void)test_RadarState_placeId {
    // reads and writes with NSUserDefaults
    NSString *const dummyPlaceId = @"dummyPlaceId";
    [RadarState setPlaceId:dummyPlaceId];
    XCTAssertEqualObjects(dummyPlaceId, [RadarState placeId]);
    [RadarState setPlaceId:nil];
    XCTAssertNil([RadarState placeId]);
    // read and writes with RadarKVStore
    [RadarSettings setFeatureSettings :[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO  useRadarKVStore:YES]]; 
    NSString *const dummyPlaceId2 = @"dummyPlaceId2";
    [RadarState setPlaceId:dummyPlaceId2];
    XCTAssertEqualObjects(dummyPlaceId2, [RadarState placeId]);
    [RadarState setPlaceId:nil];
    XCTAssertNil([RadarState placeId]);
    // ensure that no logs are created by the discrepency
    XCTAssertEqual(0, [[RadarLogBuffer sharedInstance] flushableLogs].count); 
    // ensure that discrepency will trigger logging
    [RadarSettings setFeatureSettings :[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO  useLogPersistence:NO useRadarKVStore:NO]]; 
    [[NSUserDefaults standardUserDefaults] setObject:dummyPlaceId forKey:kPlaceId];
    [RadarState placeId];
    [RadarState setPlaceId:dummyPlaceId];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kPlaceId];
    [RadarState placeId];
    [[NSUserDefaults standardUserDefaults] setObject:dummyPlaceId2 forKey:kPlaceId];
    [RadarState placeId];
    XCTAssertEqual(3, [[RadarLogBuffer sharedInstance] flushableLogs].count);
}

- (void)test_RadarState_regionIds {
    // reads and writes with NSUserDefaults
    NSArray<NSString *> *dummyRegionIds = @[@"123", @"456"];
    [RadarState setRegionIds:dummyRegionIds];
    XCTAssertEqualObjects(dummyRegionIds, [RadarState regionIds]);
    [RadarState setRegionIds:nil];
    XCTAssertNil([RadarState regionIds]);
    // read and writes with RadarKVStore
    [RadarSettings setFeatureSettings:[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO  useLogPersistence:NO useRadarKVStore:YES]]; 
    NSArray<NSString *> *dummyRegionIds2 = @[@"1234", @"4567"];
    [RadarState setRegionIds:dummyRegionIds2];
    XCTAssertEqualObjects(dummyRegionIds2, [RadarState regionIds]);
    [RadarState setRegionIds:nil];
    XCTAssertNil([RadarState regionIds]);
    // ensure that no logs are created by the discrepency
    XCTAssertEqual(0, [[RadarLogBuffer sharedInstance] flushableLogs].count); 
    // ensure that discrepency will trigger logging
    [RadarSettings setFeatureSettings:[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO  useLogPersistence:NO useRadarKVStore:NO]]; 
    [[NSUserDefaults standardUserDefaults] setObject:dummyRegionIds forKey:kRegionIds];
    [RadarState regionIds];
    [RadarState setRegionIds:dummyRegionIds];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kRegionIds];
    [RadarState regionIds];
    [[NSUserDefaults standardUserDefaults] setObject:dummyRegionIds2 forKey:kRegionIds];
    [RadarState regionIds];
    XCTAssertEqual(3, [[RadarLogBuffer sharedInstance] flushableLogs].count);
}

- (void)test_RadarState_beaconIds {
    // reads and writes with NSUserDefaults
    NSArray<NSString *> *dummyBeaconIds = @[@"123", @"456"];
    [RadarState setBeaconIds:dummyBeaconIds];
    XCTAssertEqualObjects(dummyBeaconIds, [RadarState beaconIds]);
    [RadarState setBeaconIds:nil];
    XCTAssertNil([RadarState beaconIds]);
    // read and writes with RadarKVStore
    [RadarSettings setFeatureSettings:[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO  useLogPersistence:NO useRadarKVStore:YES]]; 
    NSArray<NSString *> *dummyBeaconIds2 = @[@"1234", @"4567"];
    [RadarState setBeaconIds:dummyBeaconIds2];
    XCTAssertEqualObjects(dummyBeaconIds2, [RadarState beaconIds]);
    [RadarState setBeaconIds:nil];
    XCTAssertNil([RadarState beaconIds]);
    // ensure that no logs are created by the discrepency
    XCTAssertEqual(0, [[RadarLogBuffer sharedInstance] flushableLogs].count); 
    // ensure that discrepency will trigger logging
    [RadarSettings setFeatureSettings:[[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO  useLogPersistence:NO useRadarKVStore:NO]]; 
    [[NSUserDefaults standardUserDefaults] setObject:dummyBeaconIds forKey:kBeaconIds];
    [RadarState beaconIds];
    [RadarState setBeaconIds:dummyBeaconIds];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kBeaconIds];
    [RadarState beaconIds];
    [[NSUserDefaults standardUserDefaults] setObject:dummyBeaconIds2 forKey:kBeaconIds];
    [RadarState beaconIds];
    XCTAssertEqual(3, [[RadarLogBuffer sharedInstance] flushableLogs].count);
}

// test radar replay buffer migration
- (void)test_ReplayBuffer_migration {
    XCTAssertFalse(self.radarKVStore.radarKVStoreMigrationComplete);
    NSMutableArray<RadarReplay *> *replays = [NSMutableArray<RadarReplay *> new];
    //add 5 replays to the buffer
    for (int i = 0; i < 5; i++) {
        NSMutableDictionary *replayParams = [NSMutableDictionary new];
        replayParams[@"key1"] = [NSString stringWithFormat:@"value1_%d", i];
        replayParams[@"key2"] = [RadarUtils timeZoneOffset];
        RadarReplay *replay = [[RadarReplay alloc] initWithParams:replayParams];
        [replays addObject:replay];
    }
    NSData *replaysData = [NSKeyedArchiver archivedDataWithRootObject:replays];
    [[NSUserDefaults standardUserDefaults] setObject:replaysData forKey:@"radar-replays"];
    [RadarReplayBuffer migrateToRadarKVStore];
    NSMutableArray<RadarReplay *> *replays2 = [self.radarKVStore objectForKey:@"radar-replays"];
    for (int i = 0; i < 5; i++) {
        XCTAssertEqualObjects(replays[i].replayParams[@"key1"], replays2[i].replayParams[@"key1"]);
        XCTAssertEqualObjects(replays[i].replayParams[@"key2"], replays2[i].replayParams[@"key2"]);
    }
}


- (void)test_migration_safeToRunOnFreshInstall {
    // call migration on empty values

    [RadarState migrateToRadarKVStore];
    [RadarSettings migrateToRadarKVStore];
    [RadarReplayBuffer migrateToRadarKVStore];

    // verify that correct defaults are being read

    // RadarSettings
    XCTAssertNil([RadarSettings publishableKey]);
    XCTAssertNotNil([RadarSettings installId]);
    XCTAssertEqualObjects([RadarSettings sessionId], @"0");
    XCTAssertNil([RadarSettings _id]);
    XCTAssertNil([RadarSettings userId]);
    XCTAssertNil([RadarSettings __description]);
    XCTAssertNil([RadarSettings metadata]);
    XCTAssertFalse([RadarSettings anonymousTrackingEnabled]);
    XCTAssertFalse([RadarSettings tracking]);
    XCTAssertEqualObjects([RadarSettings trackingOptions], RadarTrackingOptions.presetEfficient);
    XCTAssertEqualObjects([RadarSettings featureSettings], [[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:NO]);
    XCTAssertNil([RadarSettings previousTrackingOptions]);
    XCTAssertNil([RadarSettings remoteTrackingOptions]);
    XCTAssertNil([RadarSettings tripOptions]);
    XCTAssertTrue(RadarLogLevelInfo==[RadarSettings logLevel]);
    XCTAssertNil([RadarSettings beaconUUIDs]);
    XCTAssertEqualObjects([RadarSettings host], @"https://api.radar.io");
    XCTAssertEqualObjects([RadarSettings verifiedHost], @"https://api-verified.radar.io");
    XCTAssertNotNil([RadarSettings lastTrackedTime]);
    XCTAssertNotNil([RadarSettings lastAppOpenTime]);
    XCTAssertFalse([RadarSettings userDebug]);

    // RadarState
    XCTAssertNil([RadarState lastLocation]);
    XCTAssertNil([RadarState lastMovedLocation]);
    XCTAssertNil([RadarState lastMovedAt]);
    XCTAssertFalse([RadarState stopped]);
    XCTAssertNil([RadarState lastSentAt]);
    XCTAssertFalse([RadarState canExit]);
    XCTAssertNil([RadarState lastFailedStoppedLocation]);
    XCTAssertNil([RadarState geofenceIds]);
    XCTAssertNil([RadarState placeId]);
    XCTAssertNil([RadarState regionIds]);
    XCTAssertNil([RadarState beaconIds]);

    // RadarReplayBuffer
    XCTAssertNil([self.radarKVStore objectForKey:@"radar-replays"]);
}


- (BOOL)compareCLLocation:(CLLocation *)location1 with:(CLLocation *)location2 {
    if ((location1 == nil && location2 != nil) || (location1 != nil && location2 == nil)) {
        return NO;
    }
    if (location1.coordinate.latitude != location2.coordinate.latitude) {
        return NO;
    }
    if (location1.coordinate.longitude != location2.coordinate.longitude) {
        return NO;
    }
    if (location1.horizontalAccuracy != location2.horizontalAccuracy) {
        return NO;
    }
    if (location1.verticalAccuracy != location2.verticalAccuracy) {
        return NO;
    }
    if (location1.timestamp != location2.timestamp) {
        return NO;
    }
    return YES;
}

@end
