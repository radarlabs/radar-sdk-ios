
#import "RadarBeaconScanRequest.h"
#import "RadarUtils.h"

NS_ASSUME_NONNULL_BEGIN

@implementation RadarBeaconScanRequest

- (instancetype)initWithIdentifier:(NSString *)identifier
                        expiration:(NSTimeInterval)expiration
                           beacons:(NSArray<RadarBeacon *> *)beacons
                 completionHandler:(nullable RadarBeaconScanCompletionHandler)completionHandler {
    if ((self = [super init])) {
        _identifier = [identifier copy];
        _expiration = expiration;
        _beacons = [beacons copy];
        _completionHandler = completionHandler;
    }

    return self;
}

- (id)copyWithZone:(nullable NSZone *)zone {
    return self;
}

@end

NS_ASSUME_NONNULL_END
