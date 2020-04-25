/**
 * This file is generated using the remodel generation script.
 * The name of the input file is RadarLocation.value
 */

#import "RadarJSONCoding.h"
#import "RadarLocationType.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RadarLocation : NSObject<RadarJSONCoding, NSCopying, NSCoding>

@property (nonatomic, readonly) double latitude;
@property (nonatomic, readonly) double longtitude;
@property (nonatomic, readonly) RadarLocationType type;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithLatitude:(double)latitude longtitude:(double)longtitude type:(RadarLocationType)type NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
