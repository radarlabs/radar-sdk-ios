//
//  RadarHost.h
//  RadarSDK
//
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Radar.h"

NS_ASSUME_NONNULL_BEGIN

/**
 The Radar API hosts.
 */
typedef NS_ENUM(NSInteger, RadarHost) {
    /// Uses https://api.na.radar.com
    RadarHostNorthAmerica NS_SWIFT_NAME(northAmerica),
    /// Uses https://api.eu.radar.com
    RadarHostEurope NS_SWIFT_NAME(europe),
    /// Uses https://api.radar.io, the default
    RadarHostDefault NS_SWIFT_NAME(defaultHost)
};

NS_ASSUME_NONNULL_END
