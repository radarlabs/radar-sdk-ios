
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol RadarJSONCoding

/// Deserialize from an array of JSON objects. Return nil if any of the JSON object is not valid
/// @param objectArray An array of the JSON objects
+ (nullable NSArray *)fromObjectArray:(nullable id)objectArray;

/// Deserialize from JSON object; return nil if the JSON object is not valid.
/// @param object JSON representation for the object
- (nullable instancetype)initWithObject:(nullable id)object;

/// Serialize to JSON object.
- (NSDictionary *)dictionaryValue;

@end

NS_ASSUME_NONNULL_END
