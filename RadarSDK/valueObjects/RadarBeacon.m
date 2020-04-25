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
        if (!__description) {
            self = nil;
            return self;
        }
        if (dictionary[@"metadata"] && [dictionary[@"metadata"] isKindOfClass:[NSDictionary class]]) {
            _metadata = (NSDictionary *)dictionary[@"metadata"];
        }
        if (dictionary[@"geometry"] && [dictionary[@"geometry"] isKindOfClass:[NSArray class]]) {
            _geometry = [RadarCoordinate fromObjectArray:dictionary[@"geometry"]];
        }
        if (!_geometry) {
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
        if (dictionary[@"major"] && [dictionary[@"major"] isKindOfClass:[NSNumber class]]) {
            _major = (NSNumber *)dictionary[@"major"];
        }
        if (!_major) {
            self = nil;
            return self;
        }
        if (dictionary[@"minor"] && [dictionary[@"minor"] isKindOfClass:[NSNumber class]]) {
            _minor = (NSNumber *)dictionary[@"minor"];
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
                   geometry:(NSArray<RadarCoordinate *> *)geometry
                       uuid:(NSString *)uuid
                      major:(NSNumber *)major
                      minor:(NSNumber *)minor {
    RMParameterAssert(_id != nil);
    RMParameterAssert(_description != nil);
    RMParameterAssert(geometry != nil);
    RMParameterAssert(uuid != nil);
    RMParameterAssert(major != nil);
    RMParameterAssert(minor != nil);
    if ((self = [super init])) {
        __id = [_id copy];
        __description = [_description copy];
        _metadata = [metadata copy];
        _geometry = [geometry copy];
        _uuid = [uuid copy];
        _major = [major copy];
        _minor = [minor copy];
    }

    return self;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    dictionary[@"_id"] = __id;
    dictionary[@"_description"] = __description;
    if (_metadata) {
        dictionary[@"metadata"] = _metadata;
    }
    dictionary[@"geometry"] = [_geometry radar_mapObjectsUsingBlock:^id _Nullable(RadarCoordinate *_Nonnull obj) {
        return [obj dictionaryValue];
    }];
    dictionary[@"uuid"] = _uuid;
    dictionary[@"major"] = _major;
    dictionary[@"minor"] = _minor;
    return [dictionary copy];
}

@end

NS_ASSUME_NONNULL_END
#pragma clang diagnostic pop
