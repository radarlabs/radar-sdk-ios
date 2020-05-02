

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
static __unsafe_unretained NSString *const kGeometryKey = @"GEOMETRY";
static __unsafe_unretained NSString *const kTypeKey = @"TYPE";
static __unsafe_unretained NSString *const kUuidKey = @"UUID";
static __unsafe_unretained NSString *const kMajorKey = @"MAJOR";
static __unsafe_unretained NSString *const kMinorKey = @"MINOR";

#define RMParameterAssert(condition) NSCParameterAssert((condition))

NS_ASSUME_NONNULL_BEGIN

@implementation RadarBeacon

+ (nullable NSArray<RadarBeacon *> *)fromObjectArray:(nullable id)objectArray {
    if (!objectArray || ![objectArray isKindOfClass:[NSArray class]]) {
        return nil;
    }

    NSMutableArray<RadarBeacon *> *array = [NSMutableArray array];
    for (id object in (NSArray *)objectArray) {
        RadarBeacon *value = [[RadarBeacon alloc] initWithObject:object];
        if (!value) {
            return nil;
        }
        [array addObject:value];
    }

    return [array copy];
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super init])) {
        __id = (id)[aDecoder decodeObjectForKey:k_idKey];
        __description = (id)[aDecoder decodeObjectForKey:k_descriptionKey];
        _metadata = (id)[aDecoder decodeObjectForKey:kMetadataKey];
        _geometry = (id)[aDecoder decodeObjectForKey:kGeometryKey];
        _type = (id)[aDecoder decodeObjectForKey:kTypeKey];
        _uuid = (id)[aDecoder decodeObjectForKey:kUuidKey];
        _major = (id)[aDecoder decodeObjectForKey:kMajorKey];
        _minor = (id)[aDecoder decodeObjectForKey:kMinorKey];
    }
    return self;
}

- (nullable instancetype)initWithObject:(nullable id)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSDictionary *dictionary = (NSDictionary *)object;
    if ((self = [super init])) {
        if (dictionary[@"_id"] && [dictionary[@"_id"] isKindOfClass:[NSString class]]) {
            __id = (NSString *)dictionary[@"_id"];
        }
        if (!__id) {
            self = nil;
            return self;
        }
        if (dictionary[@"description"] && [dictionary[@"description"] isKindOfClass:[NSString class]]) {
            __description = (NSString *)dictionary[@"description"];
        }
        if (!__description) {
            self = nil;
            return self;
        }
        if (dictionary[@"metadata"] && [dictionary[@"metadata"] isKindOfClass:[NSDictionary class]]) {
            _metadata = (NSDictionary *)dictionary[@"metadata"];
        }
        if (dictionary[@"geometry"] && [dictionary[@"geometry"] isKindOfClass:[NSDictionary class]]) {
            _geometry = [[RadarCoordinate alloc] initWithObject:dictionary[@"geometry"]];
        }
        if (!_geometry) {
            self = nil;
            return self;
        }
        if (dictionary[@"type"] && [dictionary[@"type"] isKindOfClass:[NSString class]]) {
            _type = (NSString *)dictionary[@"type"];
        }
        if (!_type) {
            self = nil;
            return self;
        }
        if (dictionary[@"uuid"] && [dictionary[@"uuid"] isKindOfClass:[NSString class]]) {
            _uuid = (NSString *)dictionary[@"uuid"];
        }
        if (!_uuid) {
            self = nil;
            return self;
        }
        if (dictionary[@"major"] && [dictionary[@"major"] isKindOfClass:[NSString class]]) {
            _major = (NSString *)dictionary[@"major"];
        }
        if (!_major) {
            self = nil;
            return self;
        }
        if (dictionary[@"minor"] && [dictionary[@"minor"] isKindOfClass:[NSString class]]) {
            _minor = (NSString *)dictionary[@"minor"];
        }
        if (!_minor) {
            self = nil;
            return self;
        }
    }
    return self;
}

- (instancetype)initWith_id:(NSString *)_id
               _description:(NSString *)_description
                   metadata:(nullable NSDictionary *)metadata
                   geometry:(RadarCoordinate *)geometry
                       type:(NSString *)type
                       uuid:(NSString *)uuid
                      major:(NSString *)major
                      minor:(NSString *)minor {
    RMParameterAssert(_id != nil);
    RMParameterAssert(_description != nil);
    RMParameterAssert(geometry != nil);
    RMParameterAssert(type != nil);
    RMParameterAssert(uuid != nil);
    RMParameterAssert(major != nil);
    RMParameterAssert(minor != nil);
    if ((self = [super init])) {
        __id = [_id copy];
        __description = [_description copy];
        _metadata = [metadata copy];
        _geometry = [geometry copy];
        _type = [type copy];
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
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    dictionary[@"_id"] = __id;
    dictionary[@"description"] = __description;
    if (_metadata) {
        dictionary[@"metadata"] = _metadata;
    }
    dictionary[@"geometry"] = [_geometry dictionaryValue];
    dictionary[@"type"] = _type;
    dictionary[@"uuid"] = _uuid;
    dictionary[@"major"] = _major;
    dictionary[@"minor"] = _minor;
    return [dictionary copy];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:__id forKey:k_idKey];
    [aCoder encodeObject:__description forKey:k_descriptionKey];
    [aCoder encodeObject:_metadata forKey:kMetadataKey];
    [aCoder encodeObject:_geometry forKey:kGeometryKey];
    [aCoder encodeObject:_type forKey:kTypeKey];
    [aCoder encodeObject:_uuid forKey:kUuidKey];
    [aCoder encodeObject:_major forKey:kMajorKey];
    [aCoder encodeObject:_minor forKey:kMinorKey];
}

- (NSUInteger)hash {
    NSUInteger subhashes[] = {[__id hash], [__description hash], [_metadata hash], [_geometry hash], [_type hash], [_uuid hash], [_major hash], [_minor hash]};
    NSUInteger result = subhashes[0];
    for (int ii = 1; ii < 8; ++ii) {
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
           (_metadata == object->_metadata ? YES : [_metadata isEqual:object->_metadata]) && (_geometry == object->_geometry ? YES : [_geometry isEqual:object->_geometry]) &&
           (_type == object->_type ? YES : [_type isEqual:object->_type]) && (_uuid == object->_uuid ? YES : [_uuid isEqual:object->_uuid]) &&
           (_major == object->_major ? YES : [_major isEqual:object->_major]) && (_minor == object->_minor ? YES : [_minor isEqual:object->_minor]);
}

@end

NS_ASSUME_NONNULL_END
#pragma clang diagnostic pop
