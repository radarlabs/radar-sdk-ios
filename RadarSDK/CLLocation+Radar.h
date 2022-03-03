//
//  CLLocation+Radar.h
//  RadarSDK
//
//  Copyright © 2022 Radar Labs, Inc. All rights reserved.
//

#ifndef CLLocation_Radar_h
#define CLLocation_Radar_h

@import CoreLocation;

@interface CLLocation (Radar)

/**
 YES if 1) the location's latitude is between -180.0 and 180.0 (except 0.0)),
 longitude is between -90.0 and 90.0 (except 0.0), and horizontalAccuracy is
 greater than `0`.
 */
@property (nonatomic, readonly) BOOL isValid;

@end

#endif /* CLLocation_Radar_h */
