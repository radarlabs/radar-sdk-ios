//
//  RadarNearbyBeaconSearch+Internal.h
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Implemented in RadarNearbyBeaconSearch.swift. It's internal, so it isn't in RadarSDK-Swift.h.
@interface RadarNearbyBeaconSearch : NSObject

@property (class, readonly) int radius;
@property (class, readonly) int limit;

@end

NS_ASSUME_NONNULL_END
