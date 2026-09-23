//
//  RadarRouteGeometry.h
//  RadarSDK
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RadarCoordinate;

NS_ASSUME_NONNULL_BEGIN

/**
 Represents the geometry of a route.
 */
@interface RadarRouteGeometry : NSObject

/**
 The geometry of the route.
 */
@property (nullable, copy, nonatomic, readonly) NSArray<RadarCoordinate *> *coordinates;

- (NSDictionary *_Nonnull)dictionaryValue;

@end

NS_ASSUME_NONNULL_END
