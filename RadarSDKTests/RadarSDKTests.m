//
//  RadarSDKTests.m
//  RadarSDKTests
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

@import RadarSDK;
#import <XCTest/XCTest.h>

#import "../RadarSDK/RadarAPIClient.h"
#import "../RadarSDK/RadarAPIHelper.h"
#import "../RadarSDK/RadarLocationManager.h"
#import "../RadarSDK/RadarSettings.h"
#import "../RadarSDK/RadarLogBuffer.h"
#import "../RadarSDK/RadarState.h"
#import "../RadarSDK/RadarGeofence+Internal.h"
#import "../RadarSDK/RadarCircleGeometry+Internal.h"
#import "../RadarSDK/RadarCoordinate+Internal.h"
#import "../RadarSDK/RadarBeacon+Internal.h"
#import "../RadarSDK/RadarPlace+Internal.h"
#import "CLLocationManagerMock.h"
#import "CLVisitMock.h"
#import "RadarAPIHelperMock.h"
#import "RadarPermissionsHelperMock.h"
#import "RadarTestUtils.h"
#import "RadarTripOptions.h"
#import "RadarFileStorage.h"
#import "RadarReplayBuffer.h"
#import <os/log.h>

#if __has_include(<RadarSDK/RadarSDK-Swift.h>)
#import <RadarSDK/RadarSDK-Swift.h>
#elif __has_include("RadarSDK-Swift.h")
#import "RadarSDK-Swift.h"
#endif

@interface RadarSDKTests : XCTestCase

@property (nonnull, strong, nonatomic) RadarAPIHelperMock *apiHelperMock;
@property (nonnull, strong, nonatomic) CLLocationManagerMock *locationManagerMock;
@property (nonnull, strong, nonatomic) RadarPermissionsHelperMock *permissionsHelperMock;
@property (nonatomic, strong) RadarFileStorage *fileSystem;
@property (nonatomic, strong) NSString *testFilePath;
@property (nonatomic, strong) RadarLogBuffer *logBuffer;
@property (nonatomic, strong) RadarReplayBuffer *replayBuffer;
@end

@implementation RadarSDKTests

static NSString *const kPublishableKey = @"prj_test_pk_0000000000000000000000000000000000000000";

#define AssertGeofencesOk(geofences) [self assertGeofencesOk:geofences]
- (void)assertGeofencesOk:(NSArray<RadarGeofence *> *)geofences {
    XCTAssertNotNil(geofences);
    for (RadarGeofence *geofence in geofences) {
        [self assertGeofenceOk:geofence];
    }
}

#define AssertGeofenceOk(geofence) [self assertGeofenceOk:geofence]
- (void)assertGeofenceOk:(RadarGeofence *)geofence {
    XCTAssertNotNil(geofence);
    XCTAssertNotNil(geofence.__description);
    XCTAssertNotNil(geofence.tag);
    XCTAssertNotNil(geofence.externalId);
    XCTAssertNotNil(geofence.metadata);
    XCTAssertNotNil(geofence.geometry);
}

#define AssertChainsOk(chains) [self assertChainsOk:chains]
- (void)assertChainsOk:(NSArray<RadarChain *> *)chains {
    XCTAssertNotNil(chains);
    for (RadarChain *chain in chains) {
        [self assertChainOk:chain];
    }
}

#define AssertChainOk(chain) [self assertChainOk:chain]
- (void)assertChainOk:(RadarChain *)chain {
    XCTAssertNotNil(chain);
    XCTAssertNotNil(chain.slug);
    XCTAssertNotNil(chain.name);
    XCTAssertNotNil(chain.externalId);
    XCTAssertNotNil(chain.metadata);
}

#define AssertPlacesOk(places) [self assertPlacesOk:places]
- (void)assertPlacesOk:(NSArray<RadarPlace *> *)places {
    XCTAssertNotNil(places);
    for (RadarPlace *place in places) {
        [self assertPlaceOk:place];
    }
}

#define AssertPlaceOk(place) [self assertPlaceOk:place]
- (void)assertPlaceOk:(RadarPlace *)place {
    XCTAssertNotNil(place);
    XCTAssertNotNil(place._id);
    XCTAssertNotNil(place.categories);
    XCTAssertNotEqual(place.categories.count, 0);
    if (place.chain) {
        AssertChainOk(place.chain);
    }
    XCTAssertNotNil(place.location);
}

#define AssertRegionOk(region) [self assertRegionOk:region]
- (void)assertRegionOk:(RadarRegion *)region {
    XCTAssertNotNil(region);
    XCTAssertNotNil(region._id);
    XCTAssertNotNil(region.name);
    XCTAssertNotNil(region.code);
    XCTAssertNotNil(region.type);
}

#define AssertSegmentsOk(segments) [self assertSegmentsOk:segments]
- (void)assertSegmentsOk:(NSArray<RadarSegment *> *)segments {
    XCTAssertNotNil(segments);
    for (RadarSegment *segment in segments) {
        [self assertSegmentOk:segment];
    }
}

#define AssertSegmentOk(segment) [self assertSegmentOk:segment]
- (void)assertSegmentOk:(RadarSegment *)segment {
    XCTAssertNotNil(segment);
    XCTAssertNotNil(segment.__description);
    XCTAssertNotNil(segment.externalId);
}

#define AssertTripOk(trip) [self assertTripOk:trip]
- (void)assertTripOk:(RadarTrip *)trip {
    XCTAssertNotNil(trip);
    XCTAssertNotNil(trip.externalId);
    XCTAssertNotNil(trip.metadata);
    XCTAssertNotNil(trip.destinationGeofenceTag);
    XCTAssertNotNil(trip.destinationGeofenceExternalId);
    XCTAssertNotNil(trip.destinationLocation);
    XCTAssertNotEqual(trip.etaDistance, 0);
    XCTAssertNotEqual(trip.etaDuration, 0);
    XCTAssertEqual(trip.status, RadarTripStatusStarted);
}

#define AssertFraudOk(fraud) [self assertFraudOk:fraud]
- (void)assertFraudOk:(RadarFraud *)fraud {
    XCTAssertNotNil(fraud);
    XCTAssertTrue(fraud.passed);
    XCTAssertTrue(fraud.bypassed);
    XCTAssertTrue(fraud.proxy);
    XCTAssertTrue(fraud.mocked);
    XCTAssertTrue(fraud.compromised);
    XCTAssertTrue(fraud.jumped);
}

#define AssertUserOk(user) [self assertUserOk:user]
- (void)assertUserOk:(RadarUser *)user {
    XCTAssertNotNil(user);
    XCTAssertNotNil(user._id);
    XCTAssertNotNil(user.userId);
    XCTAssertNotNil(user.deviceId);
    XCTAssertNotNil(user.__description);
    XCTAssertNotNil(user.metadata);
    XCTAssertNotNil(user.location);
    AssertGeofencesOk(user.geofences);
    AssertPlaceOk(user.place);
    AssertRegionOk(user.country);
    AssertRegionOk(user.state);
    AssertRegionOk(user.dma);
    AssertRegionOk(user.postalCode);
    AssertChainsOk(user.nearbyPlaceChains);
    AssertSegmentsOk(user.segments);
    AssertChainsOk(user.topChains);
    XCTAssertNotEqual(user.source, RadarLocationSourceUnknown);
    AssertTripOk(user.trip);
    AssertFraudOk(user.fraud);
}

#define AssertEventsOk(events) [self assertEventsOk:events]
- (void)assertEventsOk:(NSArray<RadarEvent *> *)events {
    XCTAssertNotNil(events);
    for (RadarEvent *event in events) {
        [self assertEventOk:event];
    }
}

#define AssertEventOk(event) [self assertEventOk:event]
- (void)assertEventOk:(RadarEvent *)event {
    XCTAssertNotNil(event);
    XCTAssertNotNil(event._id);
    XCTAssertNotNil(event.createdAt);
    XCTAssertNotNil(event.actualCreatedAt);
    XCTAssertNotEqual(event.type, RadarEventTypeUnknown);
    XCTAssertNotEqual(event.confidence, RadarEventConfidenceNone);
    XCTAssertNotNil(event.location);
    switch (event.type) {
    case RadarEventTypeUserEnteredGeofence:
        AssertGeofenceOk(event.geofence);
        break;
    case RadarEventTypeUserExitedGeofence:
        AssertGeofenceOk(event.geofence);
        XCTAssertNotEqual(event.duration, 0);
        break;
    case RadarEventTypeUserEnteredPlace:
        AssertPlaceOk(event.place);
        break;
    case RadarEventTypeUserExitedPlace:
        AssertPlaceOk(event.place);
        XCTAssertNotEqual(event.duration, 0);
        break;
    case RadarEventTypeUserNearbyPlaceChain:
        AssertPlaceOk(event.place);
        break;
    case RadarEventTypeUserEnteredRegionCountry:
        AssertRegionOk(event.region);
        break;
    case RadarEventTypeUserExitedRegionCountry:
        AssertRegionOk(event.region);
        break;
    case RadarEventTypeUserEnteredRegionState:
        AssertRegionOk(event.region);
        break;
    case RadarEventTypeUserExitedRegionState:
        AssertRegionOk(event.region);
        break;
    case RadarEventTypeUserEnteredRegionDMA:
        AssertRegionOk(event.region);
        break;
    case RadarEventTypeUserExitedRegionDMA:
        AssertRegionOk(event.region);
        break;
    default:
        break;
    }
}

#define AssertAddressesOk(addresses) [self assertAddressesOk:addresses]
- (void)assertAddressesOk:(NSArray<RadarAddress *> *)addresses {
    XCTAssertNotNil(addresses);
    for (RadarAddress *address in addresses) {
        [self assertAddressOk:address];
    }
}

#define AssertAddressOk(address) [self assertAddressOk:address]
- (void)assertAddressOk:(RadarAddress *)address {
    XCTAssertNotNil(address);
    XCTAssertNotEqual(address.coordinate.latitude, 0);
    XCTAssertNotEqual(address.coordinate.longitude, 0);
    XCTAssertNotNil(address.formattedAddress);
    XCTAssertNotNil(address.country);
    XCTAssertNotNil(address.countryCode);
    XCTAssertNotNil(address.countryFlag);
    XCTAssertNotNil(address.state);
    XCTAssertNotNil(address.stateCode);
    XCTAssertNotNil(address.postalCode);
    XCTAssertNotNil(address.city);
    XCTAssertNotNil(address.borough);
    XCTAssertNotNil(address.county);
    XCTAssertNotNil(address.neighborhood);
    XCTAssertNotNil(address.number);
    XCTAssertNotEqual(address.confidence, RadarAddressConfidenceNone);
}

#define AssertContextOk(context) [self assertContextOk:context]
- (void)assertContextOk:(RadarContext *)context {
    XCTAssertNotNil(context);
    AssertGeofencesOk(context.geofences);
    AssertPlaceOk(context.place);
    AssertRegionOk(context.country);
    AssertRegionOk(context.state);
    AssertRegionOk(context.dma);
    AssertRegionOk(context.postalCode);
}

#define AssertRouteOk(route) [self assertRouteOk:route]
- (void)assertRouteOk:(RadarRoute *)route {
    XCTAssertNotNil(route);
    XCTAssertNotNil(route.distance);
    XCTAssertNotNil(route.distance.text);
    XCTAssertNotEqual(route.distance.value, 0);
    XCTAssertNotNil(route.duration);
    XCTAssertNotNil(route.duration.text);
    XCTAssertNotEqual(route.duration.value, 0);
}

