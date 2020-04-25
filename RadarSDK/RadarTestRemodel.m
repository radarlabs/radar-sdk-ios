/**
 * This file is generated using the remodel generation script.
 * The name of the input file is RadarTestRemodel.value
 */

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "RadarTestRemodel.h"
#import "RadarCollectionAdditions.h"

#pragma clang diagnostic push
#pragma GCC diagnostic ignored "-Wobjc-designated-initializers"

#define RMParameterAssert(condition) NSCParameterAssert((condition))

NS_ASSUME_NONNULL_BEGIN

@implementation RadarTestRemodel

+ (nullable NSArray<RadarTestRemodel *> *)fromObjectArray:(nullable id)objectArray {
    if (!objectArray || ![objectArray isKindOfClass:[NSArray class]]) {
        return nil;
    }

    NSMutableArray<RadarTestRemodel *> *array = [NSMutableArray array];
    for (id object in (NSArray *)objectArray) {
        RadarTestRemodel *value = [[RadarTestRemodel alloc] initWithObject:object];
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
        if (dictionary[@"_version"] && [dictionary[@"_version"] isKindOfClass:[NSNumber class]]) {
            __version = (NSNumber *)dictionary[@"_version"];
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
        if (dictionary[@"beacons"] && [dictionary[@"beacons"] isKindOfClass:[NSDictionary class]]) {
            _beacons = (NSDictionary *)dictionary[@"beacons"];
        }
        if (dictionary[@"isActive"] && [dictionary[@"isActive"] isKindOfClass:[NSNumber class]]) {
            _isActive = [dictionary[@"isActive"] boolValue];
        }
    }
    return self;
}

- (instancetype)initWith_id:(NSString *)_id
                   _version:(nullable NSNumber *)_version
                   metadata:(nullable NSDictionary *)metadata
                   geometry:(NSArray<RadarCoordinate *> *)geometry
                    beacons:(nullable NSDictionary<NSString *, NSNumber *> *)beacons
                   isActive:(BOOL)isActive {
    RMParameterAssert(_id != nil);
    RMParameterAssert(geometry != nil);
    if ((self = [super init])) {
        __id = [_id copy];
        __version = [_version copy];
        _metadata = [metadata copy];
        _geometry = [geometry copy];
        _beacons = [beacons copy];
        _isActive = isActive;
    }

    return self;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    dictionary[@"_id"] = __id;
    if (__version) {
        dictionary[@"_version"] = __version;
    }
    if (_metadata) {
        dictionary[@"metadata"] = _metadata;
    }
    dictionary[@"geometry"] = [_geometry radar_mapObjectsUsingBlock:^id _Nullable(RadarCoordinate *_Nonnull obj) {
        return [obj dictionaryValue];
    }];
    if (_beacons) {
        dictionary[@"beacons"] = _beacons;
    }
    dictionary[@"isActive"] = @(_isActive);
    return [dictionary copy];
}

@end

NS_ASSUME_NONNULL_END
#pragma clang diagnostic pop
