import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Represents a timezone.

 @see https://radar.com/documentation/api#geocoding
 */
@interface RadarTimezone : NSObject

/**
 The ID of the timezone.
 */
@property (nonnull, copy, nonatomic, readonly) NSString *id;

/**
 The name of of the timezone.
 */
@property (nonnull, copy, nonatomic, readonly) NSString *name;

/**
 The timezone abbreviation.
 */
@property (nonnull, copy, nonatomic, readonly) NSString *code;

/**
 The current time for the timezone.
 */
@property (nonnull, copy, nonatomic, readonly) NSDate *currentTime;

/**
 The UTC offset for the timezone.
 */
@property (nonnull, copy, nonatomic, readonly) NSNumber *utcOffset;

/**
 The DST offset for the timezone.
 */
@property (nonnull, copy, nonatomic, readonly) NSNumber *dstOffset;

@end

NS_ASSUME_NONNULL_END