#define AssertRoutesOk(routes) [self assertRoutesOk:routes]
- (void)assertRoutesOk:(RadarRoutes *)routes {
    XCTAssertNotNil(routes);
    XCTAssertNotNil(routes.geodesic);
    XCTAssertNotNil(routes.geodesic.text);
    XCTAssertNotEqual(routes.geodesic.value, 0);
    AssertRouteOk(routes.foot);
    AssertRouteOk(routes.bike);
    AssertRouteOk(routes.car);
}

#pragma mark - EfficientTrackManager Test Helpers

- (RadarGeofence *)createTestGeofenceWithId:(NSString *)identifier
                                   latitude:(double)lat
                                  longitude:(double)lng
                                     radius:(double)radius {
    RadarCoordinate *center = [[RadarCoordinate alloc] initWithCoordinate:CLLocationCoordinate2DMake(lat, lng)];
    RadarCircleGeometry *geometry = [[RadarCircleGeometry alloc] initWithCenter:center radius:radius];
    return [[RadarGeofence alloc] initWithId:identifier description:@"Test Geofence" tag:@"test" externalId:identifier metadata:nil operatingHours:nil geometry:geometry];
}

- (RadarBeacon *)createTestBeaconWithId:(NSString *)identifier
                               latitude:(double)lat
                              longitude:(double)lng {
    RadarCoordinate *geometry = [[RadarCoordinate alloc] initWithCoordinate:CLLocationCoordinate2DMake(lat, lng)];
    return [[RadarBeacon alloc] initWithId:identifier description:@"Test Beacon" tag:@"test" externalId:identifier uuid:@"test-uuid" major:@"1" minor:@"1" metadata:nil geometry:geometry];
}

- (RadarPlace *)createTestPlaceWithId:(NSString *)identifier
                             latitude:(double)lat
                            longitude:(double)lng {
    RadarCoordinate *location = [[RadarCoordinate alloc] initWithCoordinate:CLLocationCoordinate2DMake(lat, lng)];
    return [[RadarPlace alloc] initWithId:identifier name:@"Test Place" categories:@[@"test"] chain:nil location:location group:@"test" metadata:nil address:nil];
}

- (void)clearEfficientTrackingState {
    [RadarState setNearbyGeofences:nil];
    [RadarState setNearbyBeacons:nil];
    [RadarState setNearbyPlaces:nil];
    [RadarState setSyncedRegion:nil];
    [RadarState setGeofenceIds:nil];
    [RadarState setBeaconIds:nil];
    [RadarState setPlaceId:nil];
    [RadarSettings setRemoteTrackingOptions:nil];
}

+ (void)setUp {
    XCTAssertFalse([Radar isInitialized]);
}

- (void)setUp {
    [super setUp];
    [Radar initializeWithPublishableKey:kPublishableKey];
    [RadarSettings setLogLevel:RadarLogLevelDebug];

    self.apiHelperMock = [RadarAPIHelperMock new];
    self.locationManagerMock = [CLLocationManagerMock new];
    self.permissionsHelperMock = [RadarPermissionsHelperMock new];

    [RadarAPIClient sharedInstance].apiHelper = self.apiHelperMock;
    [RadarLocationManager sharedInstance].locationManager = self.locationManagerMock;
    self.locationManagerMock.delegate = [RadarLocationManager sharedInstance];
    [RadarLocationManager sharedInstance].lowPowerLocationManager = self.locationManagerMock;
    [RadarLocationManager sharedInstance].permissionsHelper = self.permissionsHelperMock;
    self.fileSystem = [[RadarFileStorage alloc] init];
    self.testFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"testfile"];
    [[RadarLogBuffer sharedInstance]clearBuffer];
    [[RadarLogBuffer sharedInstance]setPersistentLogFeatureFlag:YES];
    [[RadarReplayBuffer sharedInstance]clearBuffer];
    
    // Clear user tags to ensure tests don't interfere with each other
    NSArray<NSString *> *existingTags = [Radar getTags];
    if (existingTags && existingTags.count > 0) {
        [Radar removeTags:existingTags];
    }
}

- (void)tearDown {
    [[NSFileManager defaultManager] removeItemAtPath:self.testFilePath error:nil];
    [[RadarLogBuffer sharedInstance]clearBuffer];
    [super tearDown];
}

- (void)test_Radar_initialize {
    XCTAssertEqualObjects(kPublishableKey, [RadarSettings publishableKey]);
    XCTAssertTrue([Radar isInitialized]);
}

- (void)test_Radar_setUserId {
    NSString *userId = @"userId";
    [Radar setUserId:userId];
    XCTAssertEqualObjects(userId, [Radar getUserId]);
}

- (void)test_Radar_setUserId_nil {
    NSString *userId = nil;
    [Radar setUserId:userId];
    XCTAssertEqualObjects(userId, [Radar getUserId]);
}

- (void)test_Radar_setDescription {
    NSString *description = @"description";
    [Radar setDescription:description];
    XCTAssertEqualObjects(description, [Radar getDescription]);
}

- (void)test_Radar_setDescription_nil {
    NSString *description = nil;
    [Radar setDescription:description];
    XCTAssertEqualObjects(description, [Radar getDescription]);
}

- (void)test_Radar_setMetadata {
    NSDictionary *metadata = @{@"foo": @"bar", @"baz": @YES, @"qux": @1};
    [Radar setMetadata:metadata];
    XCTAssertEqualObjects(metadata, [Radar getMetadata]);
}

- (void)test_Radar_setMetadata_nil {
    NSDictionary *metadata = nil;
    [Radar setMetadata:metadata];
    XCTAssertEqualObjects(metadata, [Radar getMetadata]);
}

- (void)test_Radar_addUserTags {
    NSArray<NSString *> *initialTags = @[@"tag1", @"tag2"];
    [Radar addTags:initialTags];
    
    NSArray<NSString *> *newTags = @[@"tag3", @"tag4"];
    [Radar addTags:newTags];
    
    NSArray<NSString *> *expectedTags = @[@"tag1", @"tag2", @"tag3", @"tag4"];
    NSArray<NSString *> *actualTags = [Radar getTags];
    XCTAssertEqualObjects([expectedTags sortedArrayUsingSelector:@selector(compare:)], [actualTags sortedArrayUsingSelector:@selector(compare:)]);
}

- (void)test_Radar_addUserTags_duplicate {
    NSArray<NSString *> *initialTags = @[@"tag1", @"tag2"];
    [Radar addTags:initialTags];
    
    NSArray<NSString *> *newTags = @[@"tag2", @"tag3"]; // tag2 is duplicate
    [Radar addTags:newTags];
    
    NSArray<NSString *> *expectedTags = @[@"tag1", @"tag2", @"tag3"];
    NSArray<NSString *> *actualTags = [Radar getTags];
    XCTAssertEqualObjects([expectedTags sortedArrayUsingSelector:@selector(compare:)], [actualTags sortedArrayUsingSelector:@selector(compare:)]);
}

- (void)test_Radar_removeUserTags {
    NSArray<NSString *> *initialTags = @[@"tag1", @"tag2", @"tag3", @"tag4"];
    [Radar addTags:initialTags];
    
    NSArray<NSString *> *tagsToRemove = @[@"tag2", @"tag4"];
    [Radar removeTags:tagsToRemove];
    
    NSArray<NSString *> *expectedTags = @[@"tag1", @"tag3"];
    NSArray<NSString *> *actualTags = [Radar getTags];
    XCTAssertEqualObjects([expectedTags sortedArrayUsingSelector:@selector(compare:)], [actualTags sortedArrayUsingSelector:@selector(compare:)]);
}

- (void)test_Radar_removeUserTags_nonexistent {
    NSArray<NSString *> *initialTags = @[@"tag1", @"tag2"];
    [Radar addTags:initialTags];
    
    NSArray<NSString *> *tagsToRemove = @[@"tag3", @"tag4"]; // don't exist
    [Radar removeTags:tagsToRemove];
    
    NSArray<NSString *> *expectedTags = @[@"tag1", @"tag2"];
    NSArray<NSString *> *actualTags = [Radar getTags];
    XCTAssertEqualObjects([expectedTags sortedArrayUsingSelector:@selector(compare:)], [actualTags sortedArrayUsingSelector:@selector(compare:)]);
}

- (void)test_Radar_removeUserTags_all {
    NSArray<NSString *> *initialTags = @[@"tag1", @"tag2"];
    [Radar addTags:initialTags];
    
    NSArray<NSString *> *tagsToRemove = @[@"tag1", @"tag2"];
    [Radar removeTags:tagsToRemove];
    
    XCTAssertEqual([Radar getTags].count, 0);
}

- (void)test_Radar_setUserTags {
    NSArray<NSString *> *userTags = @[@"tag1", @"tag2", @"tag3"];
    [Radar setTags:userTags];
    NSArray<NSString *> *actualTags = [Radar getTags];
    XCTAssertEqualObjects([userTags sortedArrayUsingSelector:@selector(compare:)], [actualTags sortedArrayUsingSelector:@selector(compare:)]);
}

- (void)test_Radar_setUserTags_nil {
    // First add some tags
    NSArray<NSString *> *initialTags = @[@"tag1", @"tag2"];
    [Radar addTags:initialTags];
    
    // Then set to nil to clear all tags
    [Radar setTags:nil];
    XCTAssertEqual([Radar getTags].count, 0);
}

- (void)test_Radar_setUserTags_replaces_existing {
    // First add some tags
    NSArray<NSString *> *initialTags = @[@"tag1", @"tag2", @"tag3"];
    [Radar addTags:initialTags];
    
    // Then set completely different tags
    NSArray<NSString *> *newTags = @[@"newTag1", @"newTag2"];
    [Radar setTags:newTags];
    
    NSArray<NSString *> *actualTags = [Radar getTags];
    XCTAssertEqualObjects([newTags sortedArrayUsingSelector:@selector(compare:)], [actualTags sortedArrayUsingSelector:@selector(compare:)]);
    
    // Verify old tags are gone
    XCTAssertFalse([actualTags containsObject:@"tag1"]);
    XCTAssertFalse([actualTags containsObject:@"tag2"]);
    XCTAssertFalse([actualTags containsObject:@"tag3"]);
}

