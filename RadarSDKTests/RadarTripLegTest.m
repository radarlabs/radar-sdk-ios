//
//  RadarTripLegTest.m
//  RadarSDK
//
//  Created by Alan Charles on 2/24/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

@import RadarSDK;
#import <XCTest/XCTest.h>
#import "../RadarSDK/Include/RadarTripLeg.h"

@interface RadarTripLegTest : XCTestCase
@end

@implementation RadarTripLegTest

#pragma mark - Default State

- (void)test_init_defaults {
    RadarTripLeg *leg = [[RadarTripLeg alloc] init];
    XCTAssertNil(leg._id);
    XCTAssertNil(leg.destinationGeofenceTag);
    XCTAssertNil(leg.destinationGeofenceExternalId);
    XCTAssertNil(leg.destinationGeofenceId);
    XCTAssertNil(leg.address);
    XCTAssertNil(leg.metadata);
    XCTAssertNil(leg.createdAt);
    XCTAssertNil(leg.updatedAt);
    XCTAssertFalse(leg.hasCoordinates);
    XCTAssertEqual(leg.status, RadarTripLegStatusUnknown);
    XCTAssertEqual(leg.etaDuration, 0);
    XCTAssertEqual(leg.etaDistance, 0);
    XCTAssertEqual(leg.stopDuration, 0);
    XCTAssertEqual(leg.arrivalRadius, 0);
}

#pragma mark - Initializers

- (void)test_initWithGeofenceTagAndExternalId {
    RadarTripLeg *leg = [[RadarTripLeg alloc] initWithDestinationGeofenceTag:@"store"
                                              destinationGeofenceExternalId:@"store-1"];
    XCTAssertEqualObjects(leg.destinationGeofenceTag, @"store");
    XCTAssertEqualObjects(leg.destinationGeofenceExternalId, @"store-1");
    XCTAssertNil(leg.destinationGeofenceId);
    XCTAssertFalse(leg.hasCoordinates);
    XCTAssertEqual(leg.status, RadarTripLegStatusUnknown);
}


- (void)test_initWithGeofenceId {
    RadarTripLeg *leg = [[RadarTripLeg alloc] initWithDestinationGeofenceId:@"geofence_abc"];
    XCTAssertEqualObjects(leg.destinationGeofenceId, @"geofence_abc");
    XCTAssertNil(leg.destinationGeofenceTag);
    XCTAssertNil(leg.destinationGeofenceExternalId);
    XCTAssertFalse(leg.hasCoordinates);
}

- (void)test_initWithAddress {
    RadarTripLeg *leg = [[RadarTripLeg alloc] initWithAddress:@"123 Main St, New York, NY"];
    XCTAssertEqualObjects(leg.address, @"123 Main St, New York, NY");
    XCTAssertNil(leg.destinationGeofenceTag);
    XCTAssertFalse(leg.hasCoordinates);
}

- (void)test_initWithCoordinates {
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(40.783825, -73.975365);
    RadarTripLeg *leg = [[RadarTripLeg alloc] initWithCoordinates: coord];
    XCTAssertTrue(leg.hasCoordinates);
    XCTAssertEqual(leg.coordinates.latitude, 40.783825);
    XCTAssertEqual(leg.coordinates.longitude, -73.975365);
    XCTAssertEqual(leg.arrivalRadius, 0);
}

- (void)test_initWithCoordinatesAndArrivalRadius {
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(40.783825, -73.975365);
    RadarTripLeg *leg = [[RadarTripLeg alloc] initWithCoordinates:coord arrivalRadius:150];
    XCTAssertTrue(leg.hasCoordinates);
    XCTAssertEqual(leg.coordinates.latitude, 40.783825);
    XCTAssertEqual(leg.coordinates.longitude, -73.975365);
    XCTAssertEqual(leg.arrivalRadius, 150);
}

#pragma mark - Status String Conversion

- (void)test_stringForStatus {
    XCTAssertEqualObjects([RadarTripLeg stringForStatus:RadarTripLegStatusUnknown], @"unknown");
    XCTAssertEqualObjects([RadarTripLeg stringForStatus:RadarTripLegStatusPending], @"pending");
    XCTAssertEqualObjects([RadarTripLeg stringForStatus:RadarTripLegStatusStarted], @"started");
    XCTAssertEqualObjects([RadarTripLeg stringForStatus:RadarTripLegStatusApproaching], @"approaching");
    XCTAssertEqualObjects([RadarTripLeg stringForStatus:RadarTripLegStatusArrived], @"arrived");
    XCTAssertEqualObjects([RadarTripLeg stringForStatus:RadarTripLegStatusCompleted], @"completed");
    XCTAssertEqualObjects([RadarTripLeg stringForStatus:RadarTripLegStatusCanceled], @"canceled");
    XCTAssertEqualObjects([RadarTripLeg stringForStatus:RadarTripLegStatusExpired], @"expired");
}

