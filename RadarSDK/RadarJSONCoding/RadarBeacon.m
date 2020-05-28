
#import "RadarBeacon.h"
#import "RadarCollectionAdditions.h"
#import "RadarCoordinate.h"

NS_ASSUME_NONNULL_BEGIN

@implementation RadarBeacon

#pragma mark - JSON Coding

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
    NSString *_id = [dictionary radar_stringForKey:@"_id"];
    NSString *description = [dictionary radar_stringForKey:@"description"];
    NSDictionary *metadata = [dictionary radar_dictionaryForKey:@"metadata"];
    RadarCoordinate *geometry = [[RadarCoordinate alloc] initWithObject:[dictionary radar_dictionaryForKey:@"geometry"]];
    NSString *type = [dictionary radar_stringForKey:@"type"];
    NSString *uuid = [dictionary radar_stringForKey:@"uuid"];
    NSString *major = [dictionary radar_stringForKey:@"major"];
    NSString *minor = [dictionary radar_stringForKey:@"minor"];
    if (_id && description && geometry && type && uuid && major && minor) {
        // check nonnull properties
        return [self initWithId:_id description:description metadata:metadata geometry:geometry type:type uuid:uuid major:major minor:minor];
    } else {
        return nil;
    }
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

- (instancetype)initWithId:(NSString *)_id
               description:(NSString *)_description
                  metadata:(nullable NSDictionary *)metadata
                  geometry:(RadarCoordinate *)geometry
                      type:(NSString *)type
                      uuid:(NSString *)uuid
                     major:(NSString *)major
                     minor:(NSString *)minor {
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

#pragma mark - copy and equal

- (id)copyWithZone:(nullable NSZone *)zone {
    return self;
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