- (void)test_Radar_userTags_included_in_track_api {
    // Set up user tags
    
    NSArray<NSString *> *userTags = @[@"premium_user", @"beta_tester", @"location_enabled"];
    [Radar addTags:userTags];
    
    // Set up mock location and API response
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.locationManagerMock.mockLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(40.78382, -73.97536)
                                                                          altitude:-1
                                                                horizontalAccuracy:65
                                                                  verticalAccuracy:-1
                                                                         timestamp:[NSDate new]];
    self.apiHelperMock.mockStatus = RadarStatusSuccess;
    self.apiHelperMock.mockResponse = [RadarTestUtils jsonDictionaryFromResource:@"track"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"trackOnce with user tags"];

    [Radar trackOnceWithCompletionHandler:^(RadarStatus status, CLLocation *_Nullable location, NSArray<RadarEvent *> *_Nullable events, RadarUser *_Nullable user) {
        XCTAssertEqual(status, RadarStatusSuccess);
        
        // Verify that the API call was made with the correct parameters
        XCTAssertNotNil(self.apiHelperMock.lastParams);
        XCTAssertEqualObjects(self.apiHelperMock.lastMethod, @"POST");
        XCTAssertTrue([self.apiHelperMock.lastUrl containsString:@"/v1/track"]);
        
        // Verify that userTags are included in the API parameters
        NSArray<NSString *> *apiUserTags = self.apiHelperMock.lastParams[@"userTags"];
        XCTAssertNotNil(apiUserTags);
        XCTAssertEqual(apiUserTags.count, 3);
        
        // Verify the tags are present (order doesn't matter for this test)
        NSArray<NSString *> *sortedApiTags = [apiUserTags sortedArrayUsingSelector:@selector(compare:)];
        NSArray<NSString *> *sortedExpectedTags = [userTags sortedArrayUsingSelector:@selector(compare:)];
        XCTAssertEqualObjects(sortedApiTags, sortedExpectedTags);
        
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail();
                                     }
                                 }];
}

- (void)test_Radar_getLocation_errorPermissions {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusNotDetermined;
    self.locationManagerMock.mockLocation = nil;

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar getLocationWithCompletionHandler:^(RadarStatus status, CLLocation *_Nullable location, BOOL stopped) {
        XCTAssertEqual(status, RadarStatusErrorPermissions);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail();
                                     }
                                 }];
}

- (void)test_Radar_getLocation_errorLocation {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.locationManagerMock.mockLocation = nil;

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar getLocationWithCompletionHandler:^(RadarStatus status, CLLocation *_Nullable location, BOOL stopped) {
        XCTAssertEqual(status, RadarStatusErrorLocation);

        [expectation fulfill];
    }];
    
    // simulate a location timeout without waiting for 20 seconds
    [[RadarLocationManager sharedInstance] callCompletionHandlersWithStatus:RadarStatusErrorLocation location:nil];

    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail();
                                     }
                                 }];
}

- (void)test_Radar_getLocation_success {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.locationManagerMock.mockLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(40.78382, -73.97536)
                                                                          altitude:-1
                                                                horizontalAccuracy:65
                                                                  verticalAccuracy:-1
                                                                         timestamp:[NSDate new]];

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar getLocationWithCompletionHandler:^(RadarStatus status, CLLocation *_Nullable location, BOOL stopped) {
        XCTAssertEqual(status, RadarStatusSuccess);
        XCTAssertEqualObjects(self.locationManagerMock.mockLocation, location);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail();
                                     }
                                 }];
}

- (void)test_Radar_trackOnce_errorPermissions {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusNotDetermined;
    self.locationManagerMock.mockLocation = nil;

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar trackOnceWithCompletionHandler:^(RadarStatus status, CLLocation *_Nullable location, NSArray<RadarEvent *> *_Nullable events, RadarUser *_Nullable user) {
        XCTAssertEqual(status, RadarStatusErrorPermissions);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail();
                                     }
                                 }];
}

- (void)test_Radar_trackOnce_errorLocation {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.locationManagerMock.mockLocation = nil;

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar trackOnceWithCompletionHandler:^(RadarStatus status, CLLocation *_Nullable location, NSArray<RadarEvent *> *_Nullable events, RadarUser *_Nullable user) {
        XCTAssertEqual(status, RadarStatusErrorLocation);

        [expectation fulfill];
    }];
    
    // simulate a location timeout without waiting for 20 seconds
    [[RadarLocationManager sharedInstance] callCompletionHandlersWithStatus:RadarStatusErrorLocation location:nil];

    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail();
                                     }
                                 }];
}

- (void)test_Radar_trackOnce_success {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.locationManagerMock.mockLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(40.78382, -73.97536)
                                                                          altitude:-1
                                                                horizontalAccuracy:65
                                                                  verticalAccuracy:-1
                                                                         timestamp:[NSDate new]];
    self.apiHelperMock.mockStatus = RadarStatusSuccess;
    self.apiHelperMock.mockResponse = [RadarTestUtils jsonDictionaryFromResource:@"track"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar trackOnceWithCompletionHandler:^(RadarStatus status, CLLocation *_Nullable location, NSArray<RadarEvent *> *_Nullable events, RadarUser *_Nullable user) {
        XCTAssertEqual(status, RadarStatusSuccess);
        XCTAssertEqualObjects(self.locationManagerMock.mockLocation, location);
        AssertEventsOk(events);
        // first event has an altitude attached, check it's parsed properly
        XCTAssertNotEqual(events.firstObject.location.altitude, -1);
        XCTAssertEqual(events.lastObject.location.altitude, -1);
        AssertUserOk(user);
        XCTAssertNotEqual(user.location.altitude, -1);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail();
                                     }
                                 }];
}

- (void)test_Radar_trackOnce_location_success {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusNotDetermined;
    CLLocation *mockLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(40.78382, -73.97536)
                                                             altitude:-1
                                                   horizontalAccuracy:65
                                                     verticalAccuracy:-1
                                                            timestamp:[NSDate new]];
    self.apiHelperMock.mockStatus = RadarStatusSuccess;
    self.apiHelperMock.mockResponse = [RadarTestUtils jsonDictionaryFromResource:@"track"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar trackOnceWithLocation:mockLocation
               completionHandler:^(RadarStatus status, CLLocation *_Nullable location, NSArray<RadarEvent *> *_Nullable events, RadarUser *_Nullable user) {
                   XCTAssertEqual(status, RadarStatusSuccess);
                   AssertEventsOk(events);
                   AssertUserOk(user);

                   [expectation fulfill];
               }];

    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail();
                                     }
                                 }];
}

- (void)test_Radar_startTracking_errorPermissions {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusNotDetermined;
    self.locationManagerMock.mockLocation = nil;

    [Radar stopTracking];

    [Radar startTrackingWithOptions:RadarTrackingOptions.presetEfficient];
    XCTAssertFalse([Radar isTracking]);
}

- (void)test_Radar_startTracking_continuous {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;

    [Radar stopTracking];

    RadarTrackingOptions *options = RadarTrackingOptions.presetContinuous;
    [Radar startTrackingWithOptions:options];
    XCTAssertEqualObjects(options, [Radar getTrackingOptions]);
    XCTAssertTrue([Radar isTracking]);
}

- (void)test_Radar_startTracking_responsive {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;

    [Radar stopTracking];

    RadarTrackingOptions *options = RadarTrackingOptions.presetResponsive;
    [Radar startTrackingWithOptions:options];
    XCTAssertEqualObjects(options, [Radar getTrackingOptions]);
    XCTAssertTrue([Radar isTracking]);
}

- (void)test_Radar_startTracking_efficient {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;

    [Radar stopTracking];

    RadarTrackingOptions *options = RadarTrackingOptions.presetEfficient;
    [Radar startTrackingWithOptions:options];
    XCTAssertEqualObjects(options, [Radar getTrackingOptions]);
    XCTAssertTrue([Radar isTracking]);
}

- (void)test_Radar_startTracking_custom {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;

    [Radar stopTracking];

    RadarTrackingOptions *options = RadarTrackingOptions.presetEfficient;
    options.desiredAccuracy = RadarTrackingOptionsDesiredAccuracyLow;
    NSDate *now = [NSDate new];
    options.startTrackingAfter = now;
    options.stopTrackingAfter = [now dateByAddingTimeInterval:1000];
    options.syncLocations = RadarTrackingOptionsSyncNone;
    [Radar startTrackingWithOptions:options];
    XCTAssertEqualObjects(options, [Radar getTrackingOptions]);
    XCTAssertTrue([Radar isTracking]);
}

- (void)test_Radar_stopTracking {
    [Radar stopTracking];
    XCTAssertFalse([Radar isTracking]);
}

- (void)test_Radar_mockTracking {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusNotDetermined;
    self.apiHelperMock.mockStatus = RadarStatusSuccess;
    self.apiHelperMock.mockResponse = [RadarTestUtils jsonDictionaryFromResource:@"route_distance"];
    
    // purposefully fail the track call here so the mockTracking does not try to flush logs (almost instant to up to 10-20 seconds)
    // to skip this step of flush logs, we are returning an error on track so it calls the completion hander without log flushing
    // the happy path behaviour is tested in test_Radar_trackOnce
    // TODO: in the future, it would be good to have log buffer mocked, so we can just pretend to have flushed logs instead of taking the short path in the completion handler
    [self.apiHelperMock setMockStatus:RadarStatusErrorUnknown forMethod:@"https://api.radar.io/v1/track"];

    CLLocation *origin = [[CLLocation alloc] initWithLatitude:40.78382 longitude:-73.97536];
    CLLocation *destination = [[CLLocation alloc] initWithLatitude:40.70390 longitude:-73.98670];
    int steps = 20;
    __block int i = 0;
    __block int expired_count = 0;

    dispatch_queue_t timer = dispatch_queue_create("mockTrackingTimer", DISPATCH_QUEUE_SERIAL);
    int64_t expire_timeout = (int64_t)(10.0 * NSEC_PER_SEC);
    
    self.continueAfterFailure = false;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];
    [Radar mockTrackingWithOrigin:origin
                      destination:destination
                             mode:RadarRouteModeCar
                            steps:steps
                         interval:1
                completionHandler:^(RadarStatus status, CLLocation *_Nullable location, NSArray<RadarEvent *> *_Nullable events, RadarUser *_Nullable user) {
                    i++;
                    // make a log here so that it doesn't look like the test is failing, this test takes a total of at least 20 seconds, could be more based on intermediate step times
                    NSLog(@"test_Radar_mockTracking completed step %i", i);
                    if (i == steps - 1) { // last step, complete test
                        [expectation fulfill];
                    } else {
                        // set a timer for when the next completion hander must be completed, which will increment i and allow this callback to pass
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, expire_timeout), timer, ^{
                            expired_count++;
                            if (i < expired_count) {
                                XCTFail(@"Did not receive next mock tracking in time, tracked %i times", i);
                                
                            }
                        });
                    }
                }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, expire_timeout), timer, ^{
        expired_count++;
        if (i < expired_count) {
            XCTFail(@"Did not receive next mock tracking in time, tracked %i times", i);
        }
    });
    [self waitForExpectationsWithTimeout:(expire_timeout * 20)
                                 handler:^(NSError *_Nullable error) {
        if (error) {
         XCTFail();
        }
    }];
}

- (void)test_Radar_acceptEventId {
    self.apiHelperMock.mockStatus = RadarStatusSuccess;
    self.apiHelperMock.mockResponse = [RadarTestUtils jsonDictionaryFromResource:@"events_verification"];
    [Radar acceptEventId:@"eventId" verifiedPlaceId:nil];
}

- (void)test_Radar_acceptEventId_verifiedPlaceId {
    self.apiHelperMock.mockStatus = RadarStatusSuccess;
    self.apiHelperMock.mockResponse = [RadarTestUtils jsonDictionaryFromResource:@"events_verification"];
    [Radar acceptEventId:@"eventId" verifiedPlaceId:@"verifiedPlaceId"];
}

