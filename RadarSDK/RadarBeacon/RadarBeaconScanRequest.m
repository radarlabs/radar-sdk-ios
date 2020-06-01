
#import "RadarBeaconScanRequest.h"
#import "RadarBeaconScanRequest+Internal.h"

NS_ASSUME_NONNULL_BEGIN

@implementation RadarBeaconScanRequest

- (instancetype)initWithIdentifier:(NSString *)identifier
                        expiration:(NSTimeInterval)expiration
                       shouldTrack:(BOOL)shouldTrack
                           beacons:(NSArray<RadarBeacon *> *)beacons
                 completionHandler:(nullable RadarBeaconDetectionCompletionHandler)detectionCompletionHandler {
    if ((self = [super init])) {
        _identifier = [identifier copy];
        _expiration = expiration;
        _shouldTrack = shouldTrack;
        _beacons = [beacons copy];
        _detectionCompletionHandler = [detectionCompletionHandler copy];
    }

    return self;
}

- (id)copyWithZone:(nullable NSZone *)zone {
    return self;
}

- (void)setDetectionCompletionHandler:(nullable RadarBeaconDetectionCompletionHandler)detectionCompletionHandler {
    _detectionCompletionHandler = [detectionCompletionHandler copy];
}

@end

NS_ASSUME_NONNULL_END
