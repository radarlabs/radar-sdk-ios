//
//  RadarSDKTests.m
//  RadarSDKTests
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <RadarSDK/RadarSDK.h>

#import "RadarAPIClient.h"
#import "RadarAPIHelper.h"
#import "RadarLocationManager.h"
#import "RadarSettings.h"

@interface CLVisitMock : CLVisit

- (instancetype _Nullable)initWithCoordinate:(CLLocationCoordinate2D)coordinate horizontalAccuracy:(CLLocationAccuracy)horizontalAccuracy arrivalDate:(NSDate *)arrivalDate departureDate:(NSDate *)departureDate;

@end

@implementation CLVisitMock

- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate horizontalAccuracy:(CLLocationAccuracy)horizontalAccuracy arrivalDate:(NSDate *)arrivalDate departureDate:(NSDate *)departureDate {
    self = [super init];
    if (self) {
        self.coordinate = coordinate;
        self.horizontalAccuracy = horizontalAccuracy;
        self.arrivalDate = arrivalDate;
        self.departureDate = departureDate;
    }
    return self;
}

- (void)setCoordinate:(CLLocationCoordinate2D)coordinate {
    self.coordinate = coordinate;
}

- (void)setHorizontalAccuracy:(CLLocationAccuracy)horizontalAccuracy {
    self.horizontalAccuracy = horizontalAccuracy;
}

- (void)setArrivalDate:(NSDate *)arrivalDate {
    self.arrivalDate = arrivalDate;
}

- (void)setDepartureDate:(NSDate *)departureDate {
    self.departureDate = departureDate;
}

@end

@interface CLLocationManagerMock : CLLocationManager

@property (nullable, strong, nonatomic) CLLocation *mockLocation;

- (void)mockRegionEnter;
- (void)mockRegionExit;
- (void)mockVisitArrival;
- (void)mockVisitDeparture;

@end

@implementation CLLocationManagerMock

- (void)requestLocation {
    if (self.delegate && self.mockLocation) {
       [self.delegate locationManager:self didUpdateLocations:@[self.mockLocation]];
    }
}

- (void)mockRegionEnter {
    if (self.delegate) {
        CLRegion *region = [[CLCircularRegion alloc] initWithCenter:self.mockLocation.coordinate radius:100 identifier:@"radar"];
        [self.delegate locationManager:self didEnterRegion:region];
    }
}

- (void)mockRegionExit {
    if (self.delegate) {
        CLRegion *region = [[CLCircularRegion alloc] initWithCenter:self.mockLocation.coordinate radius:100 identifier:@"radar"];
        [self.delegate locationManager:self didExitRegion:region];
    }
}

- (void)mockVisitArrival {
    if (self.delegate) {
        NSDate *now = [NSDate new];
        CLVisit *visit = [[CLVisitMock alloc] initWithCoordinate:self.mockLocation.coordinate horizontalAccuracy:100 arrivalDate:now departureDate:[NSDate distantFuture]];
        [self.delegate locationManager:self didVisit:visit];
    }
}

- (void)mockVisitDeparture {
    if (self.delegate) {
        NSDate *now = [NSDate new];
        CLVisit *visit = [[CLVisitMock alloc] initWithCoordinate:self.mockLocation.coordinate horizontalAccuracy:100 arrivalDate:[now dateByAddingTimeInterval:-1000] departureDate:now];
        [self.delegate locationManager:self didVisit:visit];
    }
}

- (void)setPausesLocationUpdatesAutomatically:(BOOL)pausesLocationUpdatesAutomatically {
    
}

@end

@interface RadarAPIHelperMock : RadarAPIHelper

@property (assign, nonatomic) RadarStatus mockStatus;
@property (nonnull, strong, nonatomic) NSDictionary *mockResponse;

@end

@implementation RadarAPIHelperMock

- (void)requestWithMethod:(NSString *)method url:(NSString *)url headers:(NSDictionary *)headers params:(NSDictionary *)params completionHandler:(RadarAPICompletionHandler)completionHandler {
    completionHandler(self.mockStatus, self.mockResponse);
}

@end

@interface RadarPermissionsHelperMock : RadarPermissionsHelper

@property (assign, nonatomic) CLAuthorizationStatus mockLocationAuthorizationStatus;

@end

@implementation RadarPermissionsHelperMock

