//
//  CLVisitMock.h
//  RadarSDKTests
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLVisitMock : CLVisit

- (instancetype _Nullable)initWithCoordinate:(CLLocationCoordinate2D)coordinate
                          horizontalAccuracy:(CLLocationAccuracy)horizontalAccuracy
                                 arrivalDate:(NSDate *)arrivalDate
                               departureDate:(NSDate *)departureDate;

@end

NS_ASSUME_NONNULL_END
