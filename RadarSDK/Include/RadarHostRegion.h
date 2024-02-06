//
//  RadarHostRegion.h
//  RadarSDK
//
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The Radar API hosts.
 */
typedef NS_ENUM(NSInteger, RadarHostRegion) {
    /// Uses https://api.na.radar.com
    RadarHostRegionNorthAmerica NS_SWIFT_NAME(northAmerica),
    /// Uses https://api.eu.radar.com
    RadarHostRegionEurope NS_SWIFT_NAME(europe),
    /// Uses https://api.radar.io
    RadarHostRegionGlobal NS_SWIFT_NAME(global)
};

NS_ASSUME_NONNULL_END