- (CLAuthorizationStatus)locationAuthorizationStatus {
    return self.mockLocationAuthorizationStatus;
}

@end

@interface RadarSDKTestUtils : NSObject

+ (NSDictionary *)jsonDictionaryFromResource:(NSString *)resource;

@end

@implementation RadarSDKTestUtils

+ (NSDictionary *)jsonDictionaryFromResource:(NSString *)resource {
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:resource ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSError *deserializationError = nil;
    id jsonObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&deserializationError];
    NSDictionary *jsonDict = (NSDictionary *)jsonObj;
    return jsonDict;
}

@end

@interface RadarSDKTests : XCTestCase

@property (nonnull, strong, nonatomic) RadarAPIHelperMock *apiHelperMock;
@property (nonnull, strong, nonatomic) CLLocationManagerMock *locationManagerMock;
@property (nonnull, strong, nonatomic) RadarPermissionsHelperMock *permissionsHelperMock;

@end

@implementation RadarSDKTests

static NSString * const kPublishableKey = @"prj_test_pk_0000000000000000000000000000000000000000";

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
    
    [Radar getLocationWithCompletionHandler:^(RadarStatus status, CLLocation * _Nullable location, BOOL stopped) {
        XCTAssertEqual(status, RadarStatusErrorPermissions);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError * _Nullable error) {
        if (error) {
            XCTFail();
        }
    }];
}

- (void)test_Radar_getLocation_errorLocation {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.locationManagerMock.mockLocation = nil;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];
    
    [Radar getLocationWithCompletionHandler:^(RadarStatus status, CLLocation * _Nullable location, BOOL stopped) {
        XCTAssertEqual(status, RadarStatusErrorLocation);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError * _Nullable error) {
        if (error) {
            XCTFail();
        }
    }];
}
 
- (void)test_Radar_getLocation_success {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.locationManagerMock.mockLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(40.783826, -73.975363) altitude:-1 horizontalAccuracy:65 verticalAccuracy:-1 timestamp:[NSDate new]];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];
    
    [Radar getLocationWithCompletionHandler:^(RadarStatus status, CLLocation * _Nullable location, BOOL stopped) {
        XCTAssertEqual(status, RadarStatusSuccess);
        XCTAssertEqualObjects(self.locationManagerMock.mockLocation, location);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError * _Nullable error) {
        if (error) {
            XCTFail();
        }
    }];
}

- (void)test_Radar_trackOnce_errorPermissions {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusNotDetermined;
    self.locationManagerMock.mockLocation = nil;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];
    
    [Radar trackOnceWithCompletionHandler:^(RadarStatus status, CLLocation * _Nullable location, NSArray<RadarEvent *> * _Nullable events, RadarUser * _Nullable user) {
        XCTAssertEqual(status, RadarStatusErrorPermissions);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError * _Nullable error) {
        if (error) {
            XCTFail();
        }
    }];
}

- (void)test_Radar_trackOnce_errorLocation {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.locationManagerMock.mockLocation = nil;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];
    
    [Radar trackOnceWithCompletionHandler:^(RadarStatus status, CLLocation * _Nullable location, NSArray<RadarEvent *> * _Nullable events, RadarUser * _Nullable user) {
        XCTAssertEqual(status, RadarStatusErrorLocation);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError * _Nullable error) {
        if (error) {
            XCTFail();
        }
    }];
}

- (void)test_Radar_trackOnce_success {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.locationManagerMock.mockLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(40.783826, -73.975363) altitude:-1 horizontalAccuracy:65 verticalAccuracy:-1 timestamp:[NSDate new]];
    self.apiHelperMock.mockStatus = RadarStatusSuccess;
    self.apiHelperMock.mockResponse = [RadarSDKTestUtils jsonDictionaryFromResource:@"track"];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];
    
    [Radar trackOnceWithCompletionHandler:^(RadarStatus status, CLLocation * _Nullable location, NSArray<RadarEvent *> * _Nullable events, RadarUser * _Nullable user) {
        XCTAssertEqual(status, RadarStatusSuccess);
        XCTAssertEqualObjects(self.locationManagerMock.mockLocation, location);
        XCTAssertNotNil(events);
        XCTAssertNotNil(user);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError * _Nullable error) {
        if (error) {
            XCTFail();
        }
    }];
}

