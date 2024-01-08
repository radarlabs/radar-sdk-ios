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
#import "../RadarSDK/RadarState.h"
#import "../RadarSDK/RadarUtils.h"
#import <Foundation/Foundation.h>

@interface RadarUserDefaultsTest : XCTestCase
@property (nonatomic, strong) RadarUserDefaults *radarUserDefault;

@end

@implementation RadarUserDefaultsTest

- (void)setUp {
    [super setUp];
    self.radarUserDefault = [RadarUserDefaults sharedInstance];
    [self.radarUserDefault removeAllObjects];
    [self.radarUserDefault setMigrationCompleteFlag:NO];
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
    
    // test for meaningful default values
    XCTAssertFalse([self.radarUserDefault boolForKey:@"emptyKey"]);
    
}

- (void)test_RadarUserDefault_setAndGetString {
    [self.radarUserDefault setString:@"123abc!@#" forKey:@"string1"];
    XCTAssertEqualObjects(@"123abc!@#", [self.radarUserDefault stringForKey:@"string1"]);
    [self.radarUserDefault setString:@"I like working here" forKey:@"string1"];
    XCTAssertEqualObjects(@"I like working here", [self.radarUserDefault stringForKey:@"string1"]);
    [self.radarUserDefault setString:@"hello world" forKey:@"string2"];
    XCTAssertEqualObjects(@"hello world", [self.radarUserDefault stringForKey:@"string2"]);
    
    // test for meaningful default values
    XCTAssertNil([self.radarUserDefault stringForKey:@"emptyKey"]);

    // test setting null removes data
    [self.radarUserDefault setString:nil forKey:@"string1"];
    XCTAssertNil([self.radarUserDefault stringForKey:@"string1"]);
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
    // test for string
    NSString *str = @"1234567890";
    [self.radarUserDefault setObject:str forKey:@"uuid"];
    XCTAssertEqualObjects(str, [self.radarUserDefault objectForKey:@"uuid"]);
    XCTAssertEqualObjects(str, [self.radarUserDefault stringForKey:@"uuid"]);
    // test for date
    NSDate *date = [NSDate date];
    [self.radarUserDefault setObject:date forKey:@"date"];
    XCTAssertEqualObjects(date, [self.radarUserDefault objectForKey:@"date"]);
    // test for radarTripOptions
    RadarTripOptions *tripOptions = [[RadarTripOptions alloc] initWithExternalId:@"123" destinationGeofenceTag:@"456" destinationGeofenceExternalId:@"789" scheduledArrivalAt:[NSDate date]];
    [self.radarUserDefault setObject:tripOptions forKey:@"tripOptions"];
    XCTAssertEqualObjects(tripOptions, [self.radarUserDefault objectForKey:@"tripOptions"]);
    // test for radarfeatureSettings
    RadarFeatureSettings *featureSettings = [[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:YES useLogPersistence:NO];
    [self.radarUserDefault setObject:featureSettings forKey:@"featureSettings"];
    XCTAssertEqualObjects(featureSettings, [self.radarUserDefault objectForKey:@"featureSettings"]);
    // test for radartrackingOptions
    RadarTrackingOptions *trackingOptions = RadarTrackingOptions.presetContinuous;
    [self.radarUserDefault setObject:trackingOptions forKey:@"trackingOptions"];
    XCTAssertEqualObjects(trackingOptions, [self.radarUserDefault objectForKey:@"trackingOptions"]);
    // test for CLLocation
    CLLocation *location = [[CLLocation alloc] initWithLatitude:1.0 longitude:2.0];
    [self.radarUserDefault setObject:location forKey:@"location"];
    CLLocation *location2= [self.radarUserDefault objectForKey:@"location"];
    XCTAssertTrue(location.coordinate.latitude == location2.coordinate.latitude);
    XCTAssertTrue(location.coordinate.longitude == location2.coordinate.longitude);
    XCTAssertEqualObjects(location.timestamp, location2.timestamp);
    
    // test for meaningful default values
    XCTAssertNil([self.radarUserDefault objectForKey:@"emptyKey"]);

    // test setting null removes data
    [self.radarUserDefault setObject:nil forKey:@"obj1"];
    XCTAssertNil([self.radarUserDefault objectForKey:@"obj1"]);

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
    
    // test for meaningful default values
    XCTAssertNil([self.radarUserDefault dictionaryForKey:@"emptyKey"]);

    // test setting null removes data
    [self.radarUserDefault setDictionary:nil forKey:@"dic1"];
    XCTAssertNil([self.radarUserDefault dictionaryForKey:@"dic1"]);
}

- (void)test_RadarUserDefault_setAndGetDouble {
    [self.radarUserDefault setDouble:1.0 forKey:@"double1"];
    [self.radarUserDefault setDouble:2.0 forKey:@"double2"];
    XCTAssertEqual(1.0, [self.radarUserDefault doubleForKey:@"double1"]);
    XCTAssertEqual(2.0, [self.radarUserDefault doubleForKey:@"double2"]);
    
    // test for meaningful default values
    XCTAssertEqual(0, [self.radarUserDefault doubleForKey:@"emptyKey"]);
}

- (void)test_RadarUserDefault_setAndGetInterger {
    [self.radarUserDefault setInteger:1 forKey:@"int1"];
    [self.radarUserDefault setInteger:2 forKey:@"int2"];
    XCTAssertEqual(1, [self.radarUserDefault integerForKey:@"int1"]);
    XCTAssertEqual(2, [self.radarUserDefault integerForKey:@"int2"]);
    
    // test for meaningful default values
    XCTAssertEqual(0, [self.radarUserDefault integerForKey:@"emptyKey"]);
}

- (void)test_RadarSetting_migration {
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

    [RadarSettings migrateToRadarUserDefaults];
    // verify that the migrationFlag is on, NOTE: no longer needed?
    //XCTAssertTrue(self.radarUserDefault.migrationCompleteFlag);
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

// test radar state migration
-(void) test_RadarState_migration {
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

    // verify that the migrationFlag is off
    XCTAssertTrue(!self.radarUserDefault.migrationCompleteFlag);

    // start with nsuserdefault filled with values
    CLLocationCoordinate2D dummyCoordinate = CLLocationCoordinate2DMake(1.0, 2.0);
    CLLocation *dummyLastLocation = [[CLLocation alloc] initWithCoordinate:dummyCoordinate altitude:1.0 horizontalAccuracy:3.0 verticalAccuracy:4.0 timestamp:[NSDate date]];
    NSDictionary *dummyLastLocationDict = [RadarUtils dictionaryForLocation:dummyLastLocation];
    [[NSUserDefaults standardUserDefaults] setObject:dummyLastLocationDict forKey:kLastLocation];
    // CLLocation *dummyLastMovedLocation = [[CLLocation alloc] initWithLatitude:3.0 longitude:4.0];
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

    [RadarState migrateToRadarUserDefaults];
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


// test radar replay buffer migration

// test that these classes still work with "cold boot" on this version


//helper function to compare cllocation
- (BOOL)compareCLLocation:(CLLocation *)location1 with:(CLLocation *)location2 {
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
