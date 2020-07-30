#import <Foundation/Foundation.h>

// a default implementation of deserializing from an array of JSON objects
#define FROM_JSON_ARRAY_DEFAULT_IMP(jsonArray, className)                                                                                                                          \
    {                                                                                                                                                                              \
        if (!jsonArray || ![jsonArray isKindOfClass:[NSArray class]]) {                                                                                                            \
            return nil;                                                                                                                                                            \
        }                                                                                                                                                                          \
                                                                                                                                                                                   \
        NSMutableArray<className *> *__mutableArray = [NSMutableArray array];                                                                                                      \
        for (id __jsonObject in (NSArray *)jsonArray) {                                                                                                                            \
            className *__radarObject = [[className alloc] initWithObject:__jsonObject];                                                                                            \
            if (!__radarObject) {                                                                                                                                                  \
                return nil;                                                                                                                                                        \
            }                                                                                                                                                                      \
            [__mutableArray addObject:__radarObject];                                                                                                                              \
        }                                                                                                                                                                          \
        return [__mutableArray copy];                                                                                                                                              \
    }

// a default implementation of serializing to an array of JSON objects
#define TO_JSON_ARRAY_DEFAULT_IMP(radarObjectArray, className)                                                                                                                     \
    {                                                                                                                                                                              \
        if (!radarObjectArray) {                                                                                                                                                   \
            return nil;                                                                                                                                                            \
        }                                                                                                                                                                          \
                                                                                                                                                                                   \
        NSMutableArray<NSDictionary *> *__mutableArray = [NSMutableArray array];                                                                                                   \
        for (className * __radarObject in (NSArray *)radarObjectArray) {                                                                                                           \
            NSDictionary *__dict = [__radarObject dictionaryValue];                                                                                                                \
            [__mutableArray addObject:__dict];                                                                                                                                     \
        }                                                                                                                                                                          \
        return [__mutableArray copy];                                                                                                                                              \
    }

NS_ASSUME_NONNULL_BEGIN

/// A JSON serialization / deserialization protocol for Radar models
@protocol RadarJSONCoding

/// Deserialize from JSON object; return nil if the JSON object is not valid.
/// @param object JSON representation for the object
- (nullable instancetype)initWithObject:(nullable id)object;

/// Serialize to JSON object.
- (NSDictionary *)dictionaryValue;

@end

NS_ASSUME_NONNULL_END