- (void)test_Radar_trackOnce_location_success {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusNotDetermined;
    CLLocation *mockLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(40.783826, -73.975363) altitude:-1 horizontalAccuracy:65 verticalAccuracy:-1 timestamp:[NSDate new]];
    self.apiHelperMock.mockStatus = RadarStatusSuccess;
    self.apiHelperMock.mockResponse = [RadarSDKTestUtils jsonDictionaryFromResource:@"track"];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];
    
    [Radar trackOnceWithLocation:mockLocation completionHandler:^(RadarStatus status, CLLocation * _Nullable location, NSArray<RadarEvent *> * _Nullable events, RadarUser * _Nullable user) {
        XCTAssertEqual(status, RadarStatusSuccess);
        XCTAssertNotNil(events);
        XCTAssertNotNil(user);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError * _Nullable error) {
        if (error) {
            XCTFail();
        }
    }];
}

- (void)test_Radar_startTracking_errorPermissions {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusNotDetermined;
    self.locationManagerMock.mockLocation = nil;
    
    [Radar stopTracking];
    
    [Radar startTracking];
    XCTAssertFalse([Radar isTracking]);
}

- (void)test_Radar_startTracking_default {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    
    [Radar stopTracking];
    
    [Radar startTracking];
    XCTAssertEqualObjects(RadarTrackingOptions.efficient, [Radar getTrackingOptions]);
    XCTAssertTrue([Radar isTracking]);
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

- (void)test_Radar_acceptEventId {
    self.apiHelperMock.mockStatus = RadarStatusSuccess;
    self.apiHelperMock.mockResponse = [RadarSDKTestUtils jsonDictionaryFromResource:@"events_verification"];
    [Radar acceptEventId:@"eventId" verifiedPlaceId:nil];
}

- (void)test_Radar_acceptEventId_verifiedPlaceId {
    self.apiHelperMock.mockStatus = RadarStatusSuccess;
    self.apiHelperMock.mockResponse = [RadarSDKTestUtils jsonDictionaryFromResource:@"events_verification"];
    [Radar acceptEventId:@"eventId" verifiedPlaceId:@"verifiedPlaceId"];
}

- (void)test_Radar_rejectEvent {
    self.apiHelperMock.mockStatus = RadarStatusSuccess;
    self.apiHelperMock.mockResponse = [RadarSDKTestUtils jsonDictionaryFromResource:@"events_verification"];
    [Radar rejectEventId:@"eventId"];
}

- (void)test_Radar_searchPlaces_errorPermissions {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusNotDetermined;
    self.locationManagerMock.mockLocation = nil;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];
    
    [Radar searchPlacesWithRadius:1000 chains:@[@"walmart"] categories:nil groups:nil limit:100 completionHandler:^(RadarStatus status, CLLocation * _Nullable location, NSArray<RadarPlace *> * _Nullable places) {
        XCTAssertEqual(status, RadarStatusErrorPermissions);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError * _Nullable error) {
        if (error) {
            XCTFail();
        }
    }];
}

- (void)test_Radar_searchPlaces_errorLocation {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.locationManagerMock.mockLocation = nil;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];
    
    [Radar searchPlacesWithRadius:1000 chains:@[@"walmart"] categories:nil groups:nil limit:100 completionHandler:^(RadarStatus status, CLLocation * _Nullable location, NSArray<RadarPlace *> * _Nullable places) {
        XCTAssertEqual(status, RadarStatusErrorLocation);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError * _Nullable error) {
        if (error) {
            XCTFail();
        }
    }];
}

- (void)test_Radar_searchPlaces_chains_success {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.locationManagerMock.mockLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(40.783826, -73.975363) altitude:-1 horizontalAccuracy:65 verticalAccuracy:-1 timestamp:[NSDate new]];
    self.apiHelperMock.mockStatus = RadarStatusSuccess;
    self.apiHelperMock.mockResponse = [RadarSDKTestUtils jsonDictionaryFromResource:@"search_places"];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];
    
    [Radar searchPlacesWithRadius:1000 chains:@[@"walmart"] categories:nil groups:nil limit:100 completionHandler:^(RadarStatus status, CLLocation * _Nullable location, NSArray<RadarPlace *> * _Nullable places) {
        XCTAssertEqual(status, RadarStatusSuccess);
        XCTAssertNotNil(location);
        XCTAssertNotNil(places);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError * _Nullable error) {
        if (error) {
            XCTFail();
        }
    }];
}

