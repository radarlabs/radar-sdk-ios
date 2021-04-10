//
//  RadarSDKTests.m
//  RadarSDKTests
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

@import RadarSDK;
#import <XCTest/XCTest.h>

#import "CLLocationManagerMock.h"
#import "CLVisitMock.h"
#import "RadarAPIClient.h"
#import "RadarAPIHelper.h"
#import "RadarAPIHelperMock.h"
#import "RadarLocationManager.h"
#import "RadarPermissionsHelperMock.h"
#import "RadarSettings.h"
#import "RadarTestUtils.h"
#import "RadarTripOptions.h"

@interface RadarSDKTests : XCTestCase

@property (nonnull, strong, nonatomic) RadarAPIHelperMock *apiHelperMock;
@property (nonnull, strong, nonatomic) CLLocationManagerMock *locationManagerMock;
@property (nonnull, strong, nonatomic) RadarPermissionsHelperMock *permissionsHelperMock;

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
    XCTAssertNotNil(geofence._description);
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

#define AssertInsightsOk(insights) [self assertInsightsOk:insights]
- (void)assertInsightsOk:(RadarUserInsights *)insights {
    XCTAssertNotNil(insights);
    XCTAssertNotNil(insights.homeLocation);
    XCTAssertTrue(insights.homeLocation.updatedAt);
    XCTAssertNotEqual(insights.homeLocation.confidence, RadarUserInsightsLocationConfidenceNone);
    XCTAssertNotNil(insights.officeLocation);
    XCTAssertNotNil(insights.officeLocation.updatedAt);
    XCTAssertNotEqual(insights.officeLocation.confidence, RadarUserInsightsLocationConfidenceNone);
    XCTAssertNotNil(insights.state);
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
    XCTAssertNotNil(segment._description);
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

#define AssertUserOk(user) [self assertUserOk:user]
- (void)assertUserOk:(RadarUser *)user {
    XCTAssertNotNil(user);
    XCTAssertNotNil(user._id);
    XCTAssertNotNil(user.userId);
    XCTAssertNotNil(user.deviceId);
    XCTAssertNotNil(user._description);
    XCTAssertNotNil(user.metadata);
    XCTAssertNotNil(user.location);
    AssertGeofencesOk(user.geofences);
    AssertPlaceOk(user.place);
    AssertInsightsOk(user.insights);
    AssertRegionOk(user.country);
    AssertRegionOk(user.state);
    AssertRegionOk(user.dma);
    AssertRegionOk(user.postalCode);
    AssertChainsOk(user.nearbyPlaceChains);
    AssertSegmentsOk(user.segments);
    AssertChainsOk(user.topChains);
    XCTAssertNotEqual(user.source, RadarLocationSourceUnknown);
    XCTAssertTrue(user.proxy);
    AssertTripOk(user.trip);
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
    case RadarEventTypeUserEnteredHome:
        break;
    case RadarEventTypeUserExitedHome:
        break;
    case RadarEventTypeUserEnteredOffice:
        break;
    case RadarEventTypeUserExitedOffice:
        break;
    case RadarEventTypeUserStartedTraveling:
        break;
    case RadarEventTypeUserStoppedTraveling:
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
    case RadarEventTypeUserStartedCommuting:
        break;
    case RadarEventTypeUserStoppedCommuting:
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

- (void)setUp {
    [super setUp];

    [Radar initializeWithPublishableKey:kPublishableKey];
    [Radar setLogLevel:RadarLogLevelDebug];

    self.apiHelperMock = [RadarAPIHelperMock new];
    self.locationManagerMock = [CLLocationManagerMock new];
    self.permissionsHelperMock = [RadarPermissionsHelperMock new];

    [RadarAPIClient sharedInstance].apiHelper = self.apiHelperMock;
    [RadarLocationManager sharedInstance].locationManager = self.locationManagerMock;
    self.locationManagerMock.delegate = [RadarLocationManager sharedInstance];
    [RadarLocationManager sharedInstance].lowPowerLocationManager = self.locationManagerMock;
    [RadarLocationManager sharedInstance].permissionsHelper = self.permissionsHelperMock;
}

- (void)tearDown {
}

- (void)test_Radar_initialize {
    XCTAssertEqualObjects(kPublishableKey, [RadarSettings publishableKey]);
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

    [Radar startTrackingWithOptions:RadarTrackingOptions.efficient];
    XCTAssertFalse([Radar isTracking]);
}

- (void)test_Radar_startTracking_continuous {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;

    [Radar stopTracking];

    RadarTrackingOptions *options = RadarTrackingOptions.continuous;
    [Radar startTrackingWithOptions:options];
    XCTAssertEqualObjects(options, [Radar getTrackingOptions]);
    XCTAssertTrue([Radar isTracking]);
}

- (void)test_Radar_startTracking_responsive {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;

    [Radar stopTracking];

    RadarTrackingOptions *options = RadarTrackingOptions.responsive;
    [Radar startTrackingWithOptions:options];
    XCTAssertEqualObjects(options, [Radar getTrackingOptions]);
    XCTAssertTrue([Radar isTracking]);
}

- (void)test_Radar_startTracking_efficient {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;

    [Radar stopTracking];

    RadarTrackingOptions *options = RadarTrackingOptions.efficient;
    [Radar startTrackingWithOptions:options];
    XCTAssertEqualObjects(options, [Radar getTrackingOptions]);
    XCTAssertTrue([Radar isTracking]);
}

- (void)test_Radar_startTracking_custom {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;

    [Radar stopTracking];

    RadarTrackingOptions *options = RadarTrackingOptions.efficient;
    options.desiredAccuracy = RadarTrackingOptionsDesiredAccuracyLow;
    NSDate *now = [NSDate new];
    options.startTrackingAfter = now;
    options.stopTrackingAfter = [now dateByAddingTimeInterval:1000];
    options.sync = RadarTrackingOptionsSyncNone;
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

    CLLocation *origin = [[CLLocation alloc] initWithLatitude:40.78382 longitude:-73.97536];
    CLLocation *destination = [[CLLocation alloc] initWithLatitude:40.70390 longitude:-73.98670];
    int steps = 20;
    __block int i = 0;

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar mockTrackingWithOrigin:origin
                      destination:destination
                             mode:RadarRouteModeCar
                            steps:steps
                         interval:1
                completionHandler:^(RadarStatus status, CLLocation *_Nullable location, NSArray<RadarEvent *> *_Nullable events, RadarUser *_Nullable user) {
                    i++;

                    if (i == steps - 1) {
                        [expectation fulfill];
                    }
                }];

    [self waitForExpectationsWithTimeout:30
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

- (void)test_Radar_startTrip {
    RadarTripOptions *options = [[RadarTripOptions alloc] initWithExternalId:@"tripExternalId"];
    options.metadata = @{@"foo": @"bar", @"baz": @YES, @"qux": @1};
    options.destinationGeofenceTag = @"tripDestinationGeofenceTag";
    options.destinationGeofenceExternalId = @"tripDestinationExternalId";
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

    [self waitForExpectationsWithTimeout:30
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
                            limit:100
                completionHandler:^(RadarStatus status, CLLocation *_Nullable location, NSArray<RadarPlace *> *_Nullable places) {
                    XCTAssertEqual(status, RadarStatusErrorLocation);

                    [expectation fulfill];
                }];

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

    [Radar searchGeofencesWithRadius:1000
                                tags:nil
                            metadata:nil
                               limit:100
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

    [Radar searchGeofencesWithRadius:1000
                                tags:nil
                            metadata:nil
                               limit:100
                   completionHandler:^(RadarStatus status, CLLocation *_Nullable location, NSArray<RadarGeofence *> *_Nullable geofences) {
                       XCTAssertEqual(status, RadarStatusErrorLocation);

                       [expectation fulfill];
                   }];

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

    [Radar searchGeofencesWithRadius:1000
                                tags:@[@"store"]
                            metadata:@{@"foo": @"bar"}
                               limit:100
                   completionHandler:^(RadarStatus status, CLLocation *_Nullable location, NSArray<RadarGeofence *> *_Nullable geofences) {
                       XCTAssertEqual(status, RadarStatusSuccess);
                       XCTAssertNotNil(location);
                       AssertGeofencesOk(geofences);

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
                       limit:10
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
    RadarTrackingOptions *options = RadarTrackingOptions.efficient;
    XCTAssertNotEqualObjects(options, nil);
    XCTAssertEqualObjects(options, options);
    XCTAssertNotEqualObjects(options, @"foo");
}

@end