- (void)test_Radar_rejectEvent {
    self.apiHelperMock.mockStatus = RadarStatusSuccess;
    self.apiHelperMock.mockResponse = [RadarTestUtils jsonDictionaryFromResource:@"events_verification"];
    [Radar rejectEventId:@"eventId"];
}

- (void)test_Radar_logConversion {
    self.apiHelperMock.mockStatus = RadarStatusSuccess;
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.locationManagerMock.mockLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(40.78382, -73.97536)
                                                                          altitude:-1
                                                                horizontalAccuracy:65
                                                                  verticalAccuracy:-1
                                                                         timestamp:[NSDate new]];
    [self.apiHelperMock setMockResponse:[RadarTestUtils jsonDictionaryFromResource:@"track"] forMethod:@"https://api.radar.io/v1/track"];
    [self.apiHelperMock setMockResponse:[RadarTestUtils jsonDictionaryFromResource:@"conversion_event"] forMethod:@"https://api.radar.io/v1/events"];

    XCTestExpectation *exp = [self expectationWithDescription:@"logConversion"];

    [Radar logConversionWithName:@"conversion4"
        metadata:@{@"foo": @"bar"}
   completionHandler:^(RadarStatus status, RadarEvent *_Nullable event) {
        XCTAssertEqual(status, RadarStatusSuccess);
        XCTAssertNotNil(event);

        XCTAssertNotNil(event);
        NSDictionary *metadata = event.metadata;
        XCTAssertNotNil(metadata);
        XCTAssertTrue([metadata[@"foo"] isEqual:@"bar"]);
        [exp fulfill];
    }
    ];

    [self waitForExpectations:@[exp] timeout:10.0];
}

- (void)test_Radar_logConversion_revenue {
    self.apiHelperMock.mockStatus = RadarStatusSuccess;
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.locationManagerMock.mockLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(40.78382, -73.97536)
                                                                          altitude:-1
                                                                horizontalAccuracy:65
                                                                  verticalAccuracy:-1
                                                                         timestamp:[NSDate new]];
    [self.apiHelperMock setMockResponse:[RadarTestUtils jsonDictionaryFromResource:@"track"]
                               forMethod:@"https://api.radar.io/v1/track"];
    [self.apiHelperMock setMockResponse:[RadarTestUtils jsonDictionaryFromResource:@"conversion_event"]
                              forMethod:@"https://api.radar.io/v1/events"];

    XCTestExpectation *exp = [self expectationWithDescription:@"logConversion"];

    [Radar logConversionWithName:@"conversion4"
                         revenue:@0.2
                        metadata:@{@"foo": @"bar"}
   completionHandler:^(RadarStatus status, RadarEvent *_Nullable event) {
        XCTAssertEqual(status, RadarStatusSuccess);
        XCTAssertNotNil(event);

        XCTAssertNotNil(event);
        NSDictionary *metadata = event.metadata;
        XCTAssertNotNil(metadata);
        XCTAssertTrue([metadata[@"foo"] isEqual:@"bar"]);
        XCTAssertTrue([metadata[@"revenue"] isEqual:@0.2]);
        [exp fulfill];
    }
    ];

    [self waitForExpectations:@[exp] timeout:10.0];
}

- (void)test_Radar_logConversion_statusOkButEventIsNil_fails {
    self.apiHelperMock.mockStatus = RadarStatusSuccess;
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.locationManagerMock.mockLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(40.78382, -73.97536)
                                                                          altitude:-1
                                                                horizontalAccuracy:65
                                                                  verticalAccuracy:-1
                                                                         timestamp:[NSDate new]];
    [self.apiHelperMock setMockResponse:[RadarTestUtils jsonDictionaryFromResource:@"track"] forMethod:@"https://api.radar.io/v1/track"];
    [self.apiHelperMock setMockResponse:[RadarTestUtils jsonDictionaryFromResource:@"conversion_event_nil_event"] forMethod:@"https://api.radar.io/v1/events"];

    XCTestExpectation *exp = [self expectationWithDescription:@"logConversion"];

    [Radar logConversionWithName:@"conversion4"
        metadata:nil
   completionHandler:^(RadarStatus status, RadarEvent *_Nullable event) {
        XCTAssertEqual(status, RadarStatusErrorServer);
        XCTAssertNil(event);
        [exp fulfill];
    }
    ];

    [self waitForExpectations:@[exp] timeout:10.0];
}

- (void)test_Radar_startTrip {
    RadarTripOptions *options = [[RadarTripOptions alloc] initWithExternalId:@"tripExternalId"
                                                      destinationGeofenceTag:@"tripDestinationGeofenceTag"
                                               destinationGeofenceExternalId:@"tripDestinationExternalId"];
    options.metadata = @{@"foo": @"bar", @"baz": @YES, @"qux": @1};
    options.mode = RadarRouteModeFoot;
    [Radar startTripWithOptions:options];
    XCTAssertEqualObjects(options, [Radar getTripOptions]);
}

- (void)test_Radar_completeTrip {
    [Radar completeTrip];
    XCTAssertNil([Radar getTripOptions]);
}

- (void)test_Radar_cancelTrip {
    [Radar cancelTrip];
    XCTAssertNil([Radar getTripOptions]);
}

- (void)test_Radar_startTripWithTrackingOptionsWhenTrackingIsInProgress {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedAlways;

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [RadarSettings setPreviousTrackingOptions:nil];
    RadarTrackingOptions *originalTrackingOptions = RadarTrackingOptions.presetEfficient;
    [Radar startTrackingWithOptions:originalTrackingOptions];

    RadarTripOptions *tripOptions = [[RadarTripOptions alloc] initWithExternalId:@"testTrip" destinationGeofenceTag:@"someTag" destinationGeofenceExternalId:@"someId"];
    RadarTrackingOptions *tripTrackingOptions = RadarTrackingOptions.presetContinuous;
    [Radar startTripWithOptions:tripOptions
                trackingOptions:tripTrackingOptions
              completionHandler:^(RadarStatus status, RadarTrip *_Nullable trip, NSArray<RadarEvent *> *_Nullable events) {
                  RadarTrackingOptions *previousTrackingOptions = [RadarSettings previousTrackingOptions];
                  XCTAssertTrue([previousTrackingOptions isEqual:originalTrackingOptions]);
                  RadarTrackingOptions *currentTrackingOptions = [RadarSettings trackingOptions];
                  XCTAssertTrue([currentTrackingOptions isEqual:tripTrackingOptions]);
                  [expectation fulfill];
              }];

    [self waitForExpectations:@[expectation] timeout:10];

    [Radar completeTrip];
    XCTAssertNil([RadarSettings previousTrackingOptions]);
    XCTAssertTrue([[RadarSettings trackingOptions] isEqual:originalTrackingOptions]);
    XCTAssertTrue(Radar.isTracking);
}

- (void)test_Radar_startTripWithTrackingOptionsWhenTrackingIsNotInProgress {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedAlways;

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [RadarSettings setPreviousTrackingOptions:nil];
    [RadarSettings setTrackingOptions:nil];
    [RadarSettings setTracking:NO];

    RadarTripOptions *tripOptions = [[RadarTripOptions alloc] initWithExternalId:@"testTrip" destinationGeofenceTag:@"someTag" destinationGeofenceExternalId:@"someId"];
    RadarTrackingOptions *tripTrackingOptions = RadarTrackingOptions.presetContinuous;
    [Radar startTripWithOptions:tripOptions
                trackingOptions:tripTrackingOptions
              completionHandler:^(RadarStatus status, RadarTrip *_Nullable trip, NSArray<RadarEvent *> *_Nullable events) {
                  XCTAssertNil([RadarSettings previousTrackingOptions]);
                  RadarTrackingOptions *currentTrackingOptions = [RadarSettings trackingOptions];
                  XCTAssertTrue([currentTrackingOptions isEqual:tripTrackingOptions]);
                  [expectation fulfill];
              }];

    [self waitForExpectations:@[expectation] timeout:10];

    [Radar completeTrip];
    XCTAssertNil([RadarSettings previousTrackingOptions]);
    XCTAssertFalse(Radar.isTracking);
}

- (void)test_Radar_getContext_errorPermissions {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusNotDetermined;
    self.locationManagerMock.mockLocation = nil;

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar getContextWithCompletionHandler:^(RadarStatus status, CLLocation *_Nullable location, RadarContext *_Nullable context) {
        XCTAssertEqual(status, RadarStatusErrorPermissions);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail();
                                     }
                                 }];
}

- (void)test_Radar_getContext_errorLocation {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.locationManagerMock.mockLocation = nil;

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar getContextWithCompletionHandler:^(RadarStatus status, CLLocation *_Nullable location, RadarContext *_Nullable context) {
        XCTAssertEqual(status, RadarStatusErrorLocation);

        [expectation fulfill];
    }];

    // simulate a location timeout without waiting for 20 seconds
    [[RadarLocationManager sharedInstance] callCompletionHandlersWithStatus:RadarStatusErrorLocation location:nil];
    
    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail();
                                     }
                                 }];
}

- (void)test_Radar_getContext_success {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.locationManagerMock.mockLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(40.78382, -73.97536)
                                                                          altitude:-1
                                                                horizontalAccuracy:65
                                                                  verticalAccuracy:-1
                                                                         timestamp:[NSDate new]];
    self.apiHelperMock.mockStatus = RadarStatusSuccess;
    self.apiHelperMock.mockResponse = [RadarTestUtils jsonDictionaryFromResource:@"context"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar getContextWithCompletionHandler:^(RadarStatus status, CLLocation *_Nullable location, RadarContext *_Nullable context) {
        XCTAssertEqual(status, RadarStatusSuccess);
        XCTAssertEqualObjects(self.locationManagerMock.mockLocation, location);
        AssertContextOk(context);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:60
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail();
                                     }
                                 }];
}

- (void)test_Radar_getContext_location_success {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusNotDetermined;
    CLLocation *mockLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(40.78382, -73.97536)
                                                             altitude:-1
                                                   horizontalAccuracy:65
                                                     verticalAccuracy:-1
                                                            timestamp:[NSDate new]];
    self.apiHelperMock.mockStatus = RadarStatusSuccess;
    self.apiHelperMock.mockResponse = [RadarTestUtils jsonDictionaryFromResource:@"context"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar getContextForLocation:mockLocation
               completionHandler:^(RadarStatus status, CLLocation *_Nullable location, RadarContext *_Nullable context) {
                   XCTAssertEqual(status, RadarStatusSuccess);
                   AssertContextOk(context);

                   [expectation fulfill];
               }];

    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail();
                                     }
                                 }];
}

- (void)test_Radar_searchPlaces_errorPermissions {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusNotDetermined;
    self.locationManagerMock.mockLocation = nil;

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar searchPlacesWithRadius:1000
                           chains:@[@"walmart"]
                       categories:nil
                           groups:nil
                     countryCodes:nil
                            limit:100
                completionHandler:^(RadarStatus status, CLLocation *_Nullable location, NSArray<RadarPlace *> *_Nullable places) {
                    XCTAssertEqual(status, RadarStatusErrorPermissions);

                    [expectation fulfill];
                }];

    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail();
                                     }
                                 }];
}

