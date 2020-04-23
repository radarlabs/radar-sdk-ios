/**
 * This file is generated using the remodel generation script.
 * The name of the input file is RadarBeacon.value
 */

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "RadarBeacon.h"
#import "RadarCollectionAdditions.h"

#pragma clang diagnostic push
#pragma GCC diagnostic ignored "-Wobjc-designated-initializers"

static __unsafe_unretained NSString *const k_idKey = @"_ID";
static __unsafe_unretained NSString *const k_descriptionKey = @"_DESCRIPTION";
static __unsafe_unretained NSString *const kMetadataKey = @"METADATA";
static __unsafe_unretained NSString *const kLocationKey = @"LOCATION";
static __unsafe_unretained NSString *const kUuidKey = @"UUID";
static __unsafe_unretained NSString *const kMajorKey = @"MAJOR";
static __unsafe_unretained NSString *const kMinorKey = @"MINOR";

#define RMParameterAssert(condition) NSCParameterAssert((condition))

NS_ASSUME_NONNULL_BEGIN

@implementation RadarBeacon

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super init])) {
        __id = (id)[aDecoder decodeObjectForKey:k_idKey];
        __description = (id)[aDecoder decodeObjectForKey:k_descriptionKey];
        _metadata = (id)[aDecoder decodeObjectForKey:kMetadataKey];
        _location = (id)[aDecoder decodeObjectForKey:kLocationKey];
        _uuid = (id)[aDecoder decodeObjectForKey:kUuidKey];
        _major = (id)[aDecoder decodeObjectForKey:kMajorKey];
        _minor = (id)[aDecoder decodeObjectForKey:kMinorKey];
    }
    return self;
}

- (nullable instancetype)initWithRadarJSONObject:(nullable id)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSDictionary *dictionary = (NSDictionary *)object;
    if ((self = [super init])) {
        if (!dictionary[@"_id"]) {
            return nil;
        }
        __id = (NSString *)dictionary[@"_id"];
        if (!dictionary[@"_description"]) {
            return nil;
        }
        __description = (NSString *)dictionary[@"_description"];
        _metadata = (NSDictionary *)dictionary[@"metadata"];
        if (!dictionary[@"location"]) {
            return nil;
        }
        _location = [dictionary radar_coordinateForKey:@"location"];
        if (!dictionary[@"uuid"]) {
            return nil;
        }
        _uuid = (NSString *)dictionary[@"uuid"];
        if (!dictionary[@"major"]) {
            return nil;
        }
        _major = (NSNumber *)dictionary[@"major"];
        if (!dictionary[@"minor"]) {
            return nil;
        }
        _minor = (NSNumber *)dictionary[@"minor"];
    }
    return self;
}

- (instancetype)initWith_id:(NSString *)_id
               _description:(NSString *)_description
                   metadata:(nullable NSDictionary *)metadata
                   location:(RadarCoordinate *)location
                       uuid:(NSString *)uuid
                      major:(NSNumber *)major
                      minor:(NSNumber *)minor {
    RMParameterAssert(_id != nil);
    RMParameterAssert(_description != nil);
    RMParameterAssert(location != nil);
    RMParameterAssert(uuid != nil);
    RMParameterAssert(major != nil);
    RMParameterAssert(minor != nil);
    if ((self = [super init])) {
        __id = [_id copy];
        __description = [_description copy];
        _metadata = [metadata copy];
        _location = [location copy];
        _uuid = [uuid copy];
        _major = [major copy];
        _minor = [minor copy];
    }

    return self;
}

- (id)copyWithZone:(nullable NSZone *)zone {
    return self;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"_id"] = __id;
    dict[@"_description"] = __description;
    if (_metadata) {
        dict[@"metadata"] = _metadata;
    }
    dict[@"location"] = [_location dictionaryValue];
    dict[@"uuid"] = _uuid;
    dict[@"major"] = _major;
    dict[@"minor"] = _minor;
    return [dict copy];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:__id forKey:k_idKey];
    [aCoder encodeObject:__description forKey:k_descriptionKey];
    [aCoder encodeObject:_metadata forKey:kMetadataKey];
    [aCoder encodeObject:_location forKey:kLocationKey];
    [aCoder encodeObject:_uuid forKey:kUuidKey];
    [aCoder encodeObject:_major forKey:kMajorKey];
    [aCoder encodeObject:_minor forKey:kMinorKey];
}

- (NSUInteger)hash {
    NSUInteger subhashes[] = {[__id hash], [__description hash], [_metadata hash], [_location hash], [_uuid hash], [_major hash], [_minor hash]};
    NSUInteger result = subhashes[0];
    for (int ii = 1; ii < 7; ++ii) {
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

- (BOOL)isEqual:(RadarBeacon *)object {
    if (self == object) {
        return YES;
    } else if (object == nil || ![object isKindOfClass:[self class]]) {
        return NO;
    }
    return (__id == object->__id ? YES : [__id isEqual:object->__id]) && (__description == object->__description ? YES : [__description isEqual:object->__description]) &&
           (_metadata == object->_metadata ? YES : [_metadata isEqual:object->_metadata]) && (_location == object->_location ? YES : [_location isEqual:object->_location]) &&
           (_uuid == object->_uuid ? YES : [_uuid isEqual:object->_uuid]) && (_major == object->_major ? YES : [_major isEqual:object->_major]) &&
           (_minor == object->_minor ? YES : [_minor isEqual:object->_minor]);
}

@end

NS_ASSUME_NONNULL_END
#pragma clang diagnostic pop
