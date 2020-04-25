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
static __unsafe_unretained NSString *const kNumberMetadataKey = @"NUMBER_METADATA";
static __unsafe_unretained NSString *const kMetadataArrayKey = @"METADATA_ARRAY";
static __unsafe_unretained NSString *const kLocationKey = @"LOCATION";
static __unsafe_unretained NSString *const kLocationArrayKey = @"LOCATION_ARRAY";
static __unsafe_unretained NSString *const kVersionKey = @"VERSION";

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
        _numberMetadata = (id)[aDecoder decodeObjectForKey:kNumberMetadataKey];
        _metadataArray = (id)[aDecoder decodeObjectForKey:kMetadataArrayKey];
        _location = (id)[aDecoder decodeObjectForKey:kLocationKey];
        _locationArray = (id)[aDecoder decodeObjectForKey:kLocationArrayKey];
        _version = (id)[aDecoder decodeObjectForKey:kVersionKey];
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
        if (dictionary[@"_description"] && [dictionary[@"_description"] isKindOfClass:[NSString class]]) {
            __description = (NSString *)dictionary[@"_description"];
        }
        if (dictionary[@"numberMetadata"] && [dictionary[@"numberMetadata"] isKindOfClass:[NSDictionary class]]) {
            _numberMetadata = (NSDictionary *)dictionary[@"numberMetadata"];
        }
        if (!_numberMetadata) {
            self = nil;
            return self;
        }
        if (dictionary[@"metadataArray"] && [dictionary[@"metadataArray"] isKindOfClass:[NSArray class]]) {
            _metadataArray = (NSArray *)dictionary[@"metadataArray"];
        }
        if (!_metadataArray) {
            self = nil;
            return self;
        }
        if (dictionary[@"location"] && [dictionary[@"location"] isKindOfClass:[NSDictionary class]]) {
            _location = [[RadarLocation alloc] initWithObject:dictionary[@"location"]];
        }
        if (!_location) {
            self = nil;
            return self;
        }
        if (dictionary[@"locationArray"] && [dictionary[@"locationArray"] isKindOfClass:[NSArray class]]) {
            _locationArray = [RadarLocation fromObjectArray:dictionary[@"locationArray"]];
        }
        if (!_locationArray) {
            self = nil;
            return self;
        }
        if (dictionary[@"version"] && [dictionary[@"version"] isKindOfClass:[NSNumber class]]) {
            _version = (NSNumber *)dictionary[@"version"];
        }
        if (!_version) {
            self = nil;
            return self;
        }
    }
    return self;
}

- (instancetype)initWith_id:(NSString *)_id
               _description:(nullable NSString *)_description
             numberMetadata:(NSDictionary<NSString *, NSNumber *> *)numberMetadata
              metadataArray:(NSArray<NSString *> *)metadataArray
                   location:(RadarLocation *)location
              locationArray:(NSArray<RadarLocation *> *)locationArray
                    version:(NSNumber *)version {
    RMParameterAssert(_id != nil);
    RMParameterAssert(numberMetadata != nil);
    RMParameterAssert(metadataArray != nil);
    RMParameterAssert(location != nil);
    RMParameterAssert(locationArray != nil);
    RMParameterAssert(version != nil);
    if ((self = [super init])) {
        __id = [_id copy];
        __description = [_description copy];
        _numberMetadata = [numberMetadata copy];
        _metadataArray = [metadataArray copy];
        _location = [location copy];
        _locationArray = [locationArray copy];
        _version = [version copy];
    }

    return self;
}

- (id)copyWithZone:(nullable NSZone *)zone {
    return self;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    dictionary[@"_id"] = __id;
    if (__description) {
        dictionary[@"_description"] = __description;
    }
    dictionary[@"numberMetadata"] = _numberMetadata;
    dictionary[@"metadataArray"] = _metadataArray;
    dictionary[@"location"] = [_location dictionaryValue];
    dictionary[@"locationArray"] = [_locationArray radar_mapObjectsUsingBlock:^id _Nullable(RadarLocation *_Nonnull obj) {
        return [obj dictionaryValue];
    }];
    dictionary[@"version"] = _version;
    return [dictionary copy];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:__id forKey:k_idKey];
    [aCoder encodeObject:__description forKey:k_descriptionKey];
    [aCoder encodeObject:_numberMetadata forKey:kNumberMetadataKey];
    [aCoder encodeObject:_metadataArray forKey:kMetadataArrayKey];
    [aCoder encodeObject:_location forKey:kLocationKey];
    [aCoder encodeObject:_locationArray forKey:kLocationArrayKey];
    [aCoder encodeObject:_version forKey:kVersionKey];
}

- (NSUInteger)hash {
    NSUInteger subhashes[] = {[__id hash], [__description hash], [_numberMetadata hash], [_metadataArray hash], [_location hash], [_locationArray hash], [_version hash]};
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
           (_numberMetadata == object->_numberMetadata ? YES : [_numberMetadata isEqual:object->_numberMetadata]) &&
           (_metadataArray == object->_metadataArray ? YES : [_metadataArray isEqual:object->_metadataArray]) &&
           (_location == object->_location ? YES : [_location isEqual:object->_location]) &&
           (_locationArray == object->_locationArray ? YES : [_locationArray isEqual:object->_locationArray]) &&
           (_version == object->_version ? YES : [_version isEqual:object->_version]);
}

@end

NS_ASSUME_NONNULL_END
#pragma clang diagnostic pop