- (void)test_Radar_searchPlaces_errorLocation {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.locationManagerMock.mockLocation = nil;

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar searchPlacesWithRadius:1000
                           chains:@[@"walmart"]
                       categories:nil
                           groups:nil
                     countryCodes:nil
                            limit:100
                completionHandler:^(RadarStatus status, CLLocation *_Nullable location, NSArray<RadarPlace *> *_Nullable places) {
                    XCTAssertEqual(status, RadarStatusErrorLocation);

                    [expectation fulfill];
                }];
    
    // simulate a location timeout without waiting for 20 seconds
    [[RadarLocationManager sharedInstance] callCompletionHandlersWithStatus:RadarStatusErrorLocation location:nil];
    
    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail();
                                     }
                                 }];
}

- (void)test_Radar_searchPlaces_chains_success {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.locationManagerMock.mockLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(40.78382, -73.97536)
                                                                          altitude:-1
                                                                horizontalAccuracy:65
                                                                  verticalAccuracy:-1
                                                                         timestamp:[NSDate new]];
    self.apiHelperMock.mockStatus = RadarStatusSuccess;
    self.apiHelperMock.mockResponse = [RadarTestUtils jsonDictionaryFromResource:@"search_places"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar searchPlacesWithRadius:1000
                           chains:@[@"walmart"]
                       categories:nil
                           groups:nil
                     countryCodes:nil
                            limit:100
                completionHandler:^(RadarStatus status, CLLocation *_Nullable location, NSArray<RadarPlace *> *_Nullable places) {
                    XCTAssertEqual(status, RadarStatusSuccess);
                    XCTAssertNotNil(location);
                    AssertPlacesOk(places);

                    [expectation fulfill];
                }];

    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail();
                                     }
                                 }];
}

- (void)test_Radar_searchPlaces_chainsAndMetadata_success {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.locationManagerMock.mockLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(40.78382, -73.97536)
                                                                          altitude:-1
                                                                horizontalAccuracy:65
                                                                  verticalAccuracy:-1
                                                                         timestamp:[NSDate new]];
    self.apiHelperMock.mockStatus = RadarStatusSuccess;
    self.apiHelperMock.mockResponse = [RadarTestUtils jsonDictionaryFromResource:@"search_places_chain_metadata"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar searchPlacesWithRadius:1000
                           chains:@[@"walmart"]
                    chainMetadata:@{@"orderActive": @"true"}
                       categories:nil
                           groups:nil
                     countryCodes:nil
                            limit:100
                completionHandler:^(RadarStatus status, CLLocation *_Nullable location, NSArray<RadarPlace *> *_Nullable places) {
                    XCTAssertEqual(status, RadarStatusSuccess);
                    XCTAssertNotNil(location);
                    XCTAssertNotNil(places);
                    XCTAssertEqual(places.count, 2);
                    NSDictionary<NSString *, NSString *> *firstPlaceMetadata = places[0].chain.metadata;
                    XCTAssertTrue([firstPlaceMetadata[@"orderActive"] isEqualToString:@"true"]);

                    [expectation fulfill];
                }];

    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail();
                                     }
                                 }];
}

- (void)test_Radar_searchPlacesNear_categories_success {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusNotDetermined;
    CLLocation *mockLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(40.78382, -73.97536)
                                                             altitude:-1
                                                   horizontalAccuracy:65
                                                     verticalAccuracy:-1
                                                            timestamp:[NSDate new]];
    self.apiHelperMock.mockStatus = RadarStatusSuccess;
    self.apiHelperMock.mockResponse = [RadarTestUtils jsonDictionaryFromResource:@"search_places"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar searchPlacesNear:mockLocation
                     radius:1000
                     chains:nil
                 categories:@[@"restaurant"]
                     groups:nil
               countryCodes:nil
                      limit:100
          completionHandler:^(RadarStatus status, CLLocation *_Nullable location, NSArray<RadarPlace *> *_Nullable places) {
              XCTAssertEqual(status, RadarStatusSuccess);
              XCTAssertNotNil(location);
              AssertPlacesOk(places);

              [expectation fulfill];
          }];

    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail();
                                     }
                                 }];
}

- (void)test_Radar_searchGeofences_errorPermissions {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusNotDetermined;
    self.locationManagerMock.mockLocation = nil;

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar searchGeofencesNear:nil
                        radius:1000
                          tags:nil
                      metadata:nil
                         limit:100
               includeGeometry:false
             completionHandler:^(RadarStatus status, CLLocation *_Nullable location, NSArray<RadarGeofence *> *_Nullable geofences) {
                       XCTAssertEqual(status, RadarStatusErrorPermissions);

                       [expectation fulfill];
                   }];

    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail();
                                     }
                                 }];
}

- (void)test_Radar_searchGeofences_errorLocation {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.locationManagerMock.mockLocation = nil;

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar searchGeofencesNear:nil
                        radius:1000
                          tags:nil
                      metadata:nil
                         limit:100
               includeGeometry:false
             completionHandler:^(RadarStatus status, CLLocation *_Nullable location, NSArray<RadarGeofence *> *_Nullable geofences) {
                       XCTAssertEqual(status, RadarStatusErrorLocation);

                       [expectation fulfill];
                   }];
    
    // simulate a location timeout without waiting for 20 seconds
    [[RadarLocationManager sharedInstance] callCompletionHandlersWithStatus:RadarStatusErrorLocation location:nil];
    
    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail();
                                     }
                                 }];
}

- (void)test_Radar_searchGeofences_success {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.locationManagerMock.mockLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(40.78382, -73.97536)
                                                                          altitude:-1
                                                                horizontalAccuracy:65
                                                                  verticalAccuracy:-1
                                                                         timestamp:[NSDate new]];
    self.apiHelperMock.mockStatus = RadarStatusSuccess;
    self.apiHelperMock.mockResponse = [RadarTestUtils jsonDictionaryFromResource:@"search_geofences"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar searchGeofences:^(RadarStatus status, CLLocation *_Nullable location, NSArray<RadarGeofence *> *_Nullable geofences) {
                       XCTAssertEqual(status, RadarStatusSuccess);
                       XCTAssertNotNil(location);
                       AssertGeofencesOk(geofences);

                       RadarGeofence *geofence = geofences[0];
                       NSDictionary *geofenceDict = [geofence dictionaryValue];
                       XCTAssertNotNil(geofenceDict[@"geometryCenter"]);
                       XCTAssertNotNil(geofenceDict[@"geometryRadius"]);
                       XCTAssertNotNil(geofenceDict[@"operatingHours"]);
        

                       [expectation fulfill];
                   }];

    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail();
                                     }
                                 }];
}

- (void)test_Radar_autocomplete_success {
    self.apiHelperMock.mockStatus = RadarStatusSuccess;
    self.apiHelperMock.mockResponse = [RadarTestUtils jsonDictionaryFromResource:@"search_autocomplete"];

    CLLocation *near = [[CLLocation alloc] initWithLatitude:40.78382 longitude:-73.97536];

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar autocompleteQuery:@"brooklyn roasting"
                        near:near
                      layers:@[@"place"]
                       limit:10
                     country:@"US"
           completionHandler:^(RadarStatus status, NSArray<RadarAddress *> *_Nullable addresses) {
               XCTAssertEqual(status, RadarStatusSuccess);
               AssertAddressesOk(addresses);

               [expectation fulfill];
           }];

    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail();
                                     }
                                 }];
}

- (void)test_Radar_geocode_error {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.apiHelperMock.mockStatus = RadarStatusErrorServer;

    NSString *geocodeQuery = @"20 jay street brooklyn";

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar geocodeAddress:geocodeQuery
        completionHandler:^(RadarStatus status, NSArray<RadarAddress *> *_Nullable addresses) {
            XCTAssertEqual(status, RadarStatusErrorServer);
            XCTAssertNil(addresses);

            [expectation fulfill];
        }];

    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail();
                                     }
                                 }];
}

- (void)test_Radar_geocode_success {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.apiHelperMock.mockStatus = RadarStatusSuccess;
    self.apiHelperMock.mockResponse = [RadarTestUtils jsonDictionaryFromResource:@"geocode"];

    NSString *query = @"20 jay st brooklyn";

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar geocodeAddress:query
        completionHandler:^(RadarStatus status, NSArray<RadarAddress *> *_Nullable addresses) {
            XCTAssertEqual(status, RadarStatusSuccess);
            AssertAddressesOk(addresses);

            [expectation fulfill];
        }];

    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail();
                                     }
                                 }];
}

- (void)test_Radar_reverseGeocode_errorPermissions {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusNotDetermined;
    self.locationManagerMock.mockLocation = nil;

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar reverseGeocodeWithCompletionHandler:^(RadarStatus status, NSArray<RadarAddress *> *_Nullable addresses) {
        XCTAssertEqual(status, RadarStatusErrorPermissions);
        XCTAssertNil(addresses);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail();
                                     }
                                 }];
}

- (void)test_Radar_reverseGeocode_errorLocation {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.locationManagerMock.mockLocation = nil;

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar reverseGeocodeWithCompletionHandler:^(RadarStatus status, NSArray<RadarAddress *> *_Nullable addresses) {
        XCTAssertEqual(status, RadarStatusErrorLocation);
        XCTAssertNil(addresses);

        [expectation fulfill];
    }];
    
    // simulate a location timeout without waiting for 20 seconds
    [[RadarLocationManager sharedInstance] callCompletionHandlersWithStatus:RadarStatusErrorLocation location:nil];

    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail();
                                     }
                                 }];
}

- (void)test_Radar_reverseGeocode_success {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.locationManagerMock.mockLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(40.78382, -73.97536)
                                                                          altitude:-1
                                                                horizontalAccuracy:65
                                                                  verticalAccuracy:-1
                                                                         timestamp:[NSDate new]];
    self.apiHelperMock.mockStatus = RadarStatusSuccess;
    self.apiHelperMock.mockResponse = [RadarTestUtils jsonDictionaryFromResource:@"geocode"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar reverseGeocodeWithCompletionHandler:^(RadarStatus status, NSArray<RadarAddress *> *_Nullable addresses) {
        XCTAssertEqual(status, RadarStatusSuccess);
        AssertAddressesOk(addresses);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail();
                                     }
                                 }];
}

- (void)test_Radar_reverseGeocodeLocation_error {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.apiHelperMock.mockStatus = RadarStatusErrorServer;

    CLLocation *location = [[CLLocation alloc] initWithLatitude:40.78382 longitude:-73.97536];

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar reverseGeocodeLocation:location
                completionHandler:^(RadarStatus status, NSArray<RadarAddress *> *_Nullable addresses) {
                    XCTAssertEqual(status, RadarStatusErrorServer);
                    XCTAssertNil(addresses);

                    [expectation fulfill];
                }];

    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail();
                                     }
                                 }];
}

- (void)test_Radar_reverseGeocodeLocation_success {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.apiHelperMock.mockStatus = RadarStatusSuccess;
    self.apiHelperMock.mockResponse = [RadarTestUtils jsonDictionaryFromResource:@"geocode"];

    CLLocation *location = [[CLLocation alloc] initWithLatitude:40.78382 longitude:-73.97536];

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar reverseGeocodeLocation:location
                completionHandler:^(RadarStatus status, NSArray<RadarAddress *> *_Nullable addresses) {
                    XCTAssertEqual(status, RadarStatusSuccess);
                    AssertAddressesOk(addresses);

                    [expectation fulfill];
                }];

    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail();
                                     }
                                 }];
}

