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

@property (nonatomic, readonly) BOOL isValid;

@end

#endif /* CLLocation_Radar_h */
