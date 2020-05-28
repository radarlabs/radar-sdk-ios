
#import "RadarBeaconScanRequest.h"
#import "RadarUtils.h"

NS_ASSUME_NONNULL_BEGIN

@implementation RadarBeaconScanRequest

- (instancetype)initWithIdentifier:(NSString *)identifier createdTimestamp:(NSTimeInterval)createdTimestamp beacons:(NSArray<RadarBeacon *> *)beacons {
    if ((self = [super init])) {
        _identifier = [identifier copy];
        _createdTimestamp = createdTimestamp;
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
    return CompareDoubles(_createdTimestamp, object->_createdTimestamp) && (_identifier == object->_identifier ? YES : [_identifier isEqual:object->_identifier]) &&
           (_beacons == object->_beacons ? YES : [_beacons isEqual:object->_beacons]);
}

@end

NS_ASSUME_NONNULL_END