- (void)test_Radar_ipGeocode_error {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.apiHelperMock.mockStatus = RadarStatusErrorServer;

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar ipGeocodeWithCompletionHandler:^(RadarStatus status, RadarAddress *_Nullable address, BOOL proxy) {
        XCTAssertEqual(status, RadarStatusErrorServer);
        XCTAssertNil(address);
        XCTAssertFalse(proxy);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail();
                                     }
                                 }];
}

- (void)test_Radar_ipGeocode_success {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.apiHelperMock.mockStatus = RadarStatusSuccess;
    self.apiHelperMock.mockResponse = [RadarTestUtils jsonDictionaryFromResource:@"geocode_ip"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar ipGeocodeWithCompletionHandler:^(RadarStatus status, RadarAddress *_Nullable address, BOOL proxy) {
        XCTAssertEqual(status, RadarStatusSuccess);
        AssertAddressOk(address);
        XCTAssertNotNil(address.dma);
        XCTAssertNotNil(address.dmaCode);
        XCTAssertTrue(proxy);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail();
                                     }
                                 }];
}

- (void)test_Radar_getDistance_success {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.locationManagerMock.mockLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(40.78382, -73.97536)
                                                                          altitude:-1
                                                                horizontalAccuracy:65
                                                                  verticalAccuracy:-1
                                                                         timestamp:[NSDate new]];
    self.apiHelperMock.mockStatus = RadarStatusSuccess;
    self.apiHelperMock.mockResponse = [RadarTestUtils jsonDictionaryFromResource:@"route_distance"];

    CLLocation *destination = [[CLLocation alloc] initWithLatitude:40.78382 longitude:-73.97536];

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar getDistanceToDestination:destination
                              modes:RadarRouteModeFoot | RadarRouteModeCar
                              units:RadarRouteUnitsImperial
                  completionHandler:^(RadarStatus status, RadarRoutes *_Nullable routes) {
                      XCTAssertEqual(status, RadarStatusSuccess);
                      AssertRoutesOk(routes);

                      [expectation fulfill];
                  }];

    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail();
                                     }
                                 }];
}

- (void)test_RadarTrackingOptions_isEqual {
    RadarTrackingOptions *options = RadarTrackingOptions.presetEfficient;
    XCTAssertNotEqualObjects(options, nil);
    XCTAssertEqualObjects(options, options);
    XCTAssertNotEqualObjects(options, @"foo");
}

- (void)test_RadarFileStorage_writeAndRead {
    NSData *originalData = [@"Test data" dataUsingEncoding:NSUTF8StringEncoding];
    [self.fileSystem writeData:originalData toFileAtPath:self.testFilePath];
    NSData *originalData2 = [@"Newer Test data" dataUsingEncoding:NSUTF8StringEncoding];
    [self.fileSystem writeData:originalData2 toFileAtPath:self.testFilePath];
    NSData *readData = [self.fileSystem readFileAtPath:self.testFilePath];
    XCTAssertEqualObjects(originalData2, readData, @"Data read from file should be equal to original data");
}

- (void)test_RadarFileStorage_allFilesInDirectory {
    NSString *testDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"newDir"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:testDir isDirectory:nil]) {
        [[NSFileManager defaultManager] removeItemAtPath:testDir error:nil];
    }
    [[NSFileManager defaultManager] createDirectoryAtPath:testDir withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSArray<NSString *> *files = [self.fileSystem sortedFilesInDirectory: testDir];
    XCTAssertEqual(files.count, 0);
    NSData *originalData = [@"Test data" dataUsingEncoding:NSUTF8StringEncoding];
    [self.fileSystem writeData:originalData toFileAtPath: [testDir stringByAppendingPathComponent: @"file1"]];
    [self.fileSystem writeData:originalData toFileAtPath: [testDir stringByAppendingPathComponent: @"file2"]];
    NSArray<NSString *> *newFiles = [self.fileSystem sortedFilesInDirectory: testDir];
    XCTAssertEqual(newFiles.count, 2);
    
}

- (void)test_RadarFileStorage_deleteFile {
    NSData *originalData = [@"Test data" dataUsingEncoding:NSUTF8StringEncoding];
    [self.fileSystem writeData:originalData toFileAtPath:self.testFilePath];
    [self.fileSystem deleteFileAtPath:self.testFilePath];
    NSData *readData = [self.fileSystem readFileAtPath:self.testFilePath];
    XCTAssertNil(readData, @"Data read from file should be nil after file is deleted");
}

- (void)test_RadarLogBuffer_writeAndFlushableLogs {
    [[RadarLogBuffer sharedInstance]write:RadarLogLevelDebug type:RadarLogTypeNone message:@"Test message 1"];
    [[RadarLogBuffer sharedInstance]write:RadarLogLevelDebug type:RadarLogTypeNone message:@"Test message 2"]; 
    [[RadarLogBuffer sharedInstance]persistLogs];
    NSArray<RadarLog *> *logs = [[RadarLogBuffer sharedInstance]flushableLogs];
    XCTAssertEqual(logs.count, 2);
    XCTAssertEqualObjects(logs.firstObject.message, @"Test message 1");
    XCTAssertEqualObjects(logs.lastObject.message, @"Test message 2");
    [[RadarLogBuffer sharedInstance]write:RadarLogLevelDebug type:RadarLogTypeNone message:@"Test message 3"];
    NSArray<RadarLog *> *newLogs = [[RadarLogBuffer sharedInstance]flushableLogs];
    XCTAssertEqual(newLogs.count, 1);
    XCTAssertEqualObjects(newLogs.firstObject.message, @"Test message 3");
}

- (void)test_RadarLogBuffer_flush {
    [[RadarLogBuffer sharedInstance]write:RadarLogLevelDebug type:RadarLogTypeNone message:@"Test message 1"];
    [[RadarLogBuffer sharedInstance]write:RadarLogLevelDebug type:RadarLogTypeNone message:@"Test message 2"];
    [[RadarLogBuffer sharedInstance]persistLogs];
    NSArray<RadarLog *> *logs = [[RadarLogBuffer sharedInstance]flushableLogs];
    [[RadarLogBuffer sharedInstance] onFlush:NO logs:logs];
    logs = [[RadarLogBuffer sharedInstance]flushableLogs];
    XCTAssertEqual(logs.count, 2);
    [[RadarLogBuffer sharedInstance] onFlush:YES logs:logs];
    logs = [[RadarLogBuffer sharedInstance]flushableLogs];
    XCTAssertEqual(logs.count, 0);
}

- (void)test_RadarLogBuffer_append {
    [[RadarLogBuffer sharedInstance]write:RadarLogLevelDebug type:RadarLogTypeNone message:@"Test message 1" forcePersist:YES];
    [[RadarLogBuffer sharedInstance]write:RadarLogLevelDebug type:RadarLogTypeNone message:@"Test message 2" forcePersist:YES];
    NSArray<RadarLog *> *logs = [[RadarLogBuffer sharedInstance]flushableLogs];
    XCTAssertEqual(logs.count, 2);
    XCTAssertEqualObjects(logs.firstObject.message, @"Test message 1");
    XCTAssertEqualObjects(logs.lastObject.message, @"Test message 2");
}

- (void)test_RadarLogBuffer_purge {
    [[RadarLogBuffer sharedInstance]clearBuffer];
    for (NSUInteger i = 0; i < 600; i++) {
        [[RadarLogBuffer sharedInstance]write:RadarLogLevelDebug type:RadarLogTypeNone message:[NSString stringWithFormat:@"message_%d", i]];
    }
    NSArray<RadarLog *> *logs = [[RadarLogBuffer sharedInstance]flushableLogs];
    XCTAssertEqual(logs.count, 351);
    XCTAssertEqualObjects(logs.firstObject.message, @"message_250");
    XCTAssertEqualObjects(logs.lastObject.message, @"----- purged oldest logs -----");
    [[RadarLogBuffer sharedInstance]clearBuffer];
}

- (void)test_RadarReplayBuffer_writeAndRead {
    RadarSdkConfiguration *sdkConfiguration = [[RadarSdkConfiguration alloc] initWithDict:@{
        @"logLevel": @"warning",
        @"startTrackingOnInitialize": @(NO),
        @"trackOnceOnAppOpen": @(NO),
        @"usePersistence": @(YES),
        @"extendFlushReplays": @(NO),
        @"useLogPersistence": @(NO),
        @"useRadarModifiedBeacon": @(NO),
        @"syncAfterSetUser": @(NO)
    }];
    [RadarSettings setSdkConfiguration:sdkConfiguration];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:0.1 longitude:0.1];
    NSMutableDictionary * params = [RadarTestUtils createTrackParamWithLocation:location stopped:YES foreground:YES source:RadarLocationSourceGeofenceEnter replayed:YES beacons:[NSArray arrayWithObject:[RadarBeacon alloc]] verified:YES attestationString:@"attestationString" keyId:@"keyID" attestationError:@"attestationError" encrypted:YES expectedCountryCode:@"CountryCode" expectedStateCode:@"StateCode"];
    
    [[RadarReplayBuffer sharedInstance] writeNewReplayToBuffer:params];
    [[RadarReplayBuffer sharedInstance] setValue:NULL forKey:@"mutableReplayBuffer"];
    [[RadarReplayBuffer sharedInstance] loadReplaysFromPersistentStore];
    NSMutableArray<RadarReplay *> *mutableReplayBuffer = [[RadarReplayBuffer sharedInstance] valueForKey:@"mutableReplayBuffer"];
    XCTAssertEqual(mutableReplayBuffer.count, 1);
    XCTAssertEqualObjects(mutableReplayBuffer.firstObject.replayParams, params);
}

- (void)test_RadarSdkConfiguration {
    RadarSdkConfiguration *sdkConfiguration = [[RadarSdkConfiguration alloc] initWithDict:@{
        @"logLevel": @"warning",
        @"startTrackingOnInitialize": @(YES),
        @"trackOnceOnAppOpen": @(YES),
        @"usePersistence": @(NO),
        @"extendFlushReplays": @(NO),
        @"useLogPersistence": @(NO),
        @"useRadarModifiedBeacon": @(NO),
        @"syncAfterSetUser": @(NO)
    }];

    [RadarSettings setSdkConfiguration:sdkConfiguration];
    XCTAssertEqual([RadarSettings logLevel], RadarLogLevelWarning);

    self.apiHelperMock.mockStatus = RadarStatusSuccess;
    self.apiHelperMock.mockResponse = [RadarTestUtils jsonDictionaryFromResource:@"get_config_response"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [[RadarAPIClient sharedInstance] getConfigForUsage:@"sdkConfigUpdate" 
                                              verified:false
                                     completionHandler:^(RadarStatus status, RadarConfig *config) {
        if (status != RadarStatusSuccess || !config) {
        return;
        }
        [RadarSettings setSdkConfiguration:config.meta.sdkConfiguration];

        XCTAssertEqual(config.meta.sdkConfiguration.logLevel, RadarLogLevelInfo);
        XCTAssertEqual([RadarSettings logLevel], RadarLogLevelInfo);
        
        XCTAssertEqual(config.meta.sdkConfiguration.trackOnceOnAppOpen, YES);
        XCTAssertEqual(config.meta.sdkConfiguration.startTrackingOnInitialize, YES);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail();
                                     }
                                 }];
    
    [Radar setLogLevel:RadarLogLevelDebug];
    NSDictionary *clientSdkConfigurationDict = [RadarSettings clientSdkConfiguration];
    XCTAssertEqual([RadarLog levelFromString:(NSString *)clientSdkConfigurationDict[@"logLevel"]], RadarLogLevelDebug);
    
    RadarSdkConfiguration *savedSdkConfiguration = [RadarSettings sdkConfiguration];
    XCTAssertEqual(savedSdkConfiguration.trackOnceOnAppOpen, YES);
    XCTAssertEqual(savedSdkConfiguration.startTrackingOnInitialize, YES);
}

