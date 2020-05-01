//
//  CLLocationManagerMock.h
//  RadarSDKTests
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLLocationManagerMock : CLLocationManager

@property (nullable, strong, nonatomic) CLLocation *mockLocation;

@property (nullable, strong, nonatomic) NSDictionary<NSString *, CLBeaconRegion *> *mockBeaconRegions;

- (void)mockRegionEnter;
- (void)mockRegionExit;
- (void)mockVisitArrival;
- (void)mockVisitDeparture;

@end

NS_ASSUME_NONNULL_END
