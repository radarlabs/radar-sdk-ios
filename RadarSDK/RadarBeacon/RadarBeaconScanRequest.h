
#import "Radar.h"
#import "RadarBeacon.h"
#import "RadarBeaconManager.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RadarBeaconScanRequest : NSObject<NSCopying>

@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSTimeInterval expiration;
@property (nonatomic, readonly) BOOL shouldTrack;
@property (nonatomic, readonly) NSArray<RadarBeacon *> *beacons;
@property (nonatomic, readonly, nullable) RadarBeaconDetectionCompletionHandler detectionCompletionHandler;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithIdentifier:(NSString *)identifier
                        expiration:(NSTimeInterval)expiration
                       shouldTrack:(BOOL)shouldTrack
                           beacons:(NSArray<RadarBeacon *> *)beacons
                 completionHandler:(nullable RadarBeaconDetectionCompletionHandler)detectionCompletionHandler NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
