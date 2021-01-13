//
//  RadarBeacon.h
//  RadarSDK
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Represents a Bluetooth beacon. For more information about Beacons, see https://radar.io/documentation/beacons.

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

+ (NSArray<NSDictionary *> *_Nullable)arrayForBeacons:(NSArray<RadarBeacon *> *_Nullable)beacons;
- (NSDictionary *_Nonnull)dictionaryValue;

@end

NS_ASSUME_NONNULL_END
