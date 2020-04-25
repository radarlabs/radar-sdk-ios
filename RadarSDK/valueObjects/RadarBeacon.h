/**
 * This file is generated using the remodel generation script.
 * The name of the input file is RadarBeacon.value
 */

#import "RadarCoordinate.h"
#import "RadarJSONCoding.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RadarBeacon : NSObject<RadarJSONCoding>

@property (nonatomic, readonly, copy) NSString *_id;
@property (nonatomic, readonly, copy) NSString *_description;
@property (nonatomic, readonly, copy, nullable) NSDictionary *metadata;
@property (nonatomic, readonly, copy) NSArray<RadarCoordinate *> *geometry;
@property (nonatomic, readonly, copy) NSString *uuid;
@property (nonatomic, readonly, copy) NSNumber *major;
@property (nonatomic, readonly, copy) NSNumber *minor;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWith_id:(NSString *)_id
               _description:(NSString *)_description
                   metadata:(nullable NSDictionary *)metadata
                   geometry:(NSArray<RadarCoordinate *> *)geometry
                       uuid:(NSString *)uuid
                      major:(NSNumber *)major
                      minor:(NSNumber *)minor NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
