
#import "RadarCoordinate.h"
#import "RadarJSONCoding.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RadarBeacon : NSObject<RadarJSONCoding, NSCopying>

@property (nonatomic, readonly, copy) NSString *_id;
@property (nonatomic, readonly, copy) NSString *_description;
@property (nonatomic, readonly, copy, nullable) NSDictionary *metadata;
@property (nonatomic, readonly, copy) RadarCoordinate *geometry;
@property (nonatomic, readonly, copy) NSString *type;
@property (nonatomic, readonly, copy) NSString *uuid;
@property (nonatomic, readonly, copy) NSString *major;
@property (nonatomic, readonly, copy) NSString *minor;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithId:(NSString *)_id
               description:(NSString *)_description
                  metadata:(nullable NSDictionary *)metadata
                  geometry:(RadarCoordinate *)geometry
                      type:(NSString *)type
                      uuid:(NSString *)uuid
                     major:(NSString *)major
                     minor:(NSString *)minor NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