- (void)test_statusForString {
    XCTAssertEqual([RadarTripLeg statusForString:@"pending"], RadarTripLegStatusPending);
    XCTAssertEqual([RadarTripLeg statusForString:@"started"], RadarTripLegStatusStarted);
    XCTAssertEqual([RadarTripLeg statusForString:@"approaching"], RadarTripLegStatusApproaching);
    XCTAssertEqual([RadarTripLeg statusForString:@"arrived"], RadarTripLegStatusArrived);
    XCTAssertEqual([RadarTripLeg statusForString:@"completed"], RadarTripLegStatusCompleted);
    XCTAssertEqual([RadarTripLeg statusForString:@"canceled"], RadarTripLegStatusCanceled);
    XCTAssertEqual([RadarTripLeg statusForString:@"expired"], RadarTripLegStatusExpired);
    XCTAssertEqual([RadarTripLeg statusForString:@"unknown"], RadarTripLegStatusUnknown);
    XCTAssertEqual([RadarTripLeg statusForString:@"invalid_garbage"], RadarTripLegStatusUnknown);
    XCTAssertEqual([RadarTripLeg statusForString:@""], RadarTripLegStatusUnknown);
}

#pragma mark - legFromDictionary: (Request Format)

- (void)test_legFromDictionary_requestFormat_geofenceTagAndExternalId {
    NSDictionary *dict = @{
        @"destination": @{
            @"destinationGeofenceTag": @"store",
            @"destinationGeofenceExternalId": @"store-1"
        },
        @"stopDuration": @(10),
        @"metadata": @{@"package": @"small"}
    };
    RadarTripLeg *leg = [RadarTripLeg legFromDictionary:dict];
    XCTAssertNotNil(leg);
    XCTAssertEqualObjects(leg.destinationGeofenceTag, @"store");
    XCTAssertEqualObjects(leg.destinationGeofenceExternalId, @"store-1");
    XCTAssertEqual(leg.stopDuration, 10);
    XCTAssertEqualObjects(leg.metadata[@"package"], @"small");
}

- (void)test_legFromDictionary_requestFormat_geofenceId {
    NSDictionary *dict = @{
        @"destination": @{
            @"destinationGeofenceId": @"geofence_abc"
        }
    };
    RadarTripLeg *leg = [RadarTripLeg legFromDictionary:dict];
    XCTAssertNotNil(leg);
    XCTAssertEqualObjects(leg.destinationGeofenceId, @"geofence_abc");
}

- (void)test_legFromDictionary_requestFormat_coordinates {
    NSDictionary *dict = @{
        @"destination": @{
            @"coordinates": @[@(-73.975365), @(40.783825)],
            @"arrivalRadius": @(200)
        }
    };
    RadarTripLeg *leg = [RadarTripLeg legFromDictionary:dict];
    XCTAssertNotNil(leg);
    XCTAssertTrue(leg.hasCoordinates);
    XCTAssertEqualWithAccuracy(leg.coordinates.latitude,40.783825, 0.0001);
    XCTAssertEqualWithAccuracy(leg.coordinates.longitude, -73.975365, 0.0001);
    XCTAssertEqual(leg.arrivalRadius, 200);
}

- (void)test_legFromDictionary_requestFormat_address {
    NSDictionary *dict = @{
        @"destination": @{
                @"address": @"456 Oak Ave"
        }
    };
    RadarTripLeg *leg = [RadarTripLeg legFromDictionary:dict];
    XCTAssertNotNil(leg);
    XCTAssertEqualObjects(leg.address, @"456 Oak Ave");
}

#pragma mark - legFromDictionary: (Response Format)

- (void)test_legFromDictionary_responseFormat {
    NSDictionary *dict = @{
        @"_id": @"leg_001",
        @"status": @"started",
        @"createdAt": @"2026-02-24T12:00:00.000Z",
        @"updatedAt": @"2026-02-24T12:05:00.000Z",
        @"eta": @{
            @"duration": @(5.0),
            @"distance": @(2000.0)
        },
        @"destination": @{
            @"source": @{
                @"geofence": @"geofence_aaa",
                @"data": @{
                    @"tag": @"store",
                    @"externalId": @"store-1"
                }
            },
            @"location": @{
                @"coordinates": @[@(-73.975365), @(40.783825)]
            },
            @"address": @"123 Main St"
        },
        @"stopDuration": @(10),
        @"metadata": @{@"package": @"small"}
    };
    RadarTripLeg *leg = [RadarTripLeg legFromDictionary:dict];
    XCTAssertNotNil(leg);
    XCTAssertEqualObjects(leg._id, @"leg_001");
    XCTAssertEqual(leg.status, RadarTripLegStatusStarted);
    XCTAssertNotNil(leg.createdAt);
    XCTAssertNotNil(leg.updatedAt);
    XCTAssertEqual(leg.etaDuration, 5.0);
    XCTAssertEqual(leg.etaDistance, 2000.0);
    XCTAssertEqualObjects(leg.destinationGeofenceId, @"geofence_aaa");
    XCTAssertEqualObjects(leg.destinationGeofenceTag, @"store");
    XCTAssertEqualObjects(leg.destinationGeofenceExternalId, @"store-1");
    XCTAssertTrue(leg.hasCoordinates);
    XCTAssertEqualWithAccuracy(leg.coordinates.latitude, 40.783825, 0.0001);
    XCTAssertEqualWithAccuracy(leg.coordinates.longitude, -73.975365, 0.0001);
    XCTAssertEqualObjects(leg.address, @"123 Main St");
    XCTAssertEqual(leg.stopDuration, 10);
    XCTAssertEqualObjects(leg.metadata[@"package"], @"small");
}

