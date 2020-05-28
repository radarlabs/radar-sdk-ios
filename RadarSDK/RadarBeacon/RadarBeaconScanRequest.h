
#import "RadarBeacon.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RadarBeaconScanRequest : NSObject<NSCopying>

@property (nonatomic, readonly, copy) NSString *identifier;
@property (nonatomic, readonly) NSTimeInterval expiration;
@property (nonatomic, readonly, copy) NSArray<RadarBeacon *> *beacons;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithIdentifier:(NSString *)identifier expiration:(NSTimeInterval)expiration beacons:(NSArray<RadarBeacon *> *)beacons NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
