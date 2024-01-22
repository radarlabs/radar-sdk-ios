//
//  RadarKVStore.h
//  RadarSDK
//
//  Created by Kenny Hu on 12/14/23.
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "RadarLog.h"
#import "RadarFileStorage.h"
#import "RadarTrackingOptions.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarKVStore : NSObject

@property (strong, nonatomic) NSString *settingsFileDir;
@property (strong, nonatomic) RadarFileStorage *fileHandler;
@property (nonatomic, assign) BOOL radarKVStoreMigrationComplete;

+ (instancetype)sharedInstance;

- (void)setRadarKVStoreMigrationComplete:(BOOL)migrationCompleteFlag;

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

- (NSString *)doubleWriteStringGetter:(NSString *)key;

- (void)doubleWriteStringSetter:(NSString *)key value:(NSString *)value;

- (double)doubleWriteDoubleGetter:(NSString *)key;

- (void)doubleWriteDoubleSetter:(NSString *)key value:(double)value;

- (BOOL)doubleWriteBOOLGetter:(NSString *)key;

- (void)doubleWriteBOOLSetter:(NSString *)key value:(BOOL)value;

- (NSDate *)doubleWriteDateGetter:(NSString *)key;

- (void)doubleWriteDateSetter:(NSString *)key value:(NSDate *)value;

- (NSArray<NSString *> *_Nullable)doubleWriteStringArrayGetter:(NSString *)key;

- (void)doubleWriteStringArraySetter:(NSString *)key value:(NSArray<NSString *> *)value;

- (NSInteger)doubleWriteIntegerGetter:(NSString *)key;

- (void)doubleWriteIntegerSetter:(NSString *)key value:(NSInteger)value;

- (BOOL)doubleWriteKeyExists:(NSString *)key;

- (CLLocation *)doubleWriteCLLocationGetter:(NSString *)key;

- (void)doubleWriteCLLocationSetter:(NSString *)key value:(CLLocation *)value;

- (RadarTrackingOptions *)doubleWriteRadarTrackingOptionGetter:(NSString *)key;

- (void)doubleWriteRadarTrackingOptionSetter:(NSString *)key value:(RadarTrackingOptions *)value;

@end

NS_ASSUME_NONNULL_END