#pragma mark - EfficientTrackManager Tests

// Test coordinates (Central Park, NYC area)
static double const kTestLatitude = 40.78382;
static double const kTestLongitude = -73.97536;
// ~50m north
static double const kTestLatitudeNearby = 40.78427;
// ~120m north
static double kTestLatitudeMid = 40.78490;
// ~200m north
static double const kTestLatitudeFar = 40.78562;
// ~400m north
static double kTestLatitudeVeryFar = 40.78742;

- (void)test_EfficientTrack_shouldTrack_noSyncedRegion {
    [self clearEfficientTrackingState];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:kTestLatitude longitude:kTestLongitude];
    RadarTrackingOptions *options = [RadarTrackingOptions new];
    options.syncOnBeaconEvents = YES;
    
    // No synced region means we should always track
    BOOL shouldTrack = [RadarEfficientTrackManager shouldTrackWithLocation:location options:options];
    XCTAssertTrue(shouldTrack);
}

- (void)test_EfficientTrack_shouldTrack_outsideSyncedRegion {
    [self clearEfficientTrackingState];
    
    // Set synced region at base location with 100m radius
    CLCircularRegion *syncedRegion = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(kTestLatitude, kTestLongitude) radius:100 identifier:@"synced"];
    
    [RadarState setSyncedRegion:syncedRegion];
    
    // User is 200m away (outside synced region)
    CLLocation *location = [[CLLocation alloc] initWithLatitude:kTestLatitudeFar longitude:kTestLongitude];
    RadarTrackingOptions *options = [RadarTrackingOptions new];
    options.syncOnGeofenceEvents = YES;
    
    BOOL shouldTrack = [RadarEfficientTrackManager shouldTrackWithLocation:location options:options];
    XCTAssertTrue(shouldTrack);
}

- (void)test_EfficientTrack_shouldTrack_geofenceEntry {
    [self clearEfficientTrackingState];
    
    CLCircularRegion *syncedRegion = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(kTestLatitude, kTestLongitude) radius:500 identifier:@"synced"];
    [RadarState setSyncedRegion:syncedRegion];
    
    RadarGeofence *geofence = [self createTestGeofenceWithId:@"geofence1" latitude:kTestLatitude longitude:kTestLongitude radius:100];
    [RadarState setNearbyGeofences:@[geofence]];
    
    [RadarState setGeofenceIds:@[]];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:kTestLatitude longitude:kTestLongitude];
    RadarTrackingOptions *options = [RadarTrackingOptions new];
    options.syncOnGeofenceEvents = YES;
    
    BOOL shouldTrack = [RadarEfficientTrackManager shouldTrackWithLocation:location options:options];
    XCTAssertTrue(shouldTrack);
}

- (void)test_EfficientTrack_shouldTrack_geofenceExit {
    [self clearEfficientTrackingState];
    
    CLCircularRegion *syncedRegion = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(kTestLatitude, kTestLongitude) radius:500 identifier:@"synced"];
    
    [RadarState setSyncedRegion:syncedRegion];
    
    RadarGeofence *geofence = [self createTestGeofenceWithId:@"geofence1" latitude:kTestLatitudeFar longitude:kTestLongitude radius:50];
    [RadarState setNearbyGeofences:@[geofence]];
    
    [RadarState setGeofenceIds:@[@"geofence1"]];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:kTestLatitude longitude:kTestLongitude];
    RadarTrackingOptions *options = [RadarTrackingOptions new];
    
    options.syncOnGeofenceEvents = YES;
    
    BOOL shouldTrack = [RadarEfficientTrackManager shouldTrackWithLocation:location options:options];
    XCTAssertTrue(shouldTrack);
}

- (void)test_EfficientTrack_shouldNotTrack_noStateChange {
    [self clearEfficientTrackingState];
    
    CLCircularRegion *syncedRegion = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(kTestLatitude, kTestLongitude) radius:500 identifier:@"synced"];
    
    [RadarState setSyncedRegion:syncedRegion];
    
    RadarGeofence *geofence = [self createTestGeofenceWithId:@"geofence1" latitude:kTestLatitude longitude:kTestLongitude radius:100];
    [RadarState setNearbyGeofences:@[geofence]];
    
    [RadarState setGeofenceIds:@[@"geofence1"]];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:kTestLatitude longitude:kTestLongitude];
    RadarTrackingOptions *options = [RadarTrackingOptions new];
    options.syncOnGeofenceEvents = YES;
    
    BOOL shouldTrack = [RadarEfficientTrackManager shouldTrackWithLocation:location options:options];
    XCTAssertFalse(shouldTrack);
}

- (void)test_EfficientTrack_shouldNotTrack_flagDisabled {
    [self clearEfficientTrackingState];
    
    CLCircularRegion *syncedRegion = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(kTestLatitude, kTestLongitude) radius:500 identifier:@"synced"];
    
    [RadarState setSyncedRegion:syncedRegion];
    
    RadarGeofence *geofence = [self createTestGeofenceWithId:@"geofence1" latitude:kTestLatitude longitude:kTestLongitude radius:100];
    [RadarState setNearbyGeofences:@[geofence]];
    [RadarState setGeofenceIds:@[]];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:kTestLatitude longitude:kTestLongitude];
    RadarTrackingOptions *options = [RadarTrackingOptions new];
    options.syncOnGeofenceEvents = NO;
    options.syncOnPlaceEvents = NO;
    options.syncOnBeaconEvents = NO;
    
    BOOL shouldTrack = [RadarEfficientTrackManager shouldTrackWithLocation:location options:options];
    XCTAssertFalse(shouldTrack);
}

- (void)test_EfficientTrack_getGeofences_insideCircle {
    [self clearEfficientTrackingState];
    
    RadarGeofence *geofence = [self createTestGeofenceWithId:@"geofence1" latitude:kTestLatitude longitude:kTestLongitude radius:100];
    [RadarState setNearbyGeofences:@[geofence]];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:kTestLatitude longitude:kTestLongitude];
    
    NSArray<RadarGeofence *> *geofences = [RadarEfficientTrackManager getGeofencesFor:location];
    XCTAssertEqual(geofences.count, 1);
    XCTAssertEqualObjects(geofences.firstObject._id, @"geofence1");
}

- (void)test_EfficientTrack_getGeofences_outsideCircle {
    [self clearEfficientTrackingState];
    
    RadarGeofence *geofence = [self createTestGeofenceWithId:@"geofence1" latitude:kTestLatitudeFar longitude:kTestLongitude radius:50];
    [RadarState setNearbyGeofences:@[geofence]];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:kTestLatitude longitude:kTestLongitude];

    NSArray<RadarGeofence *> *geofences = [RadarEfficientTrackManager getGeofencesFor:location];
    XCTAssertEqual(geofences.count, 0);
}

- (void)test_EfficientTrack_getGeofences_noNearbyGeofences {
    [self clearEfficientTrackingState];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:kTestLatitude longitude:kTestLongitude];

    NSArray<RadarGeofence *> *geofences = [RadarEfficientTrackManager getGeofencesFor:location];
    XCTAssertEqual(geofences.count, 0);
}

- (void)test_EfficientTrack_geofenceStateChanged_entry {
    [self clearEfficientTrackingState];
    
    RadarGeofence *geofence = [self createTestGeofenceWithId:@"geofence1" latitude:kTestLatitude longitude:kTestLongitude radius:100];
    [RadarState setNearbyGeofences:@[geofence]];
    [RadarState setGeofenceIds:@[]];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:kTestLatitude longitude:kTestLongitude];
    
    BOOL changed = [RadarEfficientTrackManager hasGeofenceStateChangedWithLocation:location];
    XCTAssertTrue(changed);
}

- (void)test_EfficientTrack_geofenceStateChanged_exit {
    [self clearEfficientTrackingState];
    
    RadarGeofence *geofence = [self createTestGeofenceWithId:@"geofence1" latitude:kTestLatitudeFar longitude:kTestLongitude radius:50];
    [RadarState setNearbyGeofences:@[geofence]];
    [RadarState setGeofenceIds:@[@"geofence1"]];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:kTestLatitude longitude:kTestLongitude];
    
    BOOL changed = [RadarEfficientTrackManager hasGeofenceStateChangedWithLocation:location];
    XCTAssertTrue(changed);
}

- (void)test_EfficientTrack_geofenceStateChanged_noChange {
    [self clearEfficientTrackingState];
    
    RadarGeofence *geofence = [self createTestGeofenceWithId:@"geofence1" latitude:kTestLatitude longitude:kTestLongitude radius:100];
    [RadarState setNearbyGeofences:@[geofence]];
    [RadarState setGeofenceIds:@[@"geofence1"]];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:kTestLatitude longitude:kTestLongitude];
    
    BOOL changed = [RadarEfficientTrackManager hasGeofenceStateChangedWithLocation:location];
    XCTAssertFalse(changed);
}

- (void)test_EfficientTrack_getBeacons_withinRange {
    [self clearEfficientTrackingState];
    
    RadarBeacon *beacon = [self createTestBeaconWithId:@"beacon1" latitude:kTestLatitude longitude:kTestLongitude];
    [RadarState setNearbyBeacons:@[beacon]];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:kTestLatitude longitude:kTestLongitude];

    NSArray<RadarBeacon *> *beacons = [RadarEfficientTrackManager getBeaconsFor:location];
    XCTAssertEqual(beacons.count, 1);
    XCTAssertEqualObjects(beacons.firstObject._id, @"beacon1");
}

- (void)test_EfficientTrack_getBeacons_outsideRange {
    [self clearEfficientTrackingState];
    
    RadarBeacon *beacon = [self createTestBeaconWithId:@"beacon1" latitude:kTestLatitudeFar longitude:kTestLongitude];
    [RadarState setNearbyBeacons:@[beacon]];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:kTestLatitude longitude:kTestLongitude];

    NSArray<RadarBeacon *> *beacons = [RadarEfficientTrackManager getBeaconsFor:location];
    XCTAssertEqual(beacons.count, 0);
}

- (void)test_EfficientTrack_beaconStateChanged_entry {
    [self clearEfficientTrackingState];
    
    RadarBeacon *beacon = [self createTestBeaconWithId:@"beacon1" latitude:kTestLatitude longitude:kTestLongitude];
    [RadarState setNearbyBeacons:@[beacon]];
    [RadarState setBeaconIds:@[]];  // Was not near any beacon
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:kTestLatitude longitude:kTestLongitude];
    
    BOOL changed = [RadarEfficientTrackManager hasBeaconStateChangedWithLocation:location];
    XCTAssertTrue(changed);
}