#pragma mark - legFromDictionary: (Invalid Input)

- (void)test_legFromDictionary_nil {
    XCTAssertNil([RadarTripLeg legFromDictionary:nil]);
}

- (void)test_legFromDictionary_nonDictionary {
    XCTAssertNil([RadarTripLeg legFromDictionary:(NSDictionary *)@"not a dict"]);
}

#pragma mark - dictionaryValue

- (void)test_dictionaryValue_geofenceLeg {
    RadarTripLeg *leg = [[RadarTripLeg alloc] initWithDestinationGeofenceTag:@"store" destinationGeofenceExternalId:@"store-1"];
    
    leg.stopDuration = 10;
    leg.metadata = @{@"key": @"value"};
    
    NSDictionary *dict = [leg dictionaryValue];
    NSDictionary *dest = dict[@"destination"];
    XCTAssertNotNil(dest);
    XCTAssertEqualObjects(dest[@"destinationGeofenceTag"], @"store");
    XCTAssertEqualObjects(dest[@"destinationGeofenceExternalId"], @"store-1");
    XCTAssertEqualObjects(dict[@"stopDuration"], @(10));
    XCTAssertEqualObjects(dict[@"metadata"][@"key"], @"value");
    XCTAssertNil(dict[@"_id"]);
    XCTAssertNil(dict[@"status"]);
}

- (void)test_dictionaryValue_coordinateLeg {
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(40.783825, -73.975365);
    RadarTripLeg *leg = [[RadarTripLeg alloc] initWithCoordinates:coord arrivalRadius:200];
    
    NSDictionary *dict = [leg dictionaryValue];
    NSDictionary *dest = dict[@"destination"];
    XCTAssertNotNil(dest);
    NSArray *coords = dest[@"coordinates"];
    XCTAssertEqual([coords[0] doubleValue], -73.975365);
    XCTAssertEqual([coords[1] doubleValue], 40.783825);
    XCTAssertEqualObjects(dest[@"arrivalRadius"], @(200));
}

- (void)test_dictionaryValue_includesResponseFields {
    NSDictionary *responseDict = @{
        @"_id": @"leg_xyz",
        @"status": @"arrived",
        @"eta": @{@"duration": @(3.5), @"distance": @(1200.0)},
        @"destination": @{
            @"source": @{
                @"geofence": @"gf_1",
                @"data": @{@"tag": @"t", @"externalId": @"e"}
            }
        }
    };
    RadarTripLeg *leg = [RadarTripLeg legFromDictionary:responseDict];
    NSDictionary *dict = [leg dictionaryValue];
    XCTAssertEqualObjects(dict[@"_id"], @"leg_xyz");
    XCTAssertEqualObjects(dict[@"status"], @"arrived");
    NSDictionary *eta = dict[@"eta"];
    XCTAssertEqualObjects(eta[@"duration"], @(3.5));
    XCTAssertEqualObjects(eta[@"distance"], @(1200.0));
}

#pragma mark - Array Serialization

- (void)test_legsFromArray {
    NSArray *array = @[
        @{@"destination": @{@"destinationGeofenceTag": @"a", @"destinationGeofenceExternalId": @"1"}},
        @{@"destination": @{@"destinationGeofenceTag": @"b", @"destinationGeofenceExternalId": @"2"}}
    ];
    NSArray<RadarTripLeg *> *legs = [RadarTripLeg legsFromArray:array];
    XCTAssertNotNil(legs);
    XCTAssertEqual(legs.count, 2);
    XCTAssertEqualObjects(legs[0].destinationGeofenceTag, @"a");
    XCTAssertEqualObjects(legs[1].destinationGeofenceTag, @"b");
}

- (void)test_legsFromArray_nilAndEmpty {
    XCTAssertNil([RadarTripLeg legsFromArray:nil]);
    XCTAssertNil([RadarTripLeg legsFromArray:@[]]);
}

