
#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "RadarBeaconScanRequest.h"

static __unsafe_unretained NSString *const kIdentifierKey = @"IDENTIFIER";
static __unsafe_unretained NSString *const kCreatedTimestampKey = @"CREATED_TIMESTAMP";
static __unsafe_unretained NSString *const kBeaconsKey = @"BEACONS";

#define RMParameterAssert(condition) NSCParameterAssert((condition))

NS_ASSUME_NONNULL_BEGIN

@implementation RadarBeaconScanRequest

static BOOL CompareDoubles(double givenDouble, double doubleToCompare) {
    return fabs(givenDouble - doubleToCompare) < DBL_EPSILON * fabs(givenDouble + doubleToCompare) || fabs(givenDouble - doubleToCompare) < DBL_MIN;
}

static NSUInteger HashDouble(double givenDouble) {
    union {
        double key;
        uint64_t bits;
    } u;
    u.key = givenDouble;
    NSUInteger p = u.bits;
    p = (~p) + (p << 18);
    p ^= (p >> 31);
    p *= 21;
    p ^= (p >> 11);
    p += (p << 6);
    p ^= (p >> 22);
    return (NSUInteger)p;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super init])) {
        _identifier = (id)[aDecoder decodeObjectForKey:kIdentifierKey];
        _createdTimestamp = [aDecoder decodeDoubleForKey:kCreatedTimestampKey];
        _beacons = (id)[aDecoder decodeObjectForKey:kBeaconsKey];
    }
    return self;
}

- (instancetype)initWithIdentifier:(NSString *)identifier createdTimestamp:(NSTimeInterval)createdTimestamp beacons:(NSArray<RadarBeacon *> *)beacons {
    RMParameterAssert(identifier != nil);
    RMParameterAssert(beacons != nil);
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

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ - \n\t identifier: %@; \n\t createdTimestamp: %lf; \n\t beacons: %@; \n", [super description], _identifier, _createdTimestamp, _beacons];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_identifier forKey:kIdentifierKey];
    [aCoder encodeDouble:_createdTimestamp forKey:kCreatedTimestampKey];
    [aCoder encodeObject:_beacons forKey:kBeaconsKey];
}

- (NSUInteger)hash {
    NSUInteger subhashes[] = {[_identifier hash], HashDouble(_createdTimestamp), [_beacons hash]};
    NSUInteger result = subhashes[0];
    for (int ii = 1; ii < 3; ++ii) {
        unsigned long long base = (((unsigned long long)result) << 32 | subhashes[ii]);
        base = (~base) + (base << 18);
        base ^= (base >> 31);
        base *= 21;
        base ^= (base >> 11);
        base += (base << 6);
        base ^= (base >> 22);
        result = base;
    }
    return result;
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
