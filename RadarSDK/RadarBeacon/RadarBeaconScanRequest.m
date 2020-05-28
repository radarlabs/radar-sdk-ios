
#import "RadarBeaconScanRequest.h"
#import "RadarUtils.h"

NS_ASSUME_NONNULL_BEGIN

@implementation RadarBeaconScanRequest

- (instancetype)initWithIdentifier:(NSString *)identifier expiration:(NSTimeInterval)expiration beacons:(NSArray<RadarBeacon *> *)beacons {
    if ((self = [super init])) {
        _identifier = [identifier copy];
        _expiration = expiration;
        _beacons = [beacons copy];
    }

    return self;
}

- (id)copyWithZone:(nullable NSZone *)zone {
    return self;
}

- (BOOL)isEqual:(RadarBeaconScanRequest *)object {
    if (self == object) {
        return YES;
    } else if (object == nil || ![object isKindOfClass:[self class]]) {
        return NO;
    }
    return CompareDoubles(_expiration, object->_expiration) && (_identifier == object->_identifier ? YES : [_identifier isEqual:object->_identifier]) &&
           (_beacons == object->_beacons ? YES : [_beacons isEqual:object->_beacons]);
}

@end

NS_ASSUME_NONNULL_END
