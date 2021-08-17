//
//  RadarBeacon.h
//  RadarSDK
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "RadarCoordinate.h"
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Represents a Bluetooth beacon.

 @see https://radar.io/documentation/beacons
 */
@interface RadarBeacon : NSObject

/**
 The Radar ID of the beacon.
 */
@property (nonnull, copy, nonatomic, readonly) NSString *_id;

/**
 The description of the beacon. Not to be confused with the `NSObject` `description` property.
 */
@property (nonnull, copy, nonatomic, readonly) NSString *_description;

/**
 The tag of the beacon.
 */
@property (nullable, copy, nonatomic, readonly) NSString *tag;

/**
 The external ID of the beacon.
 */
@property (nullable, copy, nonatomic, readonly) NSString *externalId;

/**
 The UUID of the beacon.
 */
@property (nonnull, copy, nonatomic, readonly) NSString *uuid;

/**
 The major ID of the beacon.
 */
@property (nonnull, copy, nonatomic, readonly) NSString *major;

/**
 The minor ID of the beacon.
 */
@property (nonnull, copy, nonatomic, readonly) NSString *minor;

/**
 The optional set of custom key-value pairs for the beacon.
 */
@property (nullable, copy, nonatomic, readonly) NSDictionary *metadata;

/**
 The location of the beacon.
 */
@property (nonnull, strong, nonatomic, readonly) RadarCoordinate *geometry;

+ (NSArray<NSDictionary *> *_Nullable)arrayForBeacons:(NSArray<RadarBeacon *> *_Nullable)beacons;
- (NSDictionary *_Nonnull)dictionaryValue;

@end

NS_ASSUME_NONNULL_END
