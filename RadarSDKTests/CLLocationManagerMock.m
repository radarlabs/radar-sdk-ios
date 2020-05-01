//
//  CLLocationManagerMock.m
//  RadarSDKTests
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "CLLocationManagerMock.h"
#import "CLVisitMock.h"

@implementation CLLocationManagerMock

- (void)requestLocation {
    if (self.delegate && self.mockLocation) {
        [self.delegate locationManager:self didUpdateLocations:@[self.mockLocation]];
    }
}

- (void)startMonitoringForRegion:(CLRegion *)region {
    if (!self.delegate) {
        NSAssert(NO, @"Delegate is not set");
        return;
    }

    if (![region isKindOfClass:[CLBeaconRegion class]]) {
        NSAssert(NO, @"Only beacon region is supported.");
        return;
    }

    if (!self.mockBeaconRegions) {
        // let the time out kick in
        return;
    }

    if ([self.mockBeaconRegions objectForKey:region.identifier]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate locationManager:self didEnterRegion:region];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate locationManager:self didExitRegion:region];
        });
    }
}

- (void)stopMonitoringForRegion:(CLRegion *)region {
    // No op
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
        CLVisit *visit = [[CLVisitMock alloc] initWithCoordinate:self.mockLocation.coordinate
                                              horizontalAccuracy:100
                                                     arrivalDate:[now dateByAddingTimeInterval:-1000]
                                                   departureDate:now];
        [self.delegate locationManager:self didVisit:visit];
    }
}

- (void)setPausesLocationUpdatesAutomatically:(BOOL)pausesLocationUpdatesAutomatically {
}

@end