- (void)test_Radar_searchPlacesNear_categories_success {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusNotDetermined;
    CLLocation *mockLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(40.783826, -73.975363) altitude:-1 horizontalAccuracy:65 verticalAccuracy:-1 timestamp:[NSDate new]];
    self.apiHelperMock.mockStatus = RadarStatusSuccess;
    self.apiHelperMock.mockResponse = [RadarSDKTestUtils jsonDictionaryFromResource:@"search_places"];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];
    
    [Radar searchPlacesNear:mockLocation radius:1000 chains:nil categories:@[@"restaurant"] groups:nil limit:100 completionHandler:^(RadarStatus status, CLLocation * _Nullable location, NSArray<RadarPlace *> * _Nullable places) {
        XCTAssertEqual(status, RadarStatusSuccess);
        XCTAssertNotNil(location);
        XCTAssertNotNil(places);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError * _Nullable error) {
        if (error) {
            XCTFail();
        }
    }];
}

- (void)test_Radar_searchGeofences_errorPermissions {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusNotDetermined;
    self.locationManagerMock.mockLocation = nil;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];
    
    [Radar searchGeofencesWithRadius:1000 tags:nil limit:100 completionHandler:^(RadarStatus status, CLLocation * _Nullable location, NSArray<RadarGeofence *> * _Nullable geofences) {
        XCTAssertEqual(status, RadarStatusErrorPermissions);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError * _Nullable error) {
        if (error) {
            XCTFail();
        }
    }];
}

- (void)test_Radar_searchGeofences_errorLocation {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.locationManagerMock.mockLocation = nil;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];
    
    [Radar searchGeofencesWithRadius:1000 tags:nil limit:100 completionHandler:^(RadarStatus status, CLLocation * _Nullable location, NSArray<RadarGeofence *> * _Nullable geofences) {
        XCTAssertEqual(status, RadarStatusErrorLocation);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError * _Nullable error) {
        if (error) {
            XCTFail();
        }
    }];
}

- (void)test_Radar_searchGeofences_success {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.locationManagerMock.mockLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(40.783826, -73.975363) altitude:-1 horizontalAccuracy:65 verticalAccuracy:-1 timestamp:[NSDate new]];
    self.apiHelperMock.mockStatus = RadarStatusSuccess;
    self.apiHelperMock.mockResponse = [RadarSDKTestUtils jsonDictionaryFromResource:@"search_geofences"];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];
    
    [Radar searchGeofencesWithRadius:1000 tags:@[@"store"] limit:100 completionHandler:^(RadarStatus status, CLLocation * _Nullable location, NSArray<RadarGeofence *> * _Nullable geofences) {
        XCTAssertEqual(status, RadarStatusSuccess);
        XCTAssertNotNil(location);
        XCTAssertNotNil(geofences);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError * _Nullable error) {
        if (error) {
            XCTFail();
        }
    }];
}

