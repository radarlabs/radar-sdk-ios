/**
 * This file is generated using the remodel generation script.
 * The name of the input file is RadarLocation.value
 */

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "RadarLocation.h"
#import "RadarCollectionAdditions.h"

#pragma clang diagnostic push
#pragma GCC diagnostic ignored "-Wobjc-designated-initializers"

static __unsafe_unretained NSString *const kLatitudeKey = @"LATITUDE";
static __unsafe_unretained NSString *const kLongtitudeKey = @"LONGTITUDE";
static __unsafe_unretained NSString *const kTypeKey = @"TYPE";

NS_ASSUME_NONNULL_BEGIN

@implementation RadarLocation

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

+ (nullable NSArray<RadarLocation *> *)fromObjectArray:(nullable id)objectArray {
    if (!objectArray || ![objectArray isKindOfClass:[NSArray class]]) {
        return nil;
    }

    NSMutableArray<RadarLocation *> *array = [NSMutableArray array];
    for (id object in (NSArray *)objectArray) {
        RadarLocation *value = [[RadarLocation alloc] initWithObject:object];
        if (!value) {
            return nil;
        }
        [array addObject:value];
    }

    return [array copy];
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super init])) {
        _latitude = [aDecoder decodeDoubleForKey:kLatitudeKey];
        _longtitude = [aDecoder decodeDoubleForKey:kLongtitudeKey];
        _type = (RadarLocationType)[aDecoder decodeIntegerForKey:kTypeKey];
    }
    return self;
}

- (instancetype)initWithLatitude:(double)latitude longtitude:(double)longtitude type:(RadarLocationType)type {
    if ((self = [super init])) {
        _latitude = latitude;
        _longtitude = longtitude;
        _type = type;
    }

    return self;
}

- (nullable instancetype)initWithObject:(nullable id)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSDictionary *dictionary = (NSDictionary *)object;
    if ((self = [super init])) {
        if (dictionary[@"latitude"] && [dictionary[@"latitude"] isKindOfClass:[NSNumber class]]) {
            _latitude = [dictionary[@"latitude"] doubleValue];
        }
        if (dictionary[@"longtitude"] && [dictionary[@"longtitude"] isKindOfClass:[NSNumber class]]) {
            _longtitude = [dictionary[@"longtitude"] doubleValue];
        }
        if (dictionary[@"type"] && [dictionary[@"type"] isKindOfClass:[NSNumber class]]) {
            _type = [dictionary[@"type"] integerValue];
        }
    }
    return self;
}

- (id)copyWithZone:(nullable NSZone *)zone {
    return self;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    dictionary[@"latitude"] = @(_latitude);
    dictionary[@"longtitude"] = @(_longtitude);
    dictionary[@"type"] = @(_type);
    return [dictionary copy];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeDouble:_latitude forKey:kLatitudeKey];
    [aCoder encodeDouble:_longtitude forKey:kLongtitudeKey];
    [aCoder encodeInteger:_type forKey:kTypeKey];
}

- (NSUInteger)hash {
    NSUInteger subhashes[] = {HashDouble(_latitude), HashDouble(_longtitude), ABS(_type)};
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

- (BOOL)isEqual:(RadarLocation *)object {
    if (self == object) {
        return YES;
    } else if (object == nil || ![object isKindOfClass:[self class]]) {
        return NO;
    }
    return _type == object->_type && CompareDoubles(_latitude, object->_latitude) && CompareDoubles(_longtitude, object->_longtitude);
}

@end

NS_ASSUME_NONNULL_END
#pragma clang diagnostic pop
