//
//  RadarCollectionAdditions.h
//  RadarSDK
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
@class RadarCoordinate;

NS_ASSUME_NONNULL_BEGIN
@interface NSArray<ObjectType>(Radar)

- (NSArray *)radar_mapObjectsUsingBlock:(id _Nullable (^)(ObjectType obj))block;
- (NSDictionary *)radar_mapToDictionaryUsingKeyBlock:(id _Nullable (^)(ObjectType obj))keyBlock valueBlock:(id _Nullable (^)(ObjectType obj))valueBlock;

@end

@interface NSDictionary<KeyType, ObjectType>(Radar)

- (nullable NSString *)radar_stringForKey:(KeyType)key;
- (nullable NSDictionary *)radar_dictionaryForKey:(KeyType)key;
- (nullable NSArray *)radar_arrayForKey:(KeyType)key;

@end

NS_ASSUME_NONNULL_END