- (void)test_Radar_autocomplete_success {
    self.apiHelperMock.mockStatus = RadarStatusSuccess;
    self.apiHelperMock.mockResponse = [RadarSDKTestUtils jsonDictionaryFromResource:@"search_autocomplete"];
    
    CLLocation *near = [[CLLocation alloc] initWithLatitude:40.783826 longitude:-73.975363];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];
    
    [Radar autocompleteQuery:@"brooklyn roasting" near:near limit:10 completionHandler:^(RadarStatus status, NSArray<RadarAddress *> * _Nullable addresses) {
        XCTAssertEqual(status, RadarStatusSuccess);
        XCTAssertNotNil(addresses);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError * _Nullable error) {
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

    [Radar geocodeAddress:geocodeQuery completionHandler:^(RadarStatus status, NSArray<RadarAddress *> * _Nullable addresses) {
        XCTAssertEqual(status, RadarStatusErrorServer);
        XCTAssertNil(addresses);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:30 handler:^(NSError * _Nullable error) {
        if (error) {
            XCTFail();
        }
    }];
}

- (void)test_Radar_geocode_success {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.apiHelperMock.mockStatus = RadarStatusSuccess;
    self.apiHelperMock.mockResponse = [RadarSDKTestUtils jsonDictionaryFromResource:@"geocode"];

    NSString *query = @"20 jay st brooklyn";

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar geocodeAddress:query completionHandler:^(RadarStatus status, NSArray<RadarAddress *> * _Nullable addresses) {
        XCTAssertEqual(status, RadarStatusSuccess);
        XCTAssertNotNil(addresses);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:30 handler:^(NSError * _Nullable error) {
        if (error) {
            XCTFail();
        }
    }];
}

- (void)test_Radar_reverseGeocode_errorPermissions {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusNotDetermined;
    self.locationManagerMock.mockLocation = nil;

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar reverseGeocodeWithCompletionHandler:^(RadarStatus status, NSArray<RadarAddress *> * _Nullable addresses) {
        XCTAssertEqual(status, RadarStatusErrorPermissions);
        XCTAssertNil(addresses);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:30 handler:^(NSError * _Nullable error) {
        if (error) {
            XCTFail();
        }
    }];
}

- (void)test_Radar_reverseGeocode_errorLocation {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.locationManagerMock.mockLocation = nil;

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar reverseGeocodeWithCompletionHandler:^(RadarStatus status, NSArray<RadarAddress *> * _Nullable addresses) {
        XCTAssertEqual(status, RadarStatusErrorLocation);
        XCTAssertNil(addresses);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:30 handler:^(NSError * _Nullable error) {
        if (error) {
            XCTFail();
        }
    }];
}

- (void)test_Radar_reverseGeocode_success {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.locationManagerMock.mockLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(40.783826, -73.975363) altitude:-1 horizontalAccuracy:65 verticalAccuracy:-1 timestamp:[NSDate new]];
    self.apiHelperMock.mockStatus = RadarStatusSuccess;
    self.apiHelperMock.mockResponse = [RadarSDKTestUtils jsonDictionaryFromResource:@"geocode"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar reverseGeocodeWithCompletionHandler:^(RadarStatus status, NSArray<RadarAddress *> * _Nullable addresses) {
        XCTAssertEqual(status, RadarStatusSuccess);
        XCTAssertNotNil(addresses);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:30 handler:^(NSError * _Nullable error) {
        if (error) {
            XCTFail();
        }
    }];
}

- (void)test_Radar_reverseGeocodeLocation_error {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.apiHelperMock.mockStatus = RadarStatusErrorServer;

    CLLocation *location = [[CLLocation alloc] initWithLatitude:40.783826 longitude:-73.975363];

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar reverseGeocodeLocation:location completionHandler:^(RadarStatus status, NSArray<RadarAddress *> * _Nullable addresses) {
        XCTAssertEqual(status, RadarStatusErrorServer);
        XCTAssertNil(addresses);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:30 handler:^(NSError * _Nullable error) {
        if (error) {
            XCTFail();
        }
    }];
}

- (void)test_Radar_reverseGeocodeLocation_success {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.apiHelperMock.mockStatus = RadarStatusSuccess;
    self.apiHelperMock.mockResponse = [RadarSDKTestUtils jsonDictionaryFromResource:@"geocode"];

    CLLocation *location = [[CLLocation alloc] initWithLatitude:40.783826 longitude:-73.975363];

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar reverseGeocodeLocation:location completionHandler:^(RadarStatus status, NSArray<RadarAddress *> * _Nullable addresses) {
        XCTAssertEqual(status, RadarStatusSuccess);
        XCTAssertNotNil(addresses);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:30 handler:^(NSError * _Nullable error) {
        if (error) {
            XCTFail();
        }
    }];
}

- (void)test_Radar_ipGeocode_error {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.apiHelperMock.mockStatus = RadarStatusErrorServer;

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar ipGeocodeWithCompletionHandler:^(RadarStatus status, RadarRegion * _Nullable country) {
        XCTAssertEqual(status, RadarStatusErrorServer);
        XCTAssertNil(country);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:30 handler:^(NSError * _Nullable error) {
        if (error) {
            XCTFail();
        }
    }];
}

- (void)test_Radar_ipGeocode_success {
    self.permissionsHelperMock.mockLocationAuthorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    self.apiHelperMock.mockStatus = RadarStatusSuccess;
    self.apiHelperMock.mockResponse = [RadarSDKTestUtils jsonDictionaryFromResource:@"geocode_ip"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    [Radar ipGeocodeWithCompletionHandler:^(RadarStatus status, RadarRegion * _Nullable country) {
        XCTAssertEqual(status, RadarStatusSuccess);
        XCTAssertNotNil(country);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:30 handler:^(NSError * _Nullable error) {
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
