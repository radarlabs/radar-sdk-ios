
#import "Radar.h"
#import "RadarBeacon.h"
#import "RadarBeaconManager.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RadarBeaconScanRequest : NSObject<NSCopying>

@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSTimeInterval expiration;
@property (nonatomic, readonly) NSArray<RadarBeacon *> *beacons;
@property (nonatomic, readonly, nullable) RadarBeaconTrackCompletionHandler completionHandler;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithIdentifier:(NSString *)identifier
                        expiration:(NSTimeInterval)expiration
                           beacons:(NSArray<RadarBeacon *> *)beacons
                 completionHandler:(nullable RadarBeaconTrackCompletionHandler)completionHandler NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
