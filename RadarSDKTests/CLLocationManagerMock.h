//
//  CLLocationManagerMock.h
//  RadarSDKTests
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLLocationManagerMock : CLLocationManager

@property (nullable, strong, nonatomic) CLLocation *mockLocation;

- (void)mockRegionEnter;
- (void)mockRegionExit;
- (void)mockVisitArrival;
- (void)mockVisitDeparture;

@end

NS_ASSUME_NONNULL_END
