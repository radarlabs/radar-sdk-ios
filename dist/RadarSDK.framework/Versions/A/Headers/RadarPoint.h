//
//  RadarPoint.h
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

#import "RadarCoordinate.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Represents a point. For more information about Points, see https://radar.io/documentation/points.

 @see https://radar.io/documentation/points
*/
@interface RadarPoint : NSObject

/**
 The Radar ID of the point.
 */
@property (nonatomic, readonly) NSString *_id;

/**
 The description of the point. Not to be confused with the `NSObject` `description` property.
 */
@property (nonatomic, readonly) NSString *_description;

/**
 The tag of the point.
 */
@property (nullable, nonatomic, readonly) NSString *tag;

/**
 The external ID of the point.
*/
@property (nullable, nonatomic, readonly) NSString *externalId;

/**
 The optional set of custom key-value pairs for the point.
 */
@property (nullable, nonatomic, readonly) NSDictionary *metadata;

/**
 The location of the point.
 */
@property (nonatomic, readonly) RadarCoordinate *location;

+ (NSArray<NSDictionary *> *_Nullable)arrayForPoints:(NSArray<RadarPoint *> *_Nullable)points;
- (NSDictionary *_Nonnull)dictionaryValue;

@end

NS_ASSUME_NONNULL_END
