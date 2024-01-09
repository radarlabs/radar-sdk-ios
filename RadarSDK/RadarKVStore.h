//
//  RadarKVStore.h
//  RadarSDK
//
//  Created by Kenny Hu on 12/14/23.
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RadarLog.h"
#import "RadarFileStorage.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarKVStore : NSObject

@property (strong, nonatomic) NSString *settingsFileDir;
@property (strong, nonatomic) RadarFileStorage *fileHandler;
@property (nonatomic, assign) BOOL migrationCompleteFlag;

+ (instancetype)sharedInstance;

- (void)setMigrationCompleteFlag:(BOOL)migrationCompleteFlag;

- (BOOL)boolForKey:(NSString *)key;

- (void)setBool:(BOOL)value forKey:(NSString *)key;

- (nullable NSString *)stringForKey:(NSString *)key;

- (void)setString:(nullable NSString *)value forKey:(NSString *)key;

- (nullable NSDictionary *)dictionaryForKey:(NSString *)key;

- (void)setDictionary:(nullable NSDictionary *)value forKey:(NSString *)key;

- (double)doubleForKey:(NSString *)key;

- (void)setDouble:(double)value forKey:(NSString *)key;

- (void)setInteger:(NSInteger)value forKey:(NSString *)key;

- (NSInteger)integerForKey:(NSString *)key;

- (void)setObject:(nullable NSObject *)value forKey:(NSString *)key;

- (void)removeObjectForKey:(NSString *)key;

- (nullable NSObject *)objectForKey:(NSString *)key;

- (void)removeAllObjects;

- (BOOL)keyExists:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
