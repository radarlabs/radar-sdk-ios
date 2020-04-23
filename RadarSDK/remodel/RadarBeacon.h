/**
 * This file is generated using the remodel generation script.
 * The name of the input file is RadarBeacon.value
 */

#import "RadarCoordinate.h"
#import "RadarJSONCoding.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Represents a beacon.
 */
@interface RadarBeacon : NSObject<RadarJSONCoding, NSCopying, NSCoding>

/**
 * The Radar ID of the beacon.
 */
@property (nonatomic, readonly, copy) NSString *_id;
/**
 * The description of the beacon. Not to be confused with the `NSObject` `description` property.
 */
@property (nonatomic, readonly, copy) NSString *_description;
/**
 * The optional set of custom key-value pairs for the beacon.
 */
@property (nonatomic, readonly, copy, nullable) NSDictionary *metadata;
/**
 * The location of the beacon.
 */
@property (nonatomic, readonly, copy) RadarCoordinate *location;
/**
 * The UUID of the beacon.
 */
@property (nonatomic, readonly, copy) NSString *uuid;
/**
 * The major number of the beacon.
 */
@property (nonatomic, readonly, copy) NSNumber *major;
/**
 * The minor number of the beacon.
 */
@property (nonatomic, readonly, copy) NSNumber *minor;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

// Initialization Method from Networking.
- (nullable instancetype)initWithRadarJSONObject:(nullable id)object;

/**
 * @param _id The Radar ID of the beacon.
 * @param _description The description of the beacon. Not to be confused with the `NSObject` `description` property.
 * @param metadata The optional set of custom key-value pairs for the beacon.
 * @param location The location of the beacon.
 * @param uuid The UUID of the beacon.
 * @param major The major number of the beacon.
 * @param minor The minor number of the beacon.
 */
- (instancetype)initWith_id:(NSString *)_id
               _description:(NSString *)_description
                   metadata:(nullable NSDictionary *)metadata
                   location:(RadarCoordinate *)location
                       uuid:(NSString *)uuid
                      major:(NSNumber *)major
                      minor:(NSNumber *)minor NS_DESIGNATED_INITIALIZER;

- (NSDictionary *)dictionaryValue;

@end

NS_ASSUME_NONNULL_END
