/**
 * This file is generated using the remodel generation script.
 * The name of the input file is RadarTestRemodel.value
 */

#import "RadarCoordinate.h"
#import "RadarJSONCoding.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RadarTestRemodel : NSObject<RadarJSONCoding>

@property (nonatomic, readonly, copy) NSString *_id;
@property (nonatomic, readonly, copy, nullable) NSNumber *_version;
@property (nonatomic, readonly, copy, nullable) NSDictionary *metadata;
@property (nonatomic, readonly, copy) NSArray<RadarCoordinate *> *geometry;
@property (nonatomic, readonly, copy, nullable) NSDictionary<NSString *, NSNumber *> *beacons;
@property (nonatomic, readonly) BOOL isActive;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWith_id:(NSString *)_id
                   _version:(nullable NSNumber *)_version
                   metadata:(nullable NSDictionary *)metadata
                   geometry:(NSArray<RadarCoordinate *> *)geometry
                    beacons:(nullable NSDictionary<NSString *, NSNumber *> *)beacons
                   isActive:(BOOL)isActive NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
