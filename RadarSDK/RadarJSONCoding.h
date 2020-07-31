#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// A JSON serialization / deserialization protocol for Radar model
@protocol RadarJSONCoding

/// Deserialize from JSON object; return nil if the JSON object is not valid.
/// @param object JSON representation for the object
- (nullable instancetype)initWithObject:(nullable id)object;

/// Serialize to JSON object.
- (NSDictionary *)dictionaryValue;

@end

NS_ASSUME_NONNULL_END

/* default implementations to serialize / deserialize an array of id<RadarJSONCoding> objects */

// Deserialize from an array of JSON objects. Return nil if any JSON object can't be deserialized,
#define FROM_JSON_ARRAY_DEFAULT_IMP(jsonArray, radarClassName)                                                                                                                     \
    {                                                                                                                                                                              \
        if (!jsonArray || ![jsonArray isKindOfClass:[NSArray class]]) {                                                                                                            \
            return nil;                                                                                                                                                            \
        }                                                                                                                                                                          \
                                                                                                                                                                                   \
        NSMutableArray<radarClassName *> *__mutableArray = [NSMutableArray array];                                                                                                 \
        for (id __jsonObject in (NSArray *)jsonArray) {                                                                                                                            \
            radarClassName *__radarObject = [[radarClassName alloc] initWithObject:__jsonObject];                                                                                  \
            if (!__radarObject) {                                                                                                                                                  \
                return nil;                                                                                                                                                        \
            }                                                                                                                                                                      \
            [__mutableArray addObject:__radarObject];                                                                                                                              \
        }                                                                                                                                                                          \
        return [__mutableArray copy];                                                                                                                                              \
    }

// Serialize to an array of JSON objects.
#define TO_JSON_ARRAY_DEFAULT_IMP(radarObjectArray, radarClassName)                                                                                                                \
    {                                                                                                                                                                              \
        if (!radarObjectArray) {                                                                                                                                                   \
            return nil;                                                                                                                                                            \
        }                                                                                                                                                                          \
                                                                                                                                                                                   \
        NSMutableArray<NSDictionary *> *__mutableArray = [NSMutableArray array];                                                                                                   \
        for (radarClassName * __radarObject in (NSArray *)radarObjectArray) {                                                                                                      \
            NSDictionary *__dict = [__radarObject dictionaryValue];                                                                                                                \
            [__mutableArray addObject:__dict];                                                                                                                                     \
        }                                                                                                                                                                          \
        return [__mutableArray copy];                                                                                                                                              \
    }
