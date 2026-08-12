//
//  CLLocationManagerMock.h
//  RadarSDKTests
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import "../RadarSDK/RadarLocationManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface CLLocationManagerMock : CLLocationManager

@property (nullable, strong, nonatomic) CLLocation *mockLocation;

- (void)mockRegionEnter;
- (void)mockRegionExit;
- (void)mockVisitArrival;
- (void)mockVisitDeparture;

@end

// expose callCompletionHandlersWithStatus, so we can simulate a timeout
@interface RadarLocationManager ()
- (void)callCompletionHandlersWithStatus:(RadarStatus)status location:(CLLocation *_Nullable)location;
@end
NS_ASSUME_NONNULL_END