- (void)test_arrayForLegs {
    RadarTripLeg *leg1 = [[RadarTripLeg alloc] initWithDestinationGeofenceTag:@"a"
                                               destinationGeofenceExternalId:@"1"];
    RadarTripLeg *leg2 = [[RadarTripLeg alloc] initWithAddress:@"456 St"];
    NSArray<NSDictionary *> *array = [RadarTripLeg arrayForLegs:@[leg1, leg2]];
    XCTAssertNotNil(array);
    XCTAssertEqual(array.count, 2);
}

- (void)test_arrayForLegs_nilAndEmpty {
    XCTAssertNil([RadarTripLeg arrayForLegs:nil]);
    XCTAssertNil([RadarTripLeg arrayForLegs:@[]]);
}

#pragma mark - Round-Trip Serialization

- (void)test_roundTrip_geofenceLeg {
    RadarTripLeg *original = [[RadarTripLeg alloc] initWithDestinationGeofenceTag:@"store"
                                                   destinationGeofenceExternalId:@"store-1"];
    original.stopDuration = 15;
    original.metadata = @{@"key": @"value"};
    
    NSDictionary *dict = [original dictionaryValue];
    RadarTripLeg *restored = [RadarTripLeg legFromDictionary:dict];
    XCTAssertTrue([original isEqual:restored]);
}

- (void)test_roundTrip_coordinateLeg {
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(40.783825, -73.975365);
    RadarTripLeg *original = [[RadarTripLeg alloc] initWithCoordinates:coord arrivalRadius:100];
    original.stopDuration = 5;
    
    NSDictionary *dict = [original dictionaryValue];
    RadarTripLeg *restored = [RadarTripLeg legFromDictionary:dict];
    XCTAssertTrue([original isEqual:restored]);
}

#pragma mark - isEqual

- (void)test_isEqual_sameLeg {
    RadarTripLeg *leg1 = [[RadarTripLeg alloc] initWithDestinationGeofenceTag:@"store"
                                               destinationGeofenceExternalId:@"store-1"];
    leg1.stopDuration = 10;
    leg1.metadata = @{@"k": @"v"};

    RadarTripLeg *leg2 = [[RadarTripLeg alloc] initWithDestinationGeofenceTag:@"store"
                                               destinationGeofenceExternalId:@"store-1"];
    leg2.stopDuration = 10;
    leg2.metadata = @{@"k": @"v"};

    XCTAssertTrue([leg1 isEqual:leg2]);
}

- (void)test_isEqual_differentTag {
    RadarTripLeg *leg1 = [[RadarTripLeg alloc] initWithDestinationGeofenceTag:@"store"
                                               destinationGeofenceExternalId:@"store-1"];
    RadarTripLeg *leg2 = [[RadarTripLeg alloc] initWithDestinationGeofenceTag:@"warehouse"
                                               destinationGeofenceExternalId:@"store-1"];
    XCTAssertFalse([leg1 isEqual:leg2]);
}

- (void)test_isEqual_differentStopDuration {
    RadarTripLeg *leg1 = [[RadarTripLeg alloc] initWithAddress:@"123 St"];
    leg1.stopDuration = 10;
    RadarTripLeg *leg2 = [[RadarTripLeg alloc] initWithAddress:@"123 St"];
    leg2.stopDuration = 20;
    XCTAssertFalse([leg1 isEqual:leg2]);
}

- (void)test_isEqual_nilAndWrongType {
    RadarTripLeg *leg = [[RadarTripLeg alloc] initWithAddress:@"123 St"];
    XCTAssertFalse([leg isEqual:nil]);
    XCTAssertFalse([leg isEqual:@"not a leg"]);
}

- (void)test_isEqual_sameInstance {
    RadarTripLeg *leg = [[RadarTripLeg alloc] initWithAddress:@"123 St"];
    XCTAssertTrue([leg isEqual:leg]);
}

#pragma mark - Coordinate Handling

- (void)test_setDestinationCoordinates_valid {
    RadarTripLeg *leg = [[RadarTripLeg alloc] init];
    XCTAssertFalse(leg.hasCoordinates);
    [leg setDestinationCoordinates:CLLocationCoordinate2DMake(40.0, -74.0)];
    XCTAssertTrue(leg.hasCoordinates);
    XCTAssertEqual(leg.coordinates.latitude, 40.0);
    XCTAssertEqual(leg.coordinates.longitude, -74.0);
}
 
- (void)test_setDestinationCoordinates_invalid {
    RadarTripLeg *leg = [[RadarTripLeg alloc] init];
    [leg setDestinationCoordinates:kCLLocationCoordinate2DInvalid];
    XCTAssertFalse(leg.hasCoordinates);
}

@end