- (void)test_EfficientTrack_beaconStateChanged_exit {
    [self clearEfficientTrackingState];
    
    RadarBeacon *beacon = [self createTestBeaconWithId:@"beacon1" latitude:kTestLatitudeFar longitude:kTestLongitude];
    [RadarState setNearbyBeacons:@[beacon]];
    [RadarState setBeaconIds:@[@"beacon1"]];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:kTestLatitude longitude:kTestLongitude];

    BOOL changed = [RadarEfficientTrackManager hasBeaconStateChangedWithLocation:location];
    XCTAssertTrue(changed);
}

- (void)test_EfficientTrack_getPlaces_withinRadius {
    [self clearEfficientTrackingState];
    
    RadarPlace *place = [self createTestPlaceWithId:@"place1" latitude:kTestLatitude longitude:kTestLongitude];
    [RadarState setNearbyPlaces:@[place]];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:kTestLatitude longitude:kTestLongitude];

    NSArray<RadarPlace *> *places = [RadarEfficientTrackManager getPlacesFor:location];
    XCTAssertEqual(places.count, 1);
    XCTAssertEqualObjects(places.firstObject._id, @"place1");
}

- (void)test_EfficientTrack_getPlaces_outsideRadius {
    [self clearEfficientTrackingState];
    
    RadarPlace *place = [self createTestPlaceWithId:@"place1" latitude:kTestLatitudeFar longitude:kTestLongitude];
    [RadarState setNearbyPlaces:@[place]];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:kTestLatitude longitude:kTestLongitude];

    NSArray<RadarPlace *> *places = [RadarEfficientTrackManager getPlacesFor:location];
    XCTAssertEqual(places.count, 0);
}

- (void)test_EfficientTrack_placeStateChanged_entry {
    [self clearEfficientTrackingState];
    
    RadarPlace *place = [self createTestPlaceWithId:@"place1" latitude:kTestLatitude longitude:kTestLongitude];
    [RadarState setNearbyPlaces:@[place]];
    [RadarState setPlaceId:nil];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:kTestLatitude longitude:kTestLongitude];

    BOOL changed = [RadarEfficientTrackManager hasPlaceStateChangedWithLocation:location];
    XCTAssertTrue(changed);
}

- (void)test_EfficientTrack_placeStateChanged_exit {
    [self clearEfficientTrackingState];
    
    RadarPlace *place = [self createTestPlaceWithId:@"place1" latitude:kTestLatitudeFar longitude:kTestLongitude];
    [RadarState setNearbyPlaces:@[place]];
    [RadarState setPlaceId:@"place1"];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:kTestLatitude longitude:kTestLongitude];
    
    BOOL changed = [RadarEfficientTrackManager hasPlaceStateChangedWithLocation:location];
    XCTAssertTrue(changed);
}

- (void)test_EfficientTrack_isOutsideSyncedRegion_nil {
    [self clearEfficientTrackingState];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:kTestLatitude longitude:kTestLongitude];

    BOOL outside = [RadarEfficientTrackManager isOutsideSyncedRegionWithLocation:location];
    XCTAssertTrue(outside);
}

- (void)test_EfficientTrack_isOutsideSyncedRegion_inside {
    [self clearEfficientTrackingState];
    
    CLCircularRegion *syncedRegion = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(kTestLatitude, kTestLongitude) radius:100 identifier:@"synced"];
    [RadarState setSyncedRegion:syncedRegion];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:kTestLatitude longitude:kTestLongitude];

    BOOL outside = [RadarEfficientTrackManager isOutsideSyncedRegionWithLocation:location];
    XCTAssertFalse(outside);
}

- (void)test_EfficientTrack_isOutsideSyncedRegion_outside {
    [self clearEfficientTrackingState];
    
    CLCircularRegion *syncedRegion = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(kTestLatitude, kTestLongitude) radius:100 identifier:@"synced"];
    [RadarState setSyncedRegion:syncedRegion];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:kTestLatitudeFar longitude:kTestLongitude];
    
    BOOL outside = [RadarEfficientTrackManager isOutsideSyncedRegionWithLocation:location];
    XCTAssertTrue(outside);
}

- (void)test_EfficientTrack_isPointInsideCircle_inside {
    CLLocation *point = [[CLLocation alloc] initWithLatitude:kTestLatitude longitude:kTestLongitude];
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(kTestLatitude, kTestLongitude);
    
    BOOL inside = [RadarEfficientTrackManager isPoint:point insideCircleWithCenter:center radius:100];
    XCTAssertTrue(inside);
}

- (void)test_EfficientTrack_isPointInsideCircle_outside {
    CLLocation *point = [[CLLocation alloc] initWithLatitude:kTestLatitudeFar longitude:kTestLongitude];
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(kTestLatitude, kTestLongitude);
    
    BOOL inside = [RadarEfficientTrackManager isPoint:point insideCircleWithCenter:center radius:100];
    XCTAssertFalse(inside);
}

- (void)test_EfficientTrack_multipleGeofences_usesNearestBoundary {
    [self clearEfficientTrackingState];

    RadarGeofence *geofenceA = [self createTestGeofenceWithId:@"geofenceA" latitude:kTestLatitudeFar longitude:kTestLongitude radius:50];

    RadarGeofence *geofenceB = [self createTestGeofenceWithId:@"geofenceB" latitude:kTestLatitudeVeryFar longitude:kTestLongitude radius:100];
    [RadarState setNearbyGeofences:@[geofenceA, geofenceB]];
    
    [RadarState setGeofenceIds:@[]];
    
    CLLocation *userLocation = [[CLLocation alloc] initWithLatitude:kTestLatitude longitude:kTestLongitude];
    [RadarState setLastLocation:userLocation];
    
    
    RadarTrackingOptions *options = [RadarTrackingOptions new];
    options.syncOnGeofenceEvents = YES;
    [RadarSettings setTrackingOptions:options];
    [RadarSettings setTracking:YES];
        
    RadarTrackingOptions *fetchedOptions = [Radar getTrackingOptions];

    [[RadarLocationManager sharedInstance] updateSyncedRegion];

    CLCircularRegion *syncedRegion = [RadarState syncedRegion];

    XCTAssertNotNil(syncedRegion, @"syncedRegion is nil! syncOnGeofenceEvents=%d, lastLocation=%@, nearbyGeofences count=%lu",
                    fetchedOptions.syncOnGeofenceEvents,
                    [RadarState lastLocation],
                    (unsigned long)[[RadarState nearbyGeofences] count]);
    XCTAssertLessThan(syncedRegion.radius, 100);
}

- (void)test_EfficientTrack_mixedEntities_usesNearestBoundary {
    [self clearEfficientTrackingState];
    
    RadarGeofence *geofence = [self createTestGeofenceWithId:@"geofence1" latitude:kTestLatitudeVeryFar longitude:kTestLongitude radius:50];
    RadarPlace *place = [self createTestPlaceWithId:@"place1" latitude:kTestLatitudeFar longitude:kTestLongitude];
    RadarBeacon *beacon = [self createTestBeaconWithId:@"beacon1" latitude:kTestLatitudeMid longitude:kTestLongitude];
    
    [RadarState setNearbyGeofences:@[geofence]];
    [RadarState setNearbyPlaces:@[place]];
    [RadarState setNearbyBeacons:@[beacon]];
    [RadarState setGeofenceIds:@[]];
    [RadarState setPlaceId:nil];
    [RadarState setBeaconIds:@[]];
    
    CLLocation *userLocation = [[CLLocation alloc] initWithLatitude:kTestLatitude longitude:kTestLongitude];
    [RadarState setLastLocation:userLocation];
    
    RadarTrackingOptions *options = [RadarTrackingOptions new];
    options.syncOnGeofenceEvents = YES;
    [RadarSettings setTrackingOptions:options];
    [RadarSettings setTracking:YES];
    
    RadarTrackingOptions *fetchedOptions = [Radar getTrackingOptions];

    [[RadarLocationManager sharedInstance] updateSyncedRegion];

    CLCircularRegion *syncedRegion = [RadarState syncedRegion];

    XCTAssertNotNil(syncedRegion, @"syncedRegion is nil! syncOnGeofenceEvents=%d, lastLocation=%@, nearbyGeofences count=%lu, nearbyPlaces count=%lu, nearbyBeacons count=%lu",
                    fetchedOptions.syncOnGeofenceEvents,
                    [RadarState lastLocation],
                    (unsigned long)[[RadarState nearbyGeofences] count],
                    (unsigned long)[[RadarState nearbyPlaces] count],
                    (unsigned long)[[RadarState nearbyBeacons] count]);
    XCTAssertLessThan(syncedRegion.radius, 50);
}

- (void)test_EfficientTrack_multipleGeofences_shouldTrackWhenCrossingNearestBoundary {
    [self clearEfficientTrackingState];
    
    // Setup: Two geofences at different distances
    // Geofence A: user will be inside after moving
    // Geofence B: user will still be outside
    
    RadarGeofence *geofenceA = [self createTestGeofenceWithId:@"geofenceA" latitude:kTestLatitudeNearby longitude:kTestLongitude radius:100];
    RadarGeofence *geofenceB = [self createTestGeofenceWithId:@"geofenceB" latitude:kTestLatitudeFar longitude:kTestLongitude radius:50];
    [RadarState setNearbyGeofences:@[geofenceA, geofenceB]];
    
    // User was not in any geofence
    [RadarState setGeofenceIds:@[]];
    
    // User moves to kTestLatitudeNearby (inside geofenceA, outside geofenceB)
    CLLocation *newLocation = [[CLLocation alloc] initWithLatitude:kTestLatitudeNearby longitude:kTestLongitude];

    RadarTrackingOptions *options = [RadarTrackingOptions new];
    options.syncOnGeofenceEvents = YES;
    
    // Should detect geofence entry for geofenceA
    BOOL shouldTrack = [RadarEfficientTrackManager shouldTrackWithLocation:newLocation options:options];
    XCTAssertTrue(shouldTrack);
}

- (void)test_EfficientTrack_multipleGeofences_detectsCorrectGeofences {
    [self clearEfficientTrackingState];
    
    // Create 3 geofences: user will be inside 2 of them
    RadarGeofence *geofenceA = [self createTestGeofenceWithId:@"geofenceA" latitude:kTestLatitude longitude:kTestLongitude radius:100];
    RadarGeofence *geofenceB = [self createTestGeofenceWithId:@"geofenceB" latitude:kTestLatitudeNearby longitude:kTestLongitude radius:100];
    RadarGeofence *geofenceC = [self createTestGeofenceWithId:@"geofenceC" latitude:kTestLatitudeFar longitude:kTestLongitude radius:50];
    
    [RadarState setNearbyGeofences:@[geofenceA, geofenceB, geofenceC]];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:kTestLatitude longitude:kTestLongitude];

    NSArray<RadarGeofence *> *detectedGeofences = [RadarEfficientTrackManager getGeofencesFor:location];
    
    XCTAssertEqual(detectedGeofences.count, 2);
    
    NSSet *detectedIds = [NSSet setWithArray:[detectedGeofences valueForKey:@"_id"]];
    XCTAssertTrue([detectedIds containsObject:@"geofenceA"]);
    XCTAssertTrue([detectedIds containsObject:@"geofenceB"]);
    XCTAssertFalse([detectedIds containsObject:@"geofenceC"]);
}
@end
